    addi x1, x0, 10     # x1 = 10
    addi x2, x0, 10     # x2 = 10
    addi x3, x0, 5      # x3 = 5

    beq x1, x2, 8       # Branch forward by 8 bytes (2 instructions) if x1 == x2 (yes)
    addi x3, x3, 1      # Should be skipped
    addi x3, x3, 1      # Should be skipped

    bne x1, x3, 8       # Branch forward by 8 bytes if x1 != x3 (yes)
    addi x3, x3, 1      # Should be skipped
    addi x3, x3, 1      # Should be skipped

    # Reached here
    nop