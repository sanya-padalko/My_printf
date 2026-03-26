extern printf

%macro SAVE_CHAR_FUNC 2
	lea rax, [rel spec_jump_table]
	mov rbx, %1
	mov qword [rax + rbx * 8], %2
%endmacro

%macro PRINT_OUT 2
	mov rax, 1
	mov rdi, 1
	mov rsi, %1
	mov rdx, %2
	syscall
%endmacro
section .data
	hex_begin	db '0x'
	oct_begin 	db '0q'
	bin_begin 	db '0b'
	hex_alp 	db '0123456789abcdef'
	perc		db '%'
	number		times 0x21 db '0'
	mask		dd 0
	digit_bit_size	dd 0
	minus 		db '-'
	dec_dig_cnt 	db 0
	loop_cnt 	db 0

section .data
spec_jump_table:
	times 26 dq wrong_spec

section .text
	global my_printf
	global my_printf_cdecl

;=====================================================
; my_print в формате stdcall
;=====================================================
my_printf:				
	pop rax				; сохраняем адрес возврата
	sub  rsp, 	8 * 6		; сохраняем 6 аргументов (трамплин)
	mov [rsp],	rdi
	mov [rsp + 8],	rsi
	mov [rsp + 16],	rdx
	mov [rsp + 24],	rcx
	mov [rsp + 32], r8
	mov [rsp + 40], r9

	push rax

	call my_printf_cdecl

	pop rax

	pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop r8
	pop r9
	push rax
	ret
;-----------------------------------------------------


;=====================================================
; my_printf в формате cdecl
;=====================================================
my_printf_cdecl:
	push rbp
	mov  rbp, rsp
	push rbx
	push r12			; r11 -> сохраняются флаги во время syscall
	push r13			; r10 -> используется для аргументов при системных вызовах
	push r14
	push r15

	call jump_table_init

	mov  r12, [rbp + 8 * 3]		; форматная строка (до rbp и 2-x адресов возврата) 
	lea  r13, [rbp + 8 * 4]		; 2-й и остальные аргументы

.loop:
	mov dl, [r12]
	cmp dl, 0
	je .printf_end

	cmp dl, '%'
	je .percent

.base_symbol:
	mov rax, 1
	mov rdi, 1
	mov rsi, r12
	mov rdx, 1
	syscall

	inc r12
	jmp .loop

.percent:
	inc r12
	movzx rdx, byte [r12]
	cmp dl, 'a'
	jl .unknown
	cmp dl, 'z'
	jg .unknown
	lea rax, [rel spec_jump_table]
	call qword [rax + (rdx - 'a') * 8]
	jmp .loop

.unknown:
	PRINT_OUT r12, 1
	inc r12
	jmp .loop

.printf_end:
	call std_printf

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret
;------------------------------------------------------


;======================================================
; Выводит строку с помощью библиотечного printf
;
; Entry:	-
;
; Expected:	rbp + 8 * 3 - 1-й аргумент
;
; Destruction:	rax, rbx, rdi, rsi, rdx, rcx, r8, r9, r13, r14
;======================================================
std_printf:
	mov rdi, [rbp + 8 * 3]			; в rdi форматная строка
	lea rbx, [rbp + 8 * 4]			; адрес 2-го аргумента
	sub r13, rbx				; r13 = количество аргументов * 8
	sub r13, 8 * 5

	mov rsi, [rbx]				; 2-й
	mov rdx, [rbx + 8]			; 3-й
	mov rcx, [rbx + 8 * 2]			; 4-й
	mov r8,  [rbx + 8 * 3]			; 5-й
	mov r9,  [rbx + 8 * 4]			; 6-й
	add rbx, 8 * 4
	xor r14, r14

.save_arg:
	cmp r13, 0
	jle .call_printf

	push qword [rbx + r13]
	inc r14

	sub r13, 8
	jmp .save_arg

.call_printf:
	xor rax, rax
	call printf

.clear_stack:
	cmp r14, 0
	je .end_clear
	pop rax
	dec r14
	jmp .clear_stack

.end_clear:
	ret
;------------------------------------------------------


;======================================================
; Заполняем jump-table
;
; Destruction:	rax
;======================================================
jump_table_init:
	SAVE_CHAR_FUNC 'c' - 'a', print_char
	SAVE_CHAR_FUNC 'x' - 'a', wrap_print_hex
	SAVE_CHAR_FUNC 'o' - 'a', wrap_print_oct
	SAVE_CHAR_FUNC 'b' - 'a', wrap_print_bin
	SAVE_CHAR_FUNC 'd' - 'a', print_dec
	SAVE_CHAR_FUNC 's' - 'a', print_string
	ret
;-----------------------------------------------------


;=====================================================
; В случае неправильного спецификатора ничего не выводим
;
; Entry:	-
;
; Result:	r12 = r12 + 1
;
; Expected:	-
;
; Destruction:	r12
;=====================================================
wrong_spec:
	mov rax, 1
	mov rdi, 1
	lea rbx, [rel perc]
	mov rsi, rbx
	mov rdx, 1
	syscall

	PRINT_OUT r12, 1

	inc r12
	ret
;------------------------------------------------------


;=====================================================
; Entry:	[r12] = '%'
;
; Result:	Выведет символ '%' на экран
;		r12 = r12 + 1
;
; Expected:	-
;
; Destruction:	r12, rax, rsi, rdi, rdx
;=====================================================
print_percent:
	PRINT_OUT r12, 1

	inc r12
	ret
;-----------------------------------------------------


;=====================================================
; Entry:	[r13] = ascii-код символа, который нужно вывести
;
; Result:	Выведет символ на экран (если он попадает 
;		в границы от 0 до 255)
;		r13 = r13 + 8
;		r12 = r12 + 1
;
; Expected:	-
;
; Destruction:	r13, r12, rax, rsi, rdi, rdx
;=====================================================
print_char:
	mov rax, [r13]
	cmp rax, 0xff
	jbe .right_char
	add r13, 8
	inc r12			; ничего не выводим, если неправильный char
	ret

.right_char:
	PRINT_OUT r13, 1

	add r13, 8
	inc r12
	ret
;-----------------------------------------------------


;=====================================================
; трамплин для вывода шестнадцатеричного числа
;
; Result:	устанавливает mask = 4
;		запускает вывод числа
;=====================================================
wrap_print_hex:
	lea rax, [rel mask]
	mov byte [rax], 0xf
	lea rax, [rel digit_bit_size]
	mov byte [rax], 4
	call print_bin
	ret
;-----------------------------------------------------


;=====================================================
; трамплин для вывода восьмеричного числа
;
; Result:	устанавливает mask = 3
;		запускает вывод числа
;=====================================================
wrap_print_oct:
	lea rax, [rel mask]
	mov byte [rax], 0x7
	lea rax, [rel digit_bit_size]
	mov byte [rax], 3
	call print_bin
	ret
;-----------------------------------------------------


;=====================================================
; трамплин для вывода двоичного числа
;
; Result:	устанавливает mask = 1
;		запускает вывод числа
;=====================================================
wrap_print_bin:
	lea rax, [rel mask]
	mov byte [rax], 0x1
	lea rax, [rel digit_bit_size]
	mov byte [rax], 1
	call print_bin
	ret
;-----------------------------------------------------


;=====================================================
; Entry:	[r13] = 32-битное число, которое нужно вывести
;		в системе счисления, являющейся степенью 2
;
; Result:	Выведет число на экран
;		r13 = r13 + 8
;		r12 = r12 + 1
;
; Expected:	2^digit_bit_size = система счисления
;
; Destruction:	r13, r12, rax, rbx, rcx, rdx, rsi, rdi
;=====================================================
print_bin:
	lea rbx, [rel number]
	mov rdi, rbx
	add rdi, 0x20
	mov rax, [r13]
	add r13, 8
	xor rdx, rdx

.save_dig:
	push rax
	mov cl, 0x40
	lea rbx, [rel mask]		; заменить сдвиги на маску
	and rax, qword [rbx]
	lea rbx, [rel hex_alp]
	mov bl, byte [rbx + rax]
	mov byte [rdi], bl
	
	dec rdi
	lea rbx, [rel digit_bit_size]
	mov cl, byte [rbx]
	pop rax
	shr rax, cl
	inc rdx
	cmp rax, 0
	jne .save_dig

.print_digs:
	inc rdi
	mov rsi, rdi
	mov rax, 1
	mov rdi, 1 
	syscall

	inc r12
	ret
;-----------------------------------------------------


;=====================================================
; Entry:	[r13] = 32-битное число, которое нужно вывести
;
; Result:	Выведет на экран 32-битное число [r13]
;		r13 = r13 + 8
;		r12 = r12 + 1
;
; Expected:	-
;
; Destruction:	r13, r12, rax, rbx, rsi, rdi, rdx, rcx
;=====================================================
print_dec:
	mov eax, [r13]
	cmp eax, 0
	jne .not_null
	mov rax, 1
	mov rdi, 1
	lea rbx, [rel number]
	mov rsi, rbx			; если число равно 0 сразу выводим
	mov rdx, 1
	syscall

	add r13, 8
	inc r12
	ret

.not_null:
	cmp eax, 0
	jg .positive
	mov rax, 1
	mov rdi, 1
	lea rbx, [rel minus]
	mov rsi, rbx
	mov rdx, 1
	syscall

	mov eax, [r13]
	neg eax

.positive:
	lea rbx, [rel dec_dig_cnt]
	mov byte [rbx], 0
	lea rbx, [rel number]
	mov rdi, rbx
	add rdi, 9			; rdi указывает на последнюю цифру

.print_dec_dig:
	xor rdx, rdx
	mov rbx, 10
	div rbx				; rdx = посл. цифра (остаток при делении на 10)
	lea rbx, [rel hex_alp]
	mov cl, [rbx + rdx]
	mov byte [rdi], cl
	dec rdi
	lea rbx, [rel dec_dig_cnt]
	inc byte [rbx]
	cmp eax, 0
	jne .print_dec_dig

	inc rdi				; вывод полученного числа
	mov rsi, rdi
	mov rax, 1
	mov rdi, 1
	lea rbx, [rel dec_dig_cnt]
	movzx rdx, byte [rbx]
	syscall

	add r13, 8
	inc r12
	ret
;-----------------------------------------------------


;=====================================================
; Entry:	[r13] = адрес начала строки
;		[r12] = 's'
;
; Result:	Выведет строку на экран
;		r13 = r13 + 8
;		r12 = r12 + 1
;
; Expected:	-
;
; Destruction:	r13, r12, rax, rcx, rdx, rsi, rdi
;=====================================================
print_string:
	mov rcx, [r13]
	add r13, 8
	xor rdx, rdx
	push rcx

.calc_len:
	cmp byte [rcx], 0
	je .end_calc
	inc rcx
	inc rdx
	jmp .calc_len

.end_calc:
	pop rsi
	mov rax, 1
	mov rdi, 1
	syscall

	inc r12
	ret
;-----------------------------------------------------