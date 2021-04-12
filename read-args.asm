    .data
        filepath:			    .asciiz "/home/gohan/workspaces/assembly-workspace/foreground-detection-calculation/images.pgm"
        num_rows:               .word 1
        num_columns:            .word 1
    .text

    main:
        jal read_args

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
        syscall            # open a file (file descriptor returned in $v0)

        lw  $ra, 0($sp)
        addi $sp, $sp, 4

        # move $v0, $v0

        jr $ra
        # return file_descriptor

    read_args:
        addi $sp, $sp, -28	# 7 register * 4 bytes = 28 bytes 
        sw  $s0, 0($sp)    
        sw  $s1, 4($sp)    
        sw  $s2, 8($sp)    
        sw  $s3, 12($sp)    
        sw  $s4, 16($sp)    
        sw  $s5, 20($sp)    
        sw  $ra, 24($sp)

        li $s0, 1          # rows_counter
        li $s1, 1          # columns_counter
        li $s2, 0          # buffer_address
        li $s3, 0          # file_descriptor
        li $s4, 0          # buffer_address_loaded_as_a_word
        li $s5, 0          # last_char : 0 - no-a-whitespace, 1 - whitespace

        jal open_file
        move $s3, $v0      # file_descriptor

        # create the buffer 
        li $v0, 9
        li $a0, 1
        syscall
        move $s2, $v0   # buffer address
        
        ra_loop:

            # read from file
            li $v0, 14    	# system call for read from file
            move $a0, $s3   # file descriptor 
            move $a1, $s2   # address of buffer to which to read
            li $a2, 1       # hardcoded buffer length
            syscall         # read from file
            move $t0, $v0   # how many bytes were read
            
            li $v0, -1              # return case EOF
            beq $t0, 0, ra_return   # return case EOF

            lw $t0, 0($s2)
            move $a0, $t0
            jal is_not_a_number
            beq $v0, 1, ra_EOF      # if the char just read is a letter, branch

            lw $t0, 0($s2)
            move $a0, $t0
            jal handle_whitespace_if_any
            # 0 = not_white_space, 1 = space_or_tab, 2 = bl
            beq $v0, 0, ra_loop    # continue
            beq $v0, 2, increase_num_rows       # increase_num_rows
            bne $s0, 4, ra_loop                 # only increase col if the pointer is in the 4 line
            beq $v0, 1, increase_num_columns    # increase_num_columns

            increase_num_columns:
            addi $s1, $s1, 1
            j ra_loop

            increase_num_rows:
            lw $t0, num_rows
            addi $s0, $s0, 1
            j ra_loop

            ra_EOF:
            # last_char = 0
            li $s5, 0   
            # if there's a letter after the 4º line, the program is re-reading the header
            bgt $s0, 4, ra_return 
            # else
            j ra_loop

        ra_return:
        # subi $s0, $s0, 4     # subtracting 4 for the 4 first lines

        sw $s0, num_rows
        sw $s1, num_columns

        move $s2, $a0
        jal close_file

        # Printing num_rows and num_columns
        li $v0, 1
        move $a0, $s0
        syscall
        li $v0, 4
        la $a0, filepath
        syscall
        li $v0, 1
        move $a0, $s1
        syscall

        lw  $s0, 0($sp)
        lw  $s1, 4($sp)
        lw  $s2, 8($sp)
        lw  $s3, 12($sp)
        lw  $s4, 16($sp)
        lw  $s5, 20($sp)
        lw  $ra, 24($sp)
        addi $sp, $sp, 28
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
        li $s5, 0    # else last_char = 0
        j hwif_exit
        is_space_or_tab:
        beq $s5, 1, hwif_exit   # if last_char was a whitespace, do not count again!
        li $s5, 1               # last_char = 1
        li $s0, 1
        j hwif_exit
        is_bl:
        li $s0, 2
        li $s5, 1               # last_char = 1
        j hwif_exit
        hwif_exit:
        # move $a0, $s0
        # li $v0, 1
        # syscall
        move $v0, $s0
        lw  $s0, 0($sp)
        lw  $ra, 4($sp)
        addi $sp, $sp, 8
        jr $ra

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
    
    is_not_a_number:
        # args: $a0 - buffer
       addi $sp, $sp, -8	# 2 register * 4 bytes = 8 bytes 
        sw  $s0, 0($sp)
        sw  $ra, 4($sp)

        li $s0, 1           # is_not_a_number

        inan_first_check:
        li $t0, 48
        blt $a0, $t0, indeed_not_a_number	# if $a0 < $48 then indeed_not_a_number
        
        inan_second_check:
        li $t0, 57
        # li $v0, 1
        # # move $a0, $a0
        # syscall
        bgt $a0, $t0, indeed_not_a_number	# if $a0 > $57 then indeed_not_a_number

        j inan_return

        indeed_not_a_number:
        li $s0, 0
        
        inan_return:
        move $v0, $s0
        lw  $s0, 0($sp)
        lw  $ra, 4($sp)
        addi $sp, $sp, 8
        jr $ra
        # returns true or false