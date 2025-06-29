    addi x1, x0, 100       # x1 = 100
    addi x2, x0, 42        # x2 = 42
    sw   x2, 0(x1)         # MEM[100] = 42
    lw   x3, 0(x1)         # x3 = MEM[100]