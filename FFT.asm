.data
twiddle_n2:
    .word 1, 0      # W2^0 = 1
    .word -1, 0     # W2^1 = -1

twiddle_n4:
    .word 1, 0      # W4^0 (real, imag)
    .word 0, -1     # W4^1

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
    jal fft
    
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

fft:
    addiu $sp, $sp, -32       #inorder to store all 8 registers and i need to store return address im allocating 32 bits of memory 
    sw $ra, 28($sp)           #return address stored
    sw $s0, 24($sp)
    sw $s1, 20($sp)
    sw $s2, 16($sp)
    sw $s3, 12($sp)
    sw $s4, 8($sp)
    sw $s5, 4($sp)
    sw $s6, 0($sp)

    move $s0, $a0         #s0 consists of n
    move $s1, $a1         #s1 consists of base address of the input array

    li $t0, 2           
    beq $s0, $t0, fft_n2   #branching depending on the size of array
    li $t0, 4
    beq $s0, $t0, fft_n4
    j fft_exit

fft_n2:
    lw $t0, 0($s1)  # x[0].real 
    lw $t1, 4($s1)  # x[0].imag
    lw $t2, 8($s1)  # x[1].real
    lw $t3, 12($s1) # x[1].imag

    add $t4, $t0, $t2   # X0.real
    add $t5, $t1, $t3   # X0.imag
    sub $t6, $t0, $t2   # X1.real
    sub $t7, $t1, $t3   # X1.imag

    sw $t4, 0($s1)
    sw $t5, 4($s1)
    sw $t6, 8($s1)
    sw $t7, 12($s1)
    j fft_exit

fft_n4:
    move $s2, $s1   # Base address

    # Create temporary arrays on stack for even/odd elements
    addiu $sp, $sp, -32
    sw $ra, 28($sp)

    # Copy even elements (0 and 2) to temp_even
    lw $t0, 0($s2)       # Even[0].real
    lw $t1, 4($s2)       # Even[0].imag
    sw $t0, 0($sp)       # temp_even[0].real
    sw $t1, 4($sp)       # temp_even[0].imag

    lw $t0, 16($s2)      # Even[1].real (original element 2)
    lw $t1, 20($s2)      # Even[1].imag
    sw $t0, 8($sp)       # temp_even[1].real
    sw $t1, 12($sp)      # temp_even[1].imag

    # Compute FFT2 on even elements
    li $a0, 2
    move $a1, $sp
    jal fft

    # Copy results back to even positions
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    sw $t0, 0($s2)       # E0.real
    sw $t1, 4($s2)       # E0.imag

    lw $t0, 8($sp)
    lw $t1, 12($sp)
    sw $t0, 16($s2)      # E1.real (element 2)
    sw $t1, 20($s2)      # E1.imag

    # Copy odd elements (1 and 3) to temp_odd
    lw $t0, 8($s2)       # Odd[0].real (original element 1)
    lw $t1, 12($s2)      # Odd[0].imag
    sw $t0, 16($sp)      # temp_odd[0].real
    sw $t1, 20($sp)      # temp_odd[0].imag

    lw $t0, 24($s2)      # Odd[1].real (original element 3)
    lw $t1, 28($s2)      # Odd[1].imag
    sw $t0, 24($sp)      # temp_odd[1].real
    sw $t1, 28($sp)      # temp_odd[1].imag

    # Compute FFT2 on odd elements
    li $a0, 2
    addiu $a1, $sp, 16   # Address of temp_odd
    jal fft

    # Copy results back to odd positions
    lw $t0, 16($sp)
    lw $t1, 20($sp)
    sw $t0, 8($s2)       # O0.real (element 1)
    sw $t1, 12($s2)      # O0.imag

    lw $t0, 24($sp)
    lw $t1, 28($sp)
    sw $t0, 24($s2)      # O1.real (element 3)
    sw $t1, 28($s2)      # O1.imag

    # Restore stack and RA
    lw $ra, 28($sp)
    addiu $sp, $sp, 32

    # Now combine results with twiddle factors
    # Load E0 (0,4) and O0 (8,12)
    lw $t0, 0($s2)       # E0.real
    lw $t1, 4($s2)       # E0.imag
    lw $t2, 8($s2)       # O0.real
    lw $t3, 12($s2)      # O0.imag

    # Multiply O0 by W4^0 (1,0)
    la $t8, twiddle_n4
    lw $t9, 0($t8)       # Wr
    lw $t8, 4($t8)       # Wi
    mul $s4, $t2, $t9
    mul $s5, $t3, $t8
    sub $s4, $s4, $s5    # Real
    mul $s6, $t2, $t8
    mul $s7, $t3, $t9
    add $s5, $s6, $s7    # Imag

    # Compute X0 and X2
    add $t4, $t0, $s4    # X0.real
    add $t5, $t1, $s5    # X0.imag
    sub $t6, $t0, $s4    # X2.real
    sub $t7, $t1, $s5    # X2.imag

    # Store X0 and X2
    sw $t4, 0($s2)
    sw $t5, 4($s2)
    sw $t6, 16($s2)
    sw $t7, 20($s2)

    # Load E1 (16,20) and O1 (24,28)
    lw $t0, 16($s2)     # E1.real
    lw $t1, 20($s2)     # E1.imag
    lw $t2, 24($s2)     # O1.real
    lw $t3, 28($s2)     # O1.imag

    # Multiply O1 by W4^1 (0,-1)
    la $t8, twiddle_n4
    lw $t9, 8($t8)      # Wr
    lw $t8, 12($t8)     # Wi
    mul $s4, $t2, $t9
    mul $s5, $t3, $t8
    sub $s4, $s4, $s5   # Real
    mul $s6, $t2, $t8
    mul $s7, $t3, $t9
    add $s5, $s6, $s7   # Imag

    # Compute X1 and X3
    add $t2, $t0, $s4   # X1.real
    add $t3, $t1, $s5   # X1.imag
    sub $t4, $t0, $s4   # X3.real
    sub $t5, $t1, $s5   # X3.imag

    # Store X1 and X3
    sw $t2, 8($s2)
    sw $t3, 12($s2)
    sw $t4, 24($s2)
    sw $t5, 28($s2)

fft_exit:
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
