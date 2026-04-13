.data
twiddle_n2_ifft:
    .word 1, 0      # W2^0 = 1 (unchanged)
    .word -1, 0     # W2^1 = -1 (unchanged)

twiddle_n4_ifft:
    .word 1, 0      # W4^0 (1, 0)
    .word 0, 1      # W4^1 (0, 1) ← Conjugated

input_array:
    .space 32        # 8 words (4 complex numbers)
prompt_n:
    .asciiz "Enter N (2 or 4): "
prompt_real:
    .asciiz "Enter real part of element "
prompt_imag:
    .asciiz "Enter imaginary part of element "
colon:
    .asciiz ": "
xk_prompt:
    .asciiz "X["
index_str:
    .asciiz "] = "
plus_sign:
    .asciiz " + "
minus_sign:
    .asciiz " - "
i_suffix:
    .asciiz "i\n"

.text
.globl main

main:
    # Read N from user
    li $v0, 4
    la $a0, prompt_n
    syscall
    
    li $v0, 5
    syscall
    move $s0, $v0   #$s0 consists of n
    
    # Read input array
    move $t0, $s0   # n is stored in t0 now
    li $t1, 0       # initialised i = 0

input_loop:
    bge $t1, $t0, end_input      #if t1>= t0 then we are gonna end the loop!
    
    #this block reads the real number from the user! the input is being stored as [real(0),imag(0),real(1),imag(1).......] like that in the array
    li $v0, 4
    la $a0, prompt_real
    syscall
    li $v0, 1
    move $a0, $t1
    syscall
    li $v0, 4
    la $a0, colon
    syscall
    li $v0, 5
    syscall
    move $t2, $v0          #t2 consists of address of the real number location in the input_array
    
    # Read imaginary part
    li $v0, 4
    la $a0, prompt_imag
    syscall
    li $v0, 1
    move $a0, $t1
    syscall
    li $v0, 4
    la $a0, colon
    syscall
    li $v0, 5
    syscall
    move $t3, $v0         #t3 consists of address of the latest imaginary part of the input_array 
    
    # Store in array
    la $t4, input_array    #t4 consists of base address of the array which we allocated space to 
    sll $t5, $t1, 3         
#t5 is used to increment the base address of the array each time inorder to add the next element after the current element it just multiplies the index with 8 (shifting left by 3 bits 
#then changes t4 evertime by that much..
    addu $t4, $t4, $t5        
    sw $t2, 0($t4)  #t2 which consists of real number address is stored at 0(t4) and imag 4 bits after...
    sw $t3, 4($t4)
    
    addiu $t1, $t1, 1    #increment the index counter!
    j input_loop

end_input:
    # Call FFT
    move $a0, $s0
    la $a1, input_array
    jal ifft
    
    # Print results
    move $t1, $zero     # Counter i = 0
    move $t0, $s0       # N

print_loop:
    bge $t1, $t0, end_print
    
    # Load complex number
    la $t4, input_array
    sll $t5, $t1, 3
    addu $t4, $t4, $t5
    lw $t2, 0($t4)      # Real
    lw $t3, 4($t4)      # Imag
    
    # Print "X[i] = "
    li $v0, 4
    la $a0, xk_prompt
    syscall
    li $v0, 1
    move $a0, $t1
    syscall
    li $v0, 4
    la $a0, index_str
    syscall
    
    # Print real part
    li $v0, 1
    move $a0, $t2
    syscall
    
    # Handle imaginary part
    bltz $t3, print_neg
    li $v0, 4
    la $a0, plus_sign
    syscall
    j print_imag
print_neg:
    li $v0, 4
    la $a0, minus_sign
    syscall
    sub $t3, $zero, $t3
print_imag:
    li $v0, 1
    move $a0, $t3
    syscall
    li $v0, 4
    la $a0, i_suffix
    syscall
    
    addiu $t1, $t1, 1
    j print_loop

end_print:
    li $v0, 10
    syscall

ifft:
    # Preserve registers
    addiu $sp, $sp, -32
    sw $ra, 28($sp)
    sw $s0, 24($sp)
    sw $s1, 20($sp)
    sw $s2, 16($sp)
    sw $s3, 12($sp)
    sw $s4, 8($sp)
    sw $s5, 4($sp)
    sw $s6, 0($sp)

    move $s0, $a0   # N
    move $s1, $a1   # Array

    li $t0, 2
    beq $s0, $t0, ifft_n2
    li $t0, 4
    beq $s0, $t0, ifft_n4
    j end_scale

ifft_n2:
    # Butterfly operations (subtract first, then add)
    lw $t0, 0($s1)  # x[0].real
    lw $t1, 4($s1)  # x[0].imag
    lw $t2, 8($s1)  # x[1].real
    lw $t3, 12($s1) # x[1].imag

    sub $t4, $t0, $t2   # X0.real = x[0].real - x[1].real
    sub $t5, $t1, $t3   # X0.imag = x[0].imag - x[1].imag
    add $t6, $t0, $t2   # X1.real = x[0].real + x[1].real
    add $t7, $t1, $t3   # X1.imag = x[0].imag + x[1].imag

    # Scale by 1/2
    sra $t4, $t4, 1     # X0.real /= 2
    sra $t5, $t5, 1     # X0.imag /= 2
    sra $t6, $t6, 1     # X1.real /= 2
    sra $t7, $t7, 1     # X1.imag /= 2

    # Store results
    sw $t6, 0($s1)
    sw $t7, 4($s1)
    sw $t4, 8($s1)
    sw $t5, 12($s1)
    j end_scale

ifft_n4:
    move $s2, $s1   # Base address

    # Compute IFFT2 on even elements (indices 0 and 2)
    li $a0, 2
    move $a1, $s2
    jal ifft

    # Compute IFFT2 on odd elements (indices 1 and 3)
    li $a0, 2
    addiu $a1, $s2, 16
    jal ifft

    # Load E0 and O0 for X0/X2
    lw $t0, 0($s2)   # E0.real
    lw $t1, 4($s2)   # E0.imag
    lw $t2, 16($s2)  # O0.real
    lw $t3, 20($s2)  # O0.imag

    # Multiply O0 by W4^0 (1,0)
    la $t8, twiddle_n4_ifft
    lw $t9, 0($t8)   # Wr
    lw $t8, 4($t8)   # Wi
    mul $s4, $t2, $t9
    mul $s5, $t3, $t8
    sub $s4, $s4, $s5  # Real
    mul $s6, $t2, $t8
    mul $s7, $t3, $t9
    add $s5, $s6, $s7  # Imag

    # Compute X0 and X2
    add $t4, $t0, $s4
    add $t5, $t1, $s5
    sub $t6, $t0, $s4
    sub $t7, $t1, $s5

    # Store X0 and X2
    sw $t4, 0($s2)
    sw $t5, 4($s2)
    sw $t6, 16($s2)
    sw $t7, 20($s2)

    # Load E1 and O1 for X1/X3
    lw $t0, 8($s2)    # E1.real
    lw $t1, 12($s2)   # E1.imag
    lw $t2, 24($s2)   # O1.real
    lw $t3, 28($s2)   # O1.imag

    # Multiply O1 by W4^1 (0,1) ← Conjugated
    la $t8, twiddle_n4_ifft
    lw $t9, 8($t8)    # Wr
    lw $t8, 12($t8)   # Wi
    mul $s4, $t2, $t9
    mul $s5, $t3, $t8
    sub $s4, $s4, $s5  # Real
    mul $s6, $t2, $t8
    mul $s7, $t3, $t9
    add $s5, $s6, $s7  # Imag

    # Compute X1 and X3
    add $t2, $t0, $s4
    add $t3, $t1, $s5
    sub $t4, $t0, $s4
    sub $t5, $t1, $s5

    # Store X1 and X3
    sw $t2, 8($s2)
    sw $t3, 12($s2)
    sw $t4, 24($s2)
    sw $t5, 28($s2)

    # Scale all results by 1/4
    li $t1, 0
    move $t0, $s0
scale_loop:
    bge $t1, $t0, end_scale
    la $t4, input_array
    sll $t5, $t1, 3
    addu $t4, $t4, $t5
    lw $t2, 0($t4)
    lw $t3, 4($t4)
    div $t2, $s0
    mflo $t2
    div $t3, $s0
    mflo $t3
    sw $t2, 0($t4)
    sw $t3, 4($t4)
    addiu $t1, $t1, 1
    j scale_loop

end_scale:
    # Restore registers
    lw $ra, 28($sp)
    lw $s0, 24($sp)
    lw $s1, 20($sp)
    lw $s2, 16($sp)
    lw $s3, 12($sp)
    lw $s4, 8($sp)
    lw $s5, 4($sp)
    lw $s6, 0($sp)
    addiu $sp, $sp, 32
    jr $ra
