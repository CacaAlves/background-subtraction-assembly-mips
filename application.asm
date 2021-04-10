.data
	filepath:			.asciiz "/home/gohan/workspaces/assembly-workspace/foreground-detection-calculation/images.pgm"
	number_of_files:	.word 1
.text
	main:
		# number_of_files
		la $s0, number_of_files 
		lw $s0, 0($s0) 					

		# i = 1
		li $s1, 1

		# filepath
		la $s2, filepath

		main_loop:
			bgt $s1, $s0, exit # if (i > number_of_files)	
			
			li $s3, 0 		# new_file = false 

			# Setting up the filepath
			move $a0, $s2							     # Passing the filename as arg 
			jal read_image

			addi $s1, $s1, 1 # i++
			j main_loop
	
	read_image:
		addi $sp, $sp, -4	# 1 registers * 4 bytes = 4 bytes 
		sw  $ra, 0($sp)

		# Length of the current file
		li $t0, 0		   

		ri_loop:
			#open a file for writing
			li $v0, 13        # system call for open file
			la $a0, filepath
			li $a1, 0         # Open for reading
			li $a2, 0
			syscall            # open a file (file descriptor returned in $v0)
			move $t3, $v0      # save the file descriptor 	
			addi $t0, $t0, 1


			# Error treatment: is file descriptor negative ? error!
			# move $a0, $t3
			# li $v0, 1
			# syscall

			# create the buffer 
			li $v0, 9
			move $a0, $t0
			syscall
			move $t2, $v0 # buffer address

			# read from file
			li $v0, 14    	# system call for read from file
			move $a0, $t3   # file descriptor 
			move $a1, $t2   # address of buffer to which to read
			move $a2, $t0   # hardcoded buffer length
			syscall         # read from file
			move $t4, $v0   # how many bytes were read

			# Printing file
			li $v0, 4
			move $a0, $t2
			syscall

			# Printing the lenghts
			# move $t1, $v0
			# li $v0, 1
			# move $a0, $t0
			# syscall
			# li $v0, 1
			# move $a0, $t1
			# syscall

			# Close the file 
			li   $v0, 16       # system call for close file
			move $a0, $t3      # file descriptor to close
			syscall            # close file
			
			# Check whether it is EOF
			# If the length of the buffer is greater than the length of the file, it's EOF 
			bne $t0, $t4, close_file_and_return

			j ri_loop

			close_file_and_return:
				lw  $ra, 0($sp)
				addi $sp, $sp, 4

				jr $ra

	exit:
		# Telling the system that the program is over
		li $v0, 10
		syscall 
		
