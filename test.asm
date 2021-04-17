.data

.text
    # li $v0, 9
    # li $a0, 5           # str length 
    # syscall
    # move $s0, $v0       # str address

    # li $v0, 9
    # li $a0, 2           # str length 
    # syscall
    # move $s1, $v0       # str address

    # li $t0, 80
    # sb $t0, 0($s1)

    # move $t0, $s0

    # lb $t1, ($s1)
    # sb $t1, 0($t0)

    # li $t1, 104
    # addi $t0, $t0, 1
    # sb $t1, 0($t0)

    # li $v0, 4
    # lb $t0, 0($s1)
    # move $a0, $t0
    # syscall

    li $s0, 1
    li $t0, 10
    div $s0, $t0                # value / 10
    # taking off the last_digit of the value and using it to the if statement
    mflo $s0                    # value / 10 result
    mfhi $s3                    # value % 10
    li $t2, 0                   # 0
    beq $s0, $t2, cits_exit     # if ((int)(value / 10) == 0) break

    li $v0, 10
    syscall

    cits_exit:
    li $v0, 1
    move $a0, $s0
    syscall