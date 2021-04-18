.data
    str:        .asciiz "001"
.text

main:
    # la $a0, str
    # la $a1, 3
    # jal convert_string_to_int
    # move $a0, $v0
    # li $v0, 1
    # syscall

    # create buffer
    li $v0, 9
    li $a0, 5       # str length
    syscall

    li $t0, 49
    sb $t0, 0($v0)
    li $t0, 55
    sb $t0, 1($v0)
    li $t0, 56
    sb $t0, 2($v0)
    li $t0, 57
    sb $t0, 3($v0)
    li $t0, 57
    sb $t0, 4($v0)

    move $a0, $v0
    la $a1, 5
    jal convert_string_to_int
    move $a0, $v0
    li $v0, 1
    syscall

    li $v0, 10
    syscall

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

power:
    # args: $a0 - base, $a1 - exponent
        addi $sp, $sp, -20	# 5 register * 4 bytes = 20 bytes 
        sw $s0, 0($sp)
        sw $s1, 4($sp)
        sw $s2, 8($sp)
        sw $s3, 12($sp)
        sw $ra, 16($sp)

        move $s0, $a0   # base
        move $s1, $a1   # exponent
        li $s2, 1       # result
        li $s3, 0       # counter

        beq $s1, 0, power_end # if (expoent == 0) return (result = 1)

        power_loop:
            beq $s3, $s1, power_end    # if (counter == expoent) return

            mul $s2, $s2, $s0           # result *= base

            addi $s3, $s3, 1
            j power_loop

        power_end:
        move $v0, $s2

        lw $s0, 0($sp)
        lw $s1, 4($sp)
        lw $s2, 8($sp)
        lw $s3, 12($sp)
        lw $ra, 16($sp)
        addi $sp, $sp, 20
        jr $ra
    # return: $v0 - result