.data

.text

main:
    li $a0, 103
    li $a1, 5   # the max maxval length 
    jal convert_int_to_string
    move $s0, $v0
    
    # printing the resulting str
    li $v0, 4
    move $a0, $s0
    # syscall

    li $v0, 10
    syscall
    

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
        
