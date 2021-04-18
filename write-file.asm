.data
    filepath_output:	            .asciiz "/home/gohan/workspaces/assembly-workspace/foreground-detection-calculation/output.pgm"
    output_header:                  .asciiz "P2\n# output.pgm\n"
    num_rows:                       .word 6
    num_columns:                    .word 5
    maximum_valmax_length:          .word 5
    bl:                             .asciiz "\n"
    space:                          .asciiz " " 
    char:                           .asciiz 
    fourth_line:                    .asciiz "65535\n"
.text

main:
    jal create_matrix_string
    move $s0, $v0

    move $a0, $s0
    jal write_file

    li $v0, 10
    syscall

write_file:
    # args: $a0 - matrix_address, $a1 - sizeof(string)
    addi $sp, $sp, -36	# 9 register * 4 bytes = 36 bytes 
    sw  $s0, 0($sp)
    sw  $s1, 4($sp)
    sw  $s2, 8($sp)
    sw  $s3, 12($sp)
    sw  $s4, 16($sp)
    sw  $s5, 20($sp)
    sw  $s6, 24($sp)
    sw  $s7, 28($sp)
    sw  $ra, 32($sp)

    li $s0, 0               # file_description
    move $s1, $a0           # matrix_address
    lw $t0, num_rows
    lw $t1, num_columns
    mul $s2, $t0, $t1
    lw $t2, maximum_valmax_length
    mul $s2, $s2, $t2       # matrix_length
    li $s3, 0               # num_rows_str
    li $s4, 0               # num_rows_str_length
    li $s5, 0               # num_columns_str
    li $s6, 0               # num_columns_str_length
    li $s7, 0               # counter

    jal open_file_to_write
    move $s0, $v0
    
    # writing first two lines
    li $v0, 15
    move $a0, $s0
    la $a1, output_header
    la $a2, 16
    syscall

    # printing third and fourth lines

    lw $a0, num_rows 
    jal get_int_length
    move $s4, $v0
    lw $a0, num_rows 
    move $a1, $s4
    jal convert_int_to_string
    move $s3, $v0

    lw $a0, num_columns 
    jal get_int_length
    move $s6, $v0
    lw $a0, num_columns 
    move $a1, $s6
    jal convert_int_to_string
    move $s5, $v0

    # writing num_columns
    li $v0, 15
    move $a0, $s0
    move $a1, $s5
    move $a2, $s6
    syscall 
    
    # writing space
    li $v0, 15
    move $a0, $s0
    la $a1, space
    li $a2, 1
    syscall 
    
    # writing num_rows
    li $v0, 15
    move $a0, $s0
    move $a1, $s3
    move $a2, $s4
    syscall 

    # writing bl
    li $v0, 15
    move $a0, $s0
    la $a1, bl
    li $a2, 1
    syscall 

    # writing fourth_line
    li $v0, 15
    move $a0, $s0
    la $a1, fourth_line
    li $a2, 6
    syscall 


    li $s7, 0       # counter
    # writing rest of the file
    wf_loop:
        beq $s7, $s2, wf_exit   # if (counter == matrix_length) break

        add $t0, $s1, $s7       # pos = matrix_address + counter 

        li $v0, 15
        move $a0, $s0
        move $a1, $t0
        li $a2, 1
        syscall 

        addi $t0, $s7, 1                    # counter_tmp = counter + 1 (to the modulo works)
        lw $t1, num_columns
        lw $t2, maximum_valmax_length
        mul $t1, $t1, $t2
        div $t0, $t1            
        mfhi $t0                            # counter_tmp % (num_columns * maximum_valmax_length)
        li $t1, 0
        beq $t0, $t1, wf_ĺoop_print_bl      # if (counter_tmp % num_columns == 0) print_bl

        addi $t0, $s7, 1                    # counter_tmp = counter + 1 (to the modulo works)
        lw $t1, maximum_valmax_length
        div $t0, $t1            
        mfhi $t0                            # counter_tmp % maximum_valmax_length
        li $t1, 0
        beq $t0, $t1, wf_ĺoop_print_space   # if (counter_tmp % maximum_valmax_length == 0) print_space
    
        # else continue
        addi $s7, $s7, 1        # counter++
        j wf_loop

        wf_ĺoop_print_space:
        li $v0, 15
        move $a0, $s0
        la $a1, space
        li $a2, 1
        syscall 

        addi $s7, $s7, 1        # counter++

        j wf_loop

        wf_ĺoop_print_bl:
        li $v0, 15
        move $a0, $s0
        la $a1, bl
        li $a2, 1
        syscall

        addi $s7, $s7, 1        # counter++

        j wf_loop

    wf_exit:
    move $a0, $s0
    jal close_file

    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $s2, 8($sp)
    lw  $s3, 12($sp)
    lw  $s4, 16($sp)
    lw  $s5, 20($sp)
    lw  $s6, 24($sp)
    lw  $s7, 28($sp)
    lw  $ra, 32($sp)
    addi $sp, $sp, 36
    jr $ra

open_file_to_write:
    addi $sp, $sp, -4	# 1 register * 4 bytes = 4 bytes 
    sw  $ra, 0($sp)

    li   $v0, 13                    # system call for open file
    la   $a0, filepath_output       # output file name
    li   $a1, 1                     # Open for writing (flags are 0: read, 1: write)
    li   $a2, 0                     # mode is ignored
    syscall                         # open a file (file_descriptor returned in $v0)
    # move $v0, $v0                 # save the file_descriptor 

    lw  $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

close_file:
    # args: $a0 - file_descriptor
    addi $sp, $sp, -8	# 2 register * 4 bytes = 8 bytes 
    sw  $s0, 0($sp)
    sw  $ra, 4($sp)

    move $s0, $a0       # file_descritor

    # Close the file 
    li   $v0, 16                # system call for close file
    # move $a0, $a0             # file_descriptor to close
    syscall                     # close file

    lw  $s0, 0($sp)
    lw  $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

create_matrix_int:
    # args: 
    addi $sp, $sp, -28	# 5 register * 4 bytes = 20 bytes 
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

convert_int_to_string:
        # args: $a0 - value, $a1 - str length
        addi $sp, $sp, -28	# 7 register * 4 bytes = 28 bytes 
        sw  $s0, 0($sp)
        sw  $s1, 4($sp)
        sw  $s2, 8($sp)
        sw  $s3, 12($sp)
        sw  $s4, 16($sp)
        sw  $s5, 20($sp)
        sw  $ra, 24($sp)

        move $s0, $a0       # int value
        move $s4, $a1       # str_length

        # create buffer
        li $v0, 9
        move $a0, $s4       # str length 
        syscall

        move $s1, $v0       # buffer_address
        move $s2, $v0       # buffer_address_tmp
        li $s3, 0           # last_digit
        li $s5, 0           # counter

        li $s4, 0                       # str_length = 0 -> we are going to count

        cits_zero_the_buffer_loop:
            beq $s5, $s3, cits_loop     # if (counter == str_length) break

            move $a0, $s1
            li $a1, 0
            move $a2, $s5
            jal replace_char_str        # replace(buffer, val, pos) 
            addi $s5, $s5, 1            # counter++

        j cits_zero_the_buffer_loop

        cits_loop:
            li $t0, 10
            div $s0, $t0                # value / 10
            # taking off the last_digit of the value and using it to the if statement
            mflo $s0                    # value / 10 result
            mfhi $s3                    # value % 10

            move $a0, $s2               # buffer_address_tmp
            addi $t0, $s3, 48           # converting the last_digit to char
            move $a1, $t0
            li $a2, 0
            jal replace_char_str        # replace(buffer, val, pos) 

            addi $s2, $s2, 1            # buffer_address_tmp++
            addi $s4, $s4, 1            # str_length++

            li $t2, 0                   # 0
            beq $s0, $t2, cits_exit     # if ((int)(value / 10) == 0) break 

            j cits_loop

        cits_exit:
        move $a0, $s1
        move $a1, $s4
        jal invert_str
        # move $v0, $v0
        
        lw  $s0, 0($sp)
        lw  $s1, 4($sp)
        lw  $s2, 8($sp)
        lw  $s3, 12($sp)
        lw  $s4, 16($sp)
        lw  $s5, 20($sp)
        lw  $ra, 24($sp)
        addi $sp, $sp, 28
        jr $ra
        # return: $v0 - buffer_address

replace_char_str:
    # args: $a0 - buffer, $a1 - value, $a2 - pos
    addi $sp, $sp, -12	# 3 register * 4 bytes = 12 bytes 
    sw  $s0, 0($sp)
    sw  $s1, 4($sp)
    sw  $ra, 8($sp)

    move $s0, $a0       # tmp for buffer 
    li $s1, 0           # counter

    rcs_loop:
        beq $s1, $a2, rcs_replacement
        addi $s0, $s0, 1    # tmp++
        addi $s1, $s1, 1    # counter++
        j rcs_loop

    rcs_replacement:
    sb $a1, ($s0)

    rcs_exit:
    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

invert_str:
    # args: $a0 - buffer, $a1 - size
    addi $sp, $sp, -16	# 4 register * 4 bytes = 16 bytes 
    sw  $s0, 0($sp)
    sw  $s1, 4($sp)
    sw  $s2, 8($sp)
    sw  $ra, 12($sp)

    move $s0, $a0       # old_buffer_tmp 
    li $s1, 0           # new_buffer
    move $s2, $a1       # str_length / new_buffer_pos

    # create buffer
    li $v0, 9
    move $a0, $s2       # str_length 
    syscall
    move $s1, $v0       # new_buffer

    addi $s2, $s2, -1   # positions in arrays begin in 0, so we sub 1

    is_loop:
        li $t0, 0
        blt $s2, $t0, is_exit       # if (new_buffer_pos < 0) break

        move $a0, $s1               # new_buffer_address
        lb $t0, ($s0)               # old_buffer_tmp
        move $a1, $t0
        
        move $a2, $s2               # new_buffer_pos                   
        jal replace_char_str        # replace(buffer, val, pos)

        addi $s0, $s0, 1            # old_buffer_tmp++
        addi $s2, $s2, -1           # new_buffer_pos--
        j is_loop


    is_exit:
    move $v0, $s1                   # new_buffer

    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $s2, 8($sp)
    lw  $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra

    # return: $v0 - new buffer address

get_int_length:
    # args: $a0 - number
    addi $sp, $sp, -16	# 4 register * 4 bytes = 16 bytes 
    sw  $s0, 0($sp)
    sw  $s1, 4($sp)
    sw  $s2, 8($sp)
    sw  $ra, 12($sp)

    move $s0, $a0   # number
    li $s1, 1       # length
    li $s2, 10      # cur_decimal_place

    li $t0, -1
    bgt $s0, $t0, gil_loop      # if (number >= 0) continue
    mul $s0, $s0, $t0           # else

    gil_loop:
        blt $s0, $s2, gil_exit  # if (number < cur_decimal_place) break
        # else
        addi $s1, $s1, 1        # length++
        mul $s2, $s2, 10        # cur_decimal_place *= 10
        j gil_loop
    

    gil_exit:
    move $v0, $s1

    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $s2, 8($sp)
    lw  $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra
    # return: $v0 - length