# Matrix multiplication C = A * B using P-extensions
# Input:
#   a0 = pointer to matrix A (m×n, row-major)
#   a1 = pointer to matrix B (n×p, row-major)
#   a2 = pointer to result matrix C (m×p, row-major)
#   a3 = m (rows in A, rows in C)
#   a4 = n (cols in A, rows in B)
#   a5 = p (cols in B, cols in C)
# Output:
#   Result stored in memory at a2

.global matrix_mult
.text

matrix_mult:
    # Save registers
    addi sp, sp, -32
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    
    # Save arguments
    mv s0, a0    # s0 = A
    mv s1, a1    # s1 = B
    mv s2, a2    # s2 = C
    mv s3, a3    # s3 = m
    mv s4, a4    # s4 = n
    mv s5, a5    # s5 = p
    
    # For each row in A
    li t0, 0     # i = 0 (row counter for A and C)
    
outer_loop:
    beq t0, s3, mm_done    # if i == m, done
    
    # For each column in B
    li t1, 0     # j = 0 (column counter for B and C)
    
inner_loop:
    beq t1, s5, inner_done    # if j == p, inner loop done
    
    li t6, 0     # Initialize dot product result
    
    # For each element in row i of A and column j of B
    li t2, 0     # k = 0
    
    # Check if we can process in pairs
    srli t3, s4, 1       # t3 = n / 2 (number of pairs)
    andi t4, s4, 1       # t4 = n % 2 (odd element flag)
    
    # Process pairs of elements using P-extension
pair_loop:
    beqz t3, odd_check   # if no more pairs, check for odd element
    
    # Calculate addresses for row i of A
    mul t5, t0, s4       # t5 = i * n
    add t5, t5, t2       # t5 = i * n + k
    slli t5, t5, 2       # t5 = (i * n + k) * 4
    add t5, s0, t5       # t5 = &A[i][k]
    lw t7, 0(t5)         # t7 = packed A[i][k],A[i][k+1]
    
    # Calculate address for B[k][j]
    mul t5, t2, s5       # t5 = k * p
    add t5, t5, t1       # t5 = k * p + j
    slli t5, t5, 2       # t5 = (k * p + j) * 4
    add t5, s1, t5       # t5 = &B[k][j]
    lw t8, 0(t5)         # t8 = B[k][j]
    
    # Calculate address for B[k+1][j] correctly
    addi t9, t2, 1       # t9 = k + 1
    mul t9, t9, s5       # t9 = (k+1) * p
    add t9, t9, t1       # t9 = (k+1) * p + j
    slli t9, t9, 2       # t9 = ((k+1) * p + j) * 4
    add t9, s1, t9       # t9 = &B[k+1][j]
    lw t9, 0(t9)         # t9 = B[k+1][j]
    
    # Pack B elements into one register
    slli t9, t9, 16      # shift to upper half
    or t8, t8, t9        # t8 = packed B[k][j],B[k+1][j]
    
    # Use smul16 for packed multiplication
    .word 0x02807433     # smul16 t8, t7, t8
    
    # Extract and accumulate results (using t9, t5 as scratch)
    srai t9, t8, 16      # t9 = high product
    add t6, t6, t9       # accumulate high product
    
    andi t5, t8, 0xFFFF  # t5 = low product
    add t6, t6, t5       # accumulate low product
    
    addi t2, t2, 2       # k += 2 (processed two elements)
    addi t3, t3, -1      # decrement pair counter
    j pair_loop
    
odd_check:
    beqz t4, dot_done    # if even length, we're done
    
    # Process the last odd element
    mul t5, t0, s4       # t5 = i * n
    add t5, t5, t2       # t5 = i * n + k
    slli t5, t5, 2       # t5 = (i * n + k) * 4
    add t5, s0, t5       # t5 = &A[i][k]
    lw t7, 0(t5)         # t7 = A[i][k]
    
    mul t5, t2, s5       # t5 = k * p
    add t5, t5, t1       # t5 = k * p + j
    slli t5, t5, 2       # t5 = (k * p + j) * 4
    add t5, s1, t5       # t5 = &B[k][j]
    lw t8, 0(t5)         # t8 = B[k][j]
    
    # Use only lower 16 bits
    andi t7, t7, 0xFFFF  # mask to lower 16 bits
    andi t8, t8, 0xFFFF  # mask to lower 16 bits
    mul t9, t7, t8       # t9 = A[i][k] * B[k][j]
    add t6, t6, t9       # accumulate
    
dot_done:
    # Store result in C[i][j]
    mul t5, t0, s5       # t5 = i * p
    add t5, t5, t1       # t5 = i * p + j
    slli t5, t5, 2       # t5 = (i * p + j) * 4
    add t5, s2, t5       # t5 = &C[i][j]
    sw t6, 0(t5)         # C[i][j] = dot product result
    
    addi t1, t1, 1       # j++
    j inner_loop
    
inner_done:
    addi t0, t0, 1       # i++
    j outer_loop
    
mm_done:
    # Restore registers
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    addi sp, sp, 32
    ret