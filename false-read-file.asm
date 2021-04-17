    .data
        filepath:			    .asciiz "/home/gohan/workspaces/assembly-workspace/foreground-detection-calculation/images.pgm"
        num_rows:               .word 7
        num_columns:            .word 24
        last_char:              .word 0
        num_files:              .word 0
        maximum_valmax_length:  .word 5
        bl:                     .asciiz "\n"
        space:                  .asciiz " " 
        char:                   .asciiz 

.text

    main:
        jal create_matrix_string
        move $s0, $v0

        move $a0, $s0
        jal read_next_file

        move $a0, $s0
        li $a1, 5
        # jal print_matrix_string_ascii

        # args: $a0 - buffer, $a1 - num_rows, $a2 - num_columns
        move $a0, $s0
        li $a1, 7
        li $a2, 120 
        jal print_matrix_string_int


        main_exit:
        li $v0, 10
        syscall

    open_file:
        addi $sp, $sp, -4	# 1 register * 4 bytes = 4 bytes 
        sw  $ra, 0($sp)

        # open a file for reading
        li $v0, 13        # system call for open file
        la $a0, filepath
        li $a1, 0         # Open for reading
        li $a2, 0
        syscall           # open a file (file descriptor returned in $v0)

        lw  $ra, 0($sp)
        addi $sp, $sp, 4

        # move $v0, $v0

        jr $ra
        # return file_descriptor

    read_next_file:
        # args: $a0 - matrix_string_address
        addi $sp, $sp, -28	# 9 register * 4 bytes = 36 bytes 
        sw  $s0, 0($sp)    
        sw  $s1, 4($sp)    
        sw  $s2, 8($sp)    
        sw  $s3, 12($sp)    
        sw  $s4, 16($sp)    
        sw  $s5, 20($sp)    
        sw  $s6, 24($sp)    
        sw  $s7, 28($sp)    
        sw  $ra, 32($sp)

        li $s0, 1          # rows_counter
        li $s1, 1          # columns_counter
        li $s2, 0          # buffer_address
        li $s3, 0          # file_descriptor
        lw $s4, last_char  # last_char : 0 - no-a-whitespace, 1 - whitespace
        move $s5, $a0      # matrix_string_address
        li $s6, 0          # string_pos
        # move $s7, $a1    # not_in_use

        jal open_file
        move $s3, $v0      # file_descriptor

        # create the buffer 
        li $v0, 9
        li $a0, 1
        syscall
        move $s2, $v0      # buffer_address
        
        rf_loop:
            # read from file
            li $v0, 14    	# system call for read from file
            move $a0, $s3   # file descriptor 
            move $a1, $s2   # address of buffer to which to read
            li $a2, 1       # hardcoded buffer length
            syscall         # read from file
            move $t0, $v0   # how many bytes were read
            
            li $v0, -1              # return case EOF
            beq $t0, 0, rf_return   # return case EOF

            lw $s4, last_char       # old_last_char

            lb $t0, 0($s2)
            move $a0, $t0
            jal is_number_or_whitespace
            beq $v0, 0, rf_EOF      # if the char just read is a letter, branch
        
            
            lb $t0, 0($s2)
            move $a0, $t0
            jal handle_whitespace_if_any
            lw $t0, last_char           # new_last_char
            li $t1, 0
            # if (last_char == not_whitespace) ignore
            beq $t0, $t1, increasing_variables_and_writing_read_chars_rf
            beq $s4, $t0, rf_loop       # last_char whitespace repeating! Do not count again

            increasing_variables_and_writing_read_chars_rf:
            # 0 = not_white_space, 1 = space_or_tab, 2 = bl
            beq $v0, 0, read_number_rf          # read_number_rf
            beq $v0, 2, increase_num_rows_rf    # increase_num_rows_rf
            beq $v0, 1, increase_num_columns_rf # increase_num_columns_rf

            read_number_rf:
            li $t0, 5
            blt $s0, $t0, rf_loop       # if (rows_counter < 5) continue

            lb $t1, 0($s2)              # last_read_char

            # printing last_read_char
            li $v0, 1
            move $a0, $t1
            syscall

            li $v0, 4
            la $a0, space
            syscall

            add $t0, $s5, $s6           # pos = matrix_string_address + string_pos
            lb $t1, ($s2)               # last_read_char
            sb $t1, ($t0)               # matrix_string_address[pos] = last_read_char

            addi $s6, $s6, 1            # string_pos++

            j rf_loop

            increase_num_columns_rf:
            addi $s1, $s1, 1    # columns_counter++

            j increase_matrix_address_rf

            increase_num_rows_rf:
            addi $s0, $s0, 1    # rows_counter++

            j increase_matrix_address_rf

            increase_matrix_address_rf:
            addi $s5, $s5, 5    # matrix_string_address += 5

            li $s6, 0           # string_pos = 0

            j rf_loop

            rf_EOF:
            # if there's a letter after the 4º line, the program is re-reading the header
            bgt $s0, 4, rf_return 
            # else
            j rf_loop

        rf_return:        
        lw $t0, num_files
        addi $t0, $t0, 1
        sw $t0, num_files

        move $a0, $s2
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

    handle_whitespace_if_any:
    # args: $a0 - char
    addi $sp, $sp, -8	# 2 register * 4 bytes = 8 bytes 
    sw  $s0, 0($sp)
    sw  $ra, 4($sp)

    li $s0, 0   # return_value          
                                    # 0 = not_white_space, 1 = space_or_tab, 2 = bl
    beq $a0, 9, is_space_or_tab     # horizontal tab
    beq $a0, 10, is_bl              # line feed
    beq $a0, 11, is_space_or_tab    # vertical tab
    beq $a0, 13, is_bl              # carriage return
    beq $a0, 32, is_space_or_tab    # space	
    li $t0, 0                       # if not whitespace: last_char = 0
    sw $t0, last_char
    j hwif_exit
    is_space_or_tab:
    li $t0, 1               # last_char = 1
    sw $t0, last_char
    li $s0, 1
    j hwif_exit
    is_bl:
    li $s0, 2
    li $t0, 1               # last_char = 1
    sw $t0, last_char
    j hwif_exit
    hwif_exit:
    move $v0, $s0
    lw  $s0, 0($sp)
    lw  $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra
    # returns 0 = not_white_space, 1 = space_or_tab, 2 = bl

    close_file:
        # args: $a0 - file_descriptor
        addi $sp, $sp, -8	# 2 register * 4 bytes = 8 bytes 
        sw  $s0, 0($sp)
        sw  $ra, 4($sp)

        move $s0, $a0       # file_descritor

        # Close the file 
        li   $v0, 16                # system call for close file
        # move $a0, $a0             # file descriptor to close
        syscall                     # close file

        lw  $s0, 0($sp)
        lw  $ra, 4($sp)
        addi $sp, $sp, 8
        jr $ra
    
    is_number_or_whitespace:
        # args: $a0 - buffer
        addi $sp, $sp, -12	# 3 register * 4 bytes = 12 bytes 
        sw  $s0, 0($sp)
        sw  $s1, 4($sp)
        sw  $ra, 8($sp)

        li $s0, 0           # is_number_or_whitespace
        move $s1, $a0       # $a0

        # if it's a whitespace, return false
        inan_first_check:
        move $a0, $s1
        jal handle_whitespace_if_any    
        bne $v0, 0, indeed_number_or_whitespace                                      
        
        # if $a0 < 48 then is not a number
        inan_second_check:
        li $t0, 48
        blt $s1, $t0, inan_return	
        
        # if $a0 > 57 then is not a number
        inan_third_check:
        li $t0, 57
        bgt $s1, $t0, inan_return	

        # else it is a number

        indeed_number_or_whitespace:
        li $s0, 1
        
        inan_return:
        move $v0, $s0
        lw  $s0, 0($sp)
        lw  $s1, 4($sp)
        lw  $ra, 8($sp)
        addi $sp, $sp, 12
        jr $ra
        # returns true or false

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
    mul $s3, $s3, $s1

    # matrix_string_size = num_rows * num_columns * matrix_string_unit_size
    mul $t2, $t0, $t1   
    mul $t2, $t2, $s1

    # create matrix_string buffer
    li $v0, 9
    move $a0, $t2        # matrix_string_size 
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