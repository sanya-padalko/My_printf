section .data
	hex_begin	db '0x'
	oct_begin 	db '0q'
	bin_begin 	db '0b'
	hex_alp 	db '0123456789ABCDEF'
	number		times 0x21 db '0'
	digit_bit_size	dd 1
	minus 		db '-'
	dec_dig_cnt 	db 0
	loop_cnt 	db 0

section .text
	global my_printf
	global my_printf_cdecl

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

my_printf_cdecl:
	push rbp
	mov  rbp, rsp
	push rbx
	push r12			; r11 -> сохраняются флаги во время syscall
	push r13			; r10 -> используется для аргументов при системных вызовах
	push r14
	push r15

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
	mov dl, [r12]
	cmp dl, '%'
	je .print_percent
	cmp dl, 'c'
	je .print_char
	mov byte [digit_bit_size], 4
	cmp dl, 'x'
	je .print_bin
	dec byte [digit_bit_size]
	cmp dl, 'o'
	je .print_bin
	sub byte [digit_bit_size], 2
	cmp dl, 'b'
	je .print_bin
	cmp dl, 'd'
	je .print_dec
	cmp dl, 's'
	je .print_string

	inc r12
	jmp .loop

.print_percent:
	mov rax, 1
	mov rdi, 1
	mov rsi, r12		; [r12] = второй '%'
	mov rdx, 1
	syscall

	inc r12
	jmp .loop

.print_char:
	mov rax, [r13]
	cmp rax, 0xff
	jbe .right_char
	inc r12			; ничего не выводим
	jmp .loop

.right_char:
	mov rax, 1
	mov rdi, 1
	mov rsi, r13		; [r13] = переданный char
	mov rdx, 1
	syscall

	add r13, 8
	inc r12
	jmp .loop

.print_bin:
	mov rdi, number
	add rdi, 0x20
	mov rax, [r13]
	add r13, 8
	xor rdx, rdx

.save_bin_dig:
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
	jne .save_bin_dig

.print_digs:
	inc rdi
	mov rsi, rdi
	mov rax, 1
	mov rdi, 1 
	syscall

	inc r12
	jmp .loop

.print_dec:
	mov rax, [r13]
	cmp rax, 0
	jne .not_null
	mov rax, 1
	mov rdi, 1
	mov rsi, number			; если число равно 0 сразу выводим
	mov rdx, 1
	syscall

	add r13, 8
	inc r12
	jmp .loop

.not_null:
	cmp rax, 0
	jg .positive
	mov rax, 1
	mov rdi, 1
	mov rsi, minus
	mov rdx, 1
	syscall

	mov rax, [r13]
	neg rax

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
	cmp rax, 0
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
	jmp .loop

.print_string:
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
	jmp .loop

.printf_end:
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret