.data
    filepath:			    .asciiz "/home/gohan/workspaces/assembly-workspace/foreground-detection-calculation/images.pgm"
    last_char:              .word 0
    num_rows:               .word 7
    num_columns:            .word 24
.text

main:
    jal read_args

    exit:
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
    # args: $a0 - matrix_string_address
    addi $sp, $sp, -24	# 6 register * 4 bytes = 24 bytes 
    sw  $s0, 0($sp)    
    sw  $s1, 4($sp)    
    sw  $s2, 8($sp)    
    sw  $s3, 12($sp)    
    sw  $s4, 16($sp)    
    sw  $ra, 20($sp)

    li $s0, 1            # rows_counter
    li $s1, 1            # columns_counter
    li $s2, 0            # buffer_address
    li $s3, 0            # file_descriptor
    lw $s4, last_char    # last_char : 0 - not-a-whitespace, 1 - whitespace

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
        beq $t0, 0, ra_exit   # return case EOF

        lw $s4, last_char       # old_last_char

        lb $t0, 0($s2)
        move $a0, $t0
        jal is_number_or_whitespace
        beq $v0, 0, ra_EOF                # if the char just read is a letter, branch
        
        lb $t0, 0($s2)
        move $a0, $t0
        jal handle_whitespace_if_any
        lw $t0, last_char                 # new_last_char
        beq $s4, $t0, ra_loop             # last_char whitespace repeating! Do not count again

        lb $t1, 0($s2)                    # last_read_char

        increasing_values_ra:
        # 0 = not_white_space, 1 = space_or_tab, 2 = bl
        beq $v0, 0, ra_loop                 # write the number just read
        beq $v0, 2, increase_num_rows_ra    # increase_num_rows_ra
        beq $v0, 1, increase_num_columns_ra # increase_num_columns_ra

        increase_num_columns_ra:
        li $t0, 5
        bne $s0, $t0, ra_loop   # if (rows_counter != 5) break 

        addi $s1, $s1, 1
        j ra_loop

        increase_num_rows_ra:
        addi $s0, $s0, 1
        j ra_loop

        increase_matrix_address_ra:
        addi $s5, $s5, 5    # matrix_string_address += 5

        li $s6, 0           # string_pos = 0

        j ra_loop

        ra_EOF:
        # if there's a letter after the 4º line, the program is re-reading the header
        bgt $s0, 4, ra_exit 
        # else
        j ra_loop

    ra_exit:
    addi $s0, $s0, -5       # subtracting 4 lines from the header and 1 from the line that is after
    sw $s0, num_rows
    sw $s1, num_columns

    move $a0, $s2
    jal close_file

    lw  $s0, 0($sp)
    lw  $s1, 4($sp)
    lw  $s2, 8($sp)
    lw  $s3, 12($sp)
    lw  $s4, 16($sp)
    lw  $ra, 20($sp)
    addi $sp, $sp, 24
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