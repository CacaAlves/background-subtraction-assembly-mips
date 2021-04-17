.data
	filepath:			    .asciiz "/home/gohan/workspaces/assembly-workspace/foreground-detection-calculation/images.pgm"
	matrix_pos: 			.word 0
	last_c:				    .word 1  # use to know check when there is more than one consecutive whitespace
	# last_c: 0 = whitespace, 1 = number, 2 = letter
    matrix_size:			.word 1:2 # index 0 = x, index 1 = y
    file_descriptor:        .word 
    decimal_place_counter:  .word 1
.text
	main:
        matrix_setup:
		# matrix address
		li $s0, 0

        jal open_file

        ri_loop:
            jal read_image

            #pass args x and y
            jal create_matrix
            #returns the matrix

        j ri_loop

        move $a0, $s1     # file description 
        jal close_file

        calculation:

        write_output:

    open_file:
        addi $sp, $sp, -4	# 1 register * 4 bytes = 4 bytes 
		sw  $ra, 0($sp)

        # open a file for reading
        li $v0, 13        # system call for open file
		la $a0, filepath
		li $a1, 0         # Open for reading
		li $a2, 0
		syscall            # open a file (file descriptor returned in $v0)

        sw $v0, file_descriptor

        lw  $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra

    close_file:
        addi $sp, $sp, -4	# 1 register * 4 bytes = 4 bytes 
		sw  $ra, 0($sp)

        # Close the file 
		li   $v0, 16                # system call for close file
		lw $a0, file_descriptor     # file descriptor to close
		syscall                     # close file

        lw  $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra

	read_image:
		addi $sp, $sp, -8	# 2 registers * 4 bytes = 8 bytes 
		sw  $s0, 0($sp)
		sw  $ra, 4($sp)

        read_args
        # case is EOF, x = -1
        # else return x and y
        la $t0, matrix_size
        beq $v0, -1, write_output   # EOF has been reached

        #pass args x and y
        jal create_matrix

        jal read_block
		
		lw  $s0, 0($sp)
		lw  $ra, 4($sp)
		addi $sp, $sp, 8
		jr $ra

    read_args:
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

        li $s0, 0                 # whitespace_counter
        li $s1, 0                 # buffer_address
        lw $s2, file_descriptor   # file_descriptor 
        li $s3, -1                # x_length
        li $s4, -1                # y_length
        li $s5, 0                 # current_reading_length : 0 = x, 1 = y      
        li $s6, 0                 # bool was_restarted
        li $s7, 0                 # last multiplied number

        # create the buffer 
		li $v0, 9
		move $a0, 1
		syscall
		move $s1, $v0   # buffer address

        ra_loop:
		    # read from file
		    li $v0, 14    	# system call for read from file
		    move $a0, $s2   # file descriptor 
		    move $a1, $s1   # address of buffer to which to read
		    move $a2, 1     # hardcoded buffer length
		    syscall         # read from file
		    move $t0, $v0   # how many bytes were read

            li $v0, -1            # return case EOF
            beq $t0, 0, ra_return # return case EOF

            # any whitespace
            beq $s1, 9, whitespace  # horizontal tab
			beq $s1, 10, increase_whitespace # line feed
			beq $s1, 11, whitespace # vertical tab
			beq $s1, 13, increase_whitespace # carriage return
			beq $s1, 32, whitespace # space	
            
            j ra_loop
            
            set_cur_reading_length_to_y:
                    li $s5, 1
                    j ra_loop
            
            increase_whitespace:
                addi $s0, $s0, 1 # increasing break line counter
            whitespace:
                # If the last char was a whitespace, ignore it because we just did it
                lw $t0, last_c
                beq $t0, 0, ra_loop

                li $t0, 0
                sw $t0, last_c

                li $t0, 1
                sw $t0, decimal_place_counter

                # if it isn't the third line, go back!
                bne $s0, 2, ra_loop

                beq $s6 , 0, deal_with_x_y_no_restart # !was_restarted
                j deal_with_x_y_with_restart
                
                deal_with_x_y_no_restart:  # count the length of x and y
                # whitespace: if x = -1 and y = -1, ignore (because cur_reading_length already are = x)
                # whitespace: if x != -1 and y = -1, set cur_reading_length = y
                # whitespace: if x != -1 and y != -1, 
                # close and open the file and set was_restarted = true
                beq $s3, -1, ra_loop # ignore
                beq $s4, -1, set_cur_reading_length_to_y # y = -1
                # else
                jal close_file
                jal open_file
                li $s6, 1
                j ra_loop
                
            deal_with_x_y_with_restart: # else : make the count and set them properly
                # if there's a whitespace after the y, return 
                # whitespace: if x = -1 and y = -1, ignore (because cur_reading_length already are = x)
                # whitespace: if x != -1 and y = -1, set cur_reading_length = y
                # whitespace: if x != -1 and y != -1, 
                
                la $t0, matrix_size
                lw $t1, 0($t0) # x
                lw $t2, 4($t0) # y

                beq $s7, 0, set_lengths     # if no number was multiplied yet, set the lengths
                beq $t1, 1, multiply_x      # if a number has been multiplied
               
                set_lengths:
                    li $t3, 1               #decimal place
                    li $t4, 1               # counter
                    sl_loop:


                        addi $t4, $t4, 1
                        beq $t4, 
                    j sl_loop

                multiply_x:

                
                multiply_y:

                j ra_loop

        ra_return:
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
            # return $v0 = x, $v1 = y; case EOF, x = -1

    get_matrix_size:
        # jal get_matrix_size # stored by the last read_image

        # create matrix
        li $v0, 9
		la $t0, matrix_size
		lw $t1, 0($t0)
		lw $t2, 4($t0)
        mul $t3, $t1, $t2 # matrix length
		move $a0, $t3
		syscall
		move $s0, $v0     # matrix address

        jal open_file
        move $s1, $v0     # file description
    create_matrix:

    is_a_letter:

	exit:
		# Telling the system that the program is over
		li $v0, 10
		syscall 
		