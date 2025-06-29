    .text
    .globl _start

_start:
    addi x1, x0, 5        # x1 = 5
    addi x2, x0, 10       # x2 = 10
    add x3, x1, x2        # x3 = 15
    sub x4, x2, x1        # x4 = 5
    and x5, x1, x2        # x5 = 0
    or x6, x1, x2         # x6 = 15
    xori x7, x6, 0b1010   # x7 = 15 ^ 10 = 5

    lui x8, 0x12345       # x8 = 0x12345000
    sw x7, 0(x1)          # mem[x1 + 0] = x7 = 5
    lw x9, 0(x1)          # x9 = 5

    beq x1, x4, skip      # should jump (5 == 5)
    addi x10, x0, 1       # skipped

skip:
    bne x3, x4, jump      # should jump (15 != 5)
    addi x10, x0, 2       # skipped

jump:
    jal x11, target       # jump to target

    addi x10, x0, 3       # skipped

target:
    addi x12, x0, 99      # x12 = 99
    jal x0, end           # unconditional jump (x0 discard ret addr)

    addi x13, x0, 42      

end:
    addi x0, x0, 0        