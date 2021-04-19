.data
    num_rows:               .word 1
    num_columns:            .word 9
    space:                  .asciiz " "
    bl:                     .asciiz "\n"

.text

main:
    # create matrix_int buffer
    li $v0, 9
    li $a0, 36         # matrix_int_size 
    syscall 
    move $s0, $v0

    move $t0, $s0
    
    li $t1, 1
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 2
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 3
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 5
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 6
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 7
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 8
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 9
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    # create matrix_int buffer
    li $v0, 9
    li $a0, 36         # matrix_int_size 
    syscall 
    move $s1, $v0

    move $t0, $s1
    
    li $t1, 1
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, -3
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 4
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, -5
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 6
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 7
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 1
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $t1, 2
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    move $a0, $s0 
    move $a1, $s1 
    jal sum_two_matrices
    move $s2, $v0

    move $a0, $s2
    jal print_matrix_int

    li $v0, 10
    syscall

sum_two_matrices:
    # args: $a0 - m0, $a1 - m1
    addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $ra, 20($sp)

    move $s0, $a0       # m0_address
    move $s1, $a1       # m1_address
    lw $t0, num_rows
    lw $t1, num_columns
    mul $s2, $t0, $t1   # matrix_length
    li $s3, 0           # counter
    li $s4, 0           # m_result_address

    # create matrix_int buffer
    li $v0, 9
    move $a0, $s2         # matrix_length 
    syscall 
    move $s4, $v0


    stm_loop:
        beq $s3, $s2, stm_end   # if (counter == matrix_length) break

        li $t0, 4               # sizeof(int)
        mul $t1, $s3, $t0   
        add $t1, $t1, $s0       # pos0 = m0_address + (counter * sizeof(int))
        mul $t2, $s3, $t0
        add $t2, $t2, $s1       # pos1 = m1_address + (counter * sizeof(int))
        mul $t3, $s3, $t0
        add $t3, $t3, $s4       # pos_result = m_result_address + (counter * sizeof(int))
        
        lw $t4, 0($t1)
        lw $t5, 0($t2)
        add $t6, $t4, $t5       # m0[counter] + m1[counter]
        sw $t6, 0($t3)          # m_result[counter] = m0[counter] + m1[counter]

        addi $s3, $s3, 1        # counter++

        j stm_loop

    stm_end:
    move $v0, $s4

    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra
    # return: $v0 - m_result_address 

print_matrix_int:
    # args: $a0 - buffer
    addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $ra, 20($sp)

    move $s0, $a0           # matrix_address
    lw $s1, num_rows        # num_rows
    lw $s2, num_columns     # num_columns
    li $s3, 0               # counter
    li $s4, 4               # sizeof(int)

    pmi_loop:
        # last_pos = num_rows * num_columns
        mul $t0, $s1, $s2       
        beq $s3, $t0, pmi_end   # if (counter == last_pos) return

        lw $t0, 0($s0)           # matrix_address[counter]
        # print int
        li $v0, 1
        move $a0, $t0
        syscall

        addi $t0, $s3, 1            # counter_tmp = counter + 1 
        div $t0, $s2               # added 1 to the mod calculate correctly
        mfhi $t1                    # (counter + 1) % num_columns
        li $t2, 0
        beq $t1, $t2, pmi_print_bl  # if ((counter + 1) % num_columns == 0) print_bl
        
        # else print_space 
        pmi_print_space:
        li $v0, 4
        la $a0, space
        syscall

        add $s0, $s0, $s4        # matrix_address += sizeof(int)    
        addi $s3, $s3, 1        # counter++
        j pmi_loop

        pmi_print_bl:
        li $v0, 4
        la $a0, bl
        syscall

        add $s0, $s0, $s4        # matrix_address++    
        addi $s3, $s3, 1        # counter++
        j pmi_loop

    pmi_end:
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra
# return: 

