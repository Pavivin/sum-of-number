format ELF64
public _start

section '.data' writable
    filename db "test_file.txt", 0
    error_msg db "File does not exist", 0

section '.bss' writable
    _bss_char rb 1

    _buffer_number_size equ 21
    _buffer_number rb _buffer_number_size

    buffer_size equ 20
    buffer rb buffer_size 

section '.text' executable
_start:

    mov rax, filename 
    jb .error                                   ; if CF = 1 then we have error with open file

    mov rbx, 0                                  ; 0 - read only, 1 - write only, 2 - write and read
    
    mov rcx, rbx
    mov rbx, rax                                ; rax = filename    
    mov rax, 5                                  ; open
    int 0x80                               

    mov rbx, buffer
    mov rcx, buffer_size
    call read

    push rax
    mov rax, buffer
    call sum_numbers
    call print_number
    pop rax   

    mov rbx, rax
    mov rax, 6                                  ; close
    int 0x80
    call print_line  
    call _exit

    .error: 
    mov rax, error_msg
    call print_string
    call print_line
    call _exit

section '.sum_numbers' executable               ; input: rax = string
sum_numbers:                                    ; output: rax = number
    push rbx                                    ; length of string
    push rcx
    push rdx
    xor rbx, rbx
    xor rcx, rcx
    .next_iter:
        cmp [rax+rbx], byte 0                   ;is the character the end of a string
        je .next_step
        mov cl, [rax+rbx]
        ;je .next_step
        cmp cl, '0'                             ;comparing characters for numbers 
        jb .space
        cmp cl, '9'
        ja .space
        sub cl, '0'                             ;transforming a sign into a number
        push rcx
        inc rbx
        jmp .next_iter
    .space:
        mov rcx, 1
        inc rax
        jmp .next_iter
    .next_step:
        mov rcx, 1
        xor rax, rax
    .to_number:
        cmp rbx, 0
        je .close
        pop rdx
        imul rdx, rcx                           ; convert to number with 10 degree  
        imul rcx, 10                            ; stores a degree of 10 
        add rax, rdx                            ; sum of digits in rax
        dec rbx                                 ; subtracting from the total number of characters
        jmp .to_number
    .close:
        ;cmp cl, byte 0                         ;is the character the end of a string
        ;jne .next_iter
        pop rdx
        pop rcx
        pop rbx
        ret

section '.read' executable
read:
    push rax
    push rbx
    push rcx
    push rdx

    push rbx
    push rcx

    mov rbx, 1
    xor rcx, rcx
    call seek

    pop rcx
    pop rbx

    mov rdx, rcx
    mov rcx, rbx
    mov rbx, rax
    mov rax, 3                                  ; read
    int 0x80

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

section '.seek' executable
seek:
    push rax
    push rbx
    push rdx

    mov rdx, rbx
    mov rbx, rax
    mov rax, 19                                ; seek
    int 0x80

    pop rdx
    pop rbx
    pop rax
    ret

section '.input_string' executable
in_string:
    push rax                                    ; rax = buffer
    push rbx                                    ; rbx = buffer_size
    push rcx
    push rdx

    push rax

    mov rcx, rax
    mov rdx, rbx
    mov rax, 3                                  ; read
    mov rbx, 2                                  ; stdin
    int 0x80

    pop rbx
    mov [rbx+rax-1], byte 0

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

section '.print_string' executable
print_string:
    push rax                                   ; rax = string
    push rbx
    push rcx
    push rdx

    mov rcx, rax
    call len_string

    mov rdx, rax
    mov rax, 4
    mov rbx, 1
    int 0x80

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

section '.len_string' executable                ; input : rax = string
len_string:                                     ; output : rax = length
    push rdx
    xor rdx, rdx
    .next_iter:
        cmp [rax+rdx], byte 0                   ; comparing for 0 (null-terminator)
        je .close                               ; if last letter is 0 then close
        inc rdx
        jmp .next_iter
    .close:
        mov rax, rdx                            ; copy value from rdx to rax
        pop rdx
        ret                                     ; return to begin for miltiply launches

section '.print_number' executable             ; input: rax = number
print_number:
    push rax
    push rbx
    push rcx
    push rdx
    xor rcx, rcx
    .next_iter:
        mov rbx, 10
        xor rdx, rdx
        div rbx
        add rdx, '0'
        push rdx
        inc rcx
        cmp rax, 0
        je .print_iter
        jmp .next_iter
    .print_iter:
        cmp rcx, 0
        je .close
        pop rax
        call print_char
        dec rcx
        jmp .print_iter
    .close:
        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

section '.print_char' executable               ; input: rax = char
print_char:
    push rdx
    push rcx
    push rbx
    push rax

    mov [_bss_char], al

    mov rax, 4
    mov rbx, 1
    mov rcx, _bss_char
    mov rdx, 1
    int 0x80

    pop rax
    pop rbx
    pop rcx
    pop rdx
    ret

section '.print_line' executable
print_line:
    push rax
    mov rax, 0xA
    call print_char
    pop rax
    ret

section '._exit' executable
_exit:
    mov rax, 1
    mov rbx, 0
    int 0x80