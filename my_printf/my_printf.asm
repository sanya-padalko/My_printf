extern printf

%macro save_char_func 2
	mov qword [spec_jump_table + %1 * 8], %2
%endmacro
section .data
	hex_begin	db '0x'
	oct_begin 	db '0q'
	bin_begin 	db '0b'
	hex_alp 	db '0123456789abcdef'
	number		times 0x21 db '0'
	digit_bit_size	dd 1
	minus 		db '-'
	dec_dig_cnt 	db 0
	loop_cnt 	db 0

section .data
spec_jump_table:
	times 256 dq wrong_spec

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
	xor rdx, rdx
	mov dl, [r12]				; заменить на movzx
	call qword [spec_jump_table + rdx * 8]
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
; Expected:	rbp + 8 * 3 - 1-й аргумент
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
	xor r15, r15

.save_arg:
	cmp r13, 0
	jle .call_printf

	push qword [rbx + r13]
	inc r15

	sub r13, 8
	jmp .save_arg

.call_printf:
	xor rax, rax
	call printf

.clear_stack:
	cmp r15, 0
	je .end_clear
	pop rax
	dec r15
	jmp .clear_stack

.end_clear:
	ret
;------------------------------------------------------


;======================================================
; Заполняем jump-table
;======================================================
jump_table_init:
	save_char_func '%', print_percent
	save_char_func 'c', print_char
	save_char_func 'x', wrap_print_hex
	save_char_func 'o', wrap_print_oct
	save_char_func 'b', wrap_print_bin
	save_char_func 'd', print_dec
	save_char_func 's', print_string
	ret
;------------------------------------------------------


;======================================================
; Неверный спецификатор
;======================================================
wrong_spec:
	inc r12
	ret
;------------------------------------------------------


;======================================================
; Вывод '%'
;======================================================
print_percent:
	mov rax, 1
	mov rdi, 1
	mov rsi, r12		; [r12] = второй '%'
	mov rdx, 1
	syscall

	inc r12
	ret
;-----------------------------------------------------


;=====================================================
; Вывод %c
;=====================================================
print_char:
	mov rax, [r13]
	cmp rax, 0xff
	jbe .right_char
	add r13, 8
	inc r12			; ничего не выводим, если неправильный char
	ret

.right_char:
	mov rax, 1
	mov rdi, 1
	mov rsi, r13		; [r13] = переданный char
	mov rdx, 1
	syscall

	add r13, 8
	inc r12
	ret
;-----------------------------------------------------


;=====================================================
; print_hex трамплин
;=====================================================
wrap_print_hex:
	mov byte [digit_bit_size], 4
	call print_bin
	ret
;-----------------------------------------------------


;=====================================================
; print_oct-трамплин
;=====================================================
wrap_print_oct:
	mov byte [digit_bit_size], 3
	call print_bin
	ret
;-----------------------------------------------------


;=====================================================
; print_bin-трамплин
;=====================================================
wrap_print_bin:
	mov byte [digit_bit_size], 1
	call print_bin
	ret
;-----------------------------------------------------


;=====================================================
; Вывод числа в системе счисления, равной степени двойки
;=====================================================
print_bin:
	mov rdi, number
	add rdi, 0x20
	mov rax, [r13]
	add r13, 8
	xor rdx, rdx

.save_dig:
	push rax
	mov cl, 0x40
	sub cl, byte [digit_bit_size]
	shl rax, cl
	shr rax, cl
	mov bl, byte [hex_alp + rax]
	mov byte [rdi], bl
	
	dec rdi
	mov cl, byte [digit_bit_size]
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
; Вывод десятичного числа
;=====================================================
print_dec:
	xor rax, rax
	mov eax, [r13]
	cmp eax, 0
	jne .not_null
	mov rax, 1
	mov rdi, 1
	mov rsi, number			; если число равно 0 сразу выводим
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
	mov rsi, minus
	mov rdx, 1
	syscall

	mov eax, [r13]
	neg eax

.positive:
	mov byte [dec_dig_cnt], 0
	mov rdi, number
	add rdi, 9			; rdi указывает на последнюю цифру

.print_dec_dig:
	xor rdx, rdx
	mov rbx, 10
	div rbx				; rdx = посл. цифра (остаток при делении на 10)
	mov cl, [hex_alp + rdx]
	mov byte [rdi], cl
	dec rdi
	inc byte [dec_dig_cnt]
	cmp eax, 0
	jne .print_dec_dig

	inc rdi				; вывод полученного числа
	mov rsi, rdi
	mov rax, 1
	mov rdi, 1
	xor rdx, rdx
	mov dl, byte [dec_dig_cnt]
	syscall

	add r13, 8
	inc r12
	ret
;-----------------------------------------------------


;=====================================================
; Вывод строки
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