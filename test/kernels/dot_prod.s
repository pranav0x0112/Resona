# Dot product of two vectors using P-extensions
# Input:
#   a0 = pointer to vector A
#   a1 = pointer to vector B
#   a2 = length of vectors (number of elements)
# Output:
#   a0 = result (dot product value)

.global dot_product
.text

dot_product:
    li a3, 0           # accumulated result
    li t0, 0           # loop counter i = 0
    
    # Determine number of pairs to process
    srli t1, a2, 1     # t1 = a2 / 2 (number of pairs)
    andi t2, a2, 1     # t2 = a2 % 2 (odd element flag)
    
    # Process pairs using P-extension
pair_loop:
    beqz t1, odd_check  # if no more pairs, check for odd element
    
    # Load pairs from both vectors
    slli t3, t0, 2     # t3 = i * 4 (byte offset)
    add t4, a0, t3     # t4 = &A[i]
    add t5, a1, t3     # t5 = &B[i]
    lw t4, 0(t4)       # t4 = packed A[i,i+1]
    lw t5, 0(t5)       # t5 = packed B[i,i+1]
    
    # Use smul16 for packed multiplication
    .word 0x02507433   # smul16 t8, t4, t5
    
    # Extract and accumulate results
    srai t6, t8, 16    # t6 = high product
    add a3, a3, t6     # accumulate high product
    
    andi t6, t8, 0xFFFF # t6 = low product
    add a3, a3, t6     # accumulate low product
    
    addi t0, t0, 2     # i += 2 (processed two elements)
    addi t1, t1, -1    # decrement pair counter
    j pair_loop
    
odd_check:
    beqz t2, done  
    
    # Process the last odd element
    slli t3, t0, 2     # t3 = i * 4 (byte offset)
    add t4, a0, t3     # t4 = &A[i]
    add t5, a1, t3     # t5 = &B[i]
    lw t4, 0(t4)       # t4 = A[i]
    lw t5, 0(t5)       # t5 = B[i]
    
    # Only use lower 16 bits for the last element
    andi t4, t4, 0xFFFF # mask to lower 16 bits
    andi t5, t5, 0xFFFF # mask to lower 16 bits
    mul t6, t4, t5     # t6 = A[i] * B[i]
    add a3, a3, t6     # accumulate
    
done:
    mv a0, a3          # return result
    ret