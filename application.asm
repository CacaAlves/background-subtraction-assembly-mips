.data
	filepath:			.asciiz "/home/gohan/workspaces/assembly-workspace/project1/image-n.pgm"
	n_position:			.word 57 	# in which position the numerator is
	number_of_files:	.word 30	
.text
	main:
		# number_of_files
		la $s0, number_of_files 
		lw $s0, 0($s0) 					

		# i = 0
		li $s1, 0

		# filepath
		la $s2, filepath

		# n_position
		la $s3, n_position
		lw $s3, 0($s3)
		
		while:
			bgt $s1, $s0, exit # if (i > number_of_files)	
				# Setting up the filepath
				sw $s1, $s3($s2)    					 # filepath[n_position] = i
				lw $t0, $s3($s2) 					
				
				lw $a0, 0($s2)							 # Passing the filename as arg 
				jal read_image

			addi $s1, $s1, 1 # i++
			j while
	
	read_image:
		addi $sp, $sp, -12	# 3 registers * 4 bytes = 12 bytes 
		sw  $s0, 0($sp)
		sw  $s1, 4($sp)
		sw  $ra, 8($sp)


		#open a file for writing
		li   $v0, 13       # system call for open file
		# $ao is already with the filename
		li   $a1, 0        # Open for reading
		li   $a2, 0
		syscall            # open a file (file descriptor returned in $v0)
		move $s1, $v0      # save the file descriptor 

		# Error treatment
		# move $a0, $v0
		# li $v0, 1
		# syscall

		# create the buffer 
		li $v0, 9
		li $a0, 1
		syscall
		move $s0, $v0 # buffer address

		#read from file
		li   $v0, 14    # system call for read from file
		move $a0, $s1   # file descriptor 
		la   $a1, $s0   # address of buffer to which to read
		li   $a2, 1     # hardcoded buffer length
		syscall         # read from file

		# Printing file
		move $a0, $
		li $v0, 4
		syscall

		lw  $s0, 0($sp)
		lw  $s1, 4($sp)
		lw  $ra, 8($sp)
		addi $sp, $sp, 12	# 3 registers * 4 bytes = 12 bytes 

		jr $ra

	exit:
		# Telling the system that the program is over
		li $v0, 10
		syscall 
		
