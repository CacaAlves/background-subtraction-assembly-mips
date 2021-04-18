.data
    num_rows:               .word 4
    num_columns:            .word 3
    maximum_valmax_length:  .word 5
    bl:                     .asciiz "\n"
    space:                  .asciiz " " 
    char:                   .asciiz 
.text

main:
    jal create_matrix_string 

    move $a0, $v0
    jal matrix_string_to_matrix_int
    move $s0, $v0

    move $a0, $s0
    jal print_matrix_int

    li $v0, 10
    syscall

matrix_string_to_matrix_int:
    # args: $a0 - matrix_string_address
    addi $sp, $sp, -20	# 5 register * 4 bytes = 20 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $ra, 16($sp)

    move $s0, $a0           # matrix_string_address
    jal create_matrix_int
    move $s1, $v0           # matrix_int_address
    lw $t0, num_rows
    lw $t1, num_columns
    mul $s2, $t0, $t1       # matrix_length
    li $s3, 0               # counter

    mstmi_loop:
        beq $s3, $s2, mstmi_exit    # if (counter == matrix_length) break
        bgt $s3, $s2, mstmi_exit    # if (counter > matrix_length) break

        # pos_matrix_string = matrix_string_address + (counter * sizeof(string)) 
        lw $t0, maximum_valmax_length
        mul $t1, $s3, $t0
        add $t1, $t1, $s0           

        move $a0, $t1               # pos_matrix_string
        lw $a1, maximum_valmax_length
        jal convert_string_to_int
        move $t0, $v0               # converted_value

        # pos_matrix_int = matrix_int_address + (counter * sizeof(int)) 
        li $t1, 4                   # sizeof(int)
        mul $t2, $s3, $t1
        add $t2, $t2, $s1

        sw $t0, ($t2)               # matrix_int[counter] = matrix_string[counter]  

        addi $s3, $s3, 1            # counter++

        j mstmi_loop


    mstmi_exit:
    move $v0, $s1

    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra
    # return: $v0 - matrix_int_address

create_matrix_int:
    # args: 
    addi $sp, $sp, -20	# 5 register * 4 bytes = 20 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $ra, 16($sp)

    li $s0, 0           # matrix_int_address
    li $s1, 0           # matrix_int_address_tmp
    li $s2, 0           # matrix_length
    li $s3, 0           # counter

    
    lw $t0, num_rows
    lw $t1, num_columns

    mul $s2, $t0, $t1   # matrix_length = num_rows * num_columns

    # matrix_int_size = num_rows * num_columns * size(int)
    mul $t2, $t0, $t1
    li $t3, 4           # sizeof(int)
    mul $t2, $t2, $t3

    # create matrix_int buffer
    li $v0, 9
    move $a0, $t2         # matrix_int_size 
    syscall 
    move $s0, $v0

    move $s1, $s0       # matrix_int_address_tmp = matrix_int_address
    li $s3, 0           # counter = 0
    # set matrix_int all to 0s
    cm_int_loop:
        beq $s3, $s2, cm_int_exit       # if (counter == matrix_length) break

        li $t0, 0
        sw $t0, ($s1)               # matrix_int[counter] = 0

        addi $s1, $s1, 4            # matrix_int++
        addi $s3, $s3, 1            # counter++

        j cm_int_loop


    cm_int_exit:
    # return matrix_int_address
    move $v0, $s0
    
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra
    # return: $v0 - matrix_int_address

create_matrix_string:
    # args: 
    addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $ra, 20($sp)

    li $s0, 0                       # matrix_string_address
    lw $s1, maximum_valmax_length   # matrix_string_unit_size 
    li $s2, 0                       # matrix_string_address_tmp
    li $s3, 0                       # matrix_length
    li $s4, 0                       # counter
    
    lw $t0, num_rows
    lw $t1, num_columns

    mul $s3, $t0, $t1   # matrix_length = num_rows * num_columns * sizeof(string)
    mul $s3, $s3, 5

    # matrix_string_size = num_rows * num_columns * matrix_string_unit_size
    mul $t2, $t0, $t1   
    mul $t2, $t2, $s1

    # create matrix_string buffer
    li $v0, 9
    move $a0, $t2         # matrix_string_size 
    syscall 
    move $s0, $v0

    move $s2, $s0       # matrix_int_address_tmp = matrix_int_address
    li $s4, 0           # counter = 0
    # set matrix_string all to 0s
    cm_string_loop:
        beq $s4, $s3, cm_string_exit    # if (counter == matrix_length) break  

        li $t0, 0
        sb $t0, ($s2)                   # matrix_string[counter] = 0

        addi $s2, $s2, 1                # matrix_string++
        addi $s4, $s4, 1                # counter++

        j cm_string_loop
    
    cm_string_exit:
    move $v0, $s0
    
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra
    # return: $v0 - matrix_string_address

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

print_matrix_string_int:
        # args: $a0 - buffer, $a1 - num_rows, $a2 - num_columns
        addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
        sw $s0, 0($sp)
        sw $s1, 4($sp)
        sw $s2, 8($sp)
        sw $s3, 12($sp)
        sw $s4, 16($sp)
        sw $ra, 20($sp)

        move $s0, $a0           # matrix_address
        move $s1, $a1           # num_rows
        move $s2, $a2           # num_columns
        li $s3, 0               # counter
        li $s4, 1               # sizeof(char)

        pmsi_loop:
            # last_pos = num_rows * num_columns
            mul $t0, $s1, $s2       
            beq $s3, $t0, pmsi_end   # if (counter == last_pos) return

            lb $t0, 0($s0)           # matrix_address[counter]
            # print int
            li $v0, 1
            move $a0, $t0
            syscall

            addi $t0, $s3, 1            # counter_tmp = counter + 1 
            div $t0, $s2                # added 1 to the mod calculate correctly
            mfhi $t1                    # (counter + 1) % num_columns
            li $t2, 0
            beq $t1, $t2, pmsi_print_bl  # if ((counter + 1) % num_columns == 0) print_bl
            
            # else print_space 
            pmsi_print_space:
            li $v0, 4
            la $a0, space
            syscall

            add $s0, $s0, $s4       # matrix_address += sizeof(int)    
            addi $s3, $s3, 1        # counter++
            j pmsi_loop

            pmsi_print_bl:
            li $v0, 4
            la $a0, bl
            syscall

            add $s0, $s0, $s4       # matrix_address++    
            addi $s3, $s3, 1        # counter++
            j pmsi_loop

        pmsi_end:
        lw $s0, 0($sp)
        lw $s1, 4($sp)
        lw $s2, 8($sp)
        lw $s3, 12($sp)
        lw $s4, 16($sp)
        lw $ra, 20($sp)
        addi $sp, $sp, 24
        jr $ra
    # return: 

print_matrix_string_ascii:
    # args: $a0 - buffer, $a1 - sizeof(string)
    addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $ra, 20($sp)

    move $s0, $a0           # matrix_address
    lw $s1, num_rows        # num_rows = num_rows
    lw $t0, num_columns     
    mul $s2, $t0, $a1       # num_columns = num_columns
    li $s3, 0               # counter
    move $s4, $a1           # sizeof(string)

    pmsa_loop:
        mul $t0, $s1, $s2           # last_pos = num_rows * num_columns   
        beq $s3, $t0, pmsa_end      # if (counter == last_pos) return
        lb $t0, 0($s0)              # matrix_address[counter]
        la $t1, char
        sb $t0, ($t1)
        # print char
        li $v0, 4
        la $a0, char
        syscall
        
        addi $t0, $s3, 1                # counter_tmp = counter + 1 
        div $t0, $s2                    # added 1 to the mod calculate correctly
        mfhi $t1                        # (counter + 1) % num_columns
        li $t2, 0
        beq $t1, $t2, pmsa_print_bl     # if ((counter + 1) % num_columns == 0) print_bl

        addi $t0, $s3, 1                # counter_tmp = counter + 1 
        div $t0, $s4 
        mfhi $t1                        # (counter + 1) % sizeof(string)
        li $t2, 0
        beq $t1, $t2, pmsa_print_space  # if ((counter + 1) % sizeof(string) == 0) print_space
        
        j pmsa_increment # else continue 
        
        pmsa_print_space:
        li $v0, 4
        la $a0, space
        syscall
        j pmsa_increment
        pmsa_print_bl:
        li $v0, 4
        la $a0, bl
        syscall
        j pmsa_increment

        pmsa_increment:
        addi $s0, $s0, 1        # matrix_address++    
        addi $s3, $s3, 1        # counter++
        j pmsa_loop

    pmsa_end:
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra
    # return: 

convert_string_to_int:
    # args: $a0 - buffer, $a1 - str length
    addi $sp, $sp, -28	# 7 register * 4 bytes = 28 bytes 
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $s5, 20($sp)
    sw $ra, 24($sp)

    move $s0, $a0       # buffer_address
    move $s1, $a1       # buffer_length
    # move $s2, $a0     # buffer_address_tmp -> not in use
    li $s3, 1           # decimal_place
    move $s4, $s1       # buffer_address_pos           
    addi $s4, $s4, -1   # subtracting 1 because the array first index is 0    
    li $s5, 0           # int value        


    sti_loop:
        blt $s4, 0, sti_exit # if (buffer_address_pos < 0) break

        add $t0, $s0, $s4    # buffer_address[pos]
        lb $t1, 0($t0)
        li $t2, 0
        beq $t1, $t2, sti_loop_increment  # if (buffer_address[pos] == 0) continue  

        addi $t1, $t1, -48  # converting char to int
        mul $t1, $t1, $s3   # num = num * decimal_place
        add $s5, $s5, $t1   # value += num

        mul $s3, $s3, 10    # decimal_place *= 10

        sti_loop_increment:
        # addi $s2, $s2, 1    # buffer_address_tmp++
        addi $s4, $s4, -1   # buffer_address_pos--

        j sti_loop

    sti_exit:
    move $v0, $s5
    
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $ra, 24($sp)
    addi $sp, $sp, 28
    jr $ra
    # return: $v0 - buffer_address
