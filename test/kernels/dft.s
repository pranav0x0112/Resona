# filepath: dft_p.s
# Discrete Fourier Transform using P-extensions
# Input:
#   a0 = pointer to real input (length n)
#   a1 = pointer to imaginary input (length n, usually zeros)
#   a2 = pointer to real output (length n)
#   a3 = pointer to imaginary output (length n)
#   a4 = n (length of input/output)
#   a5 = pointer to cosine table (precomputed cos values)
#   a6 = pointer to sine table (precomputed sin values)
# Output:
#   Results stored in memory at a2 (real) and a3 (imaginary)

.global dft
.text

dft:
    # Save registers
    addi sp, sp, -36
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)
    
    # Save arguments
    mv s0, a0    # s0 = x_real
    mv s1, a1    # s1 = x_imag
    mv s2, a2    # s2 = X_real
    mv s3, a3    # s3 = X_imag
    mv s4, a4    # s4 = n
    mv s5, a5    # s5 = cos_table
    mv s6, a6    # s6 = sin_table
    
    # For each output frequency k
    li s7, 0     # k = 0
    
freq_loop:
    beq s7, s4, dft_done
    
    # Initialize accumulators for real and imaginary parts
    li t0, 0     # real_sum = 0
    li t1, 0     # imag_sum = 0
    
    # Check if we can process in pairs
    srli t2, s4, 1      # t2 = n / 2 (number of pairs)
    andi t3, s4, 1      # t3 = n % 2 (odd element flag)
    li t4, 0            # t4 = m = 0 (time sample index)
    
    # Process pairs using P-extensions
pair_loop:
    beqz t2, odd_check  # if no more pairs, check for odd element
    
    # Calculate index for cos/sin tables for time m and m+1
    mul t5, s7, t4      # t5 = k * m
    rem t5, t5, s4      # t5 = (k * m) % n
    slli t5, t5, 2      # t5 = ((k * m) % n) * 4
    
    # Get cos(2π*k*m/n) and sin(2π*k*m/n)
    add t6, s5, t5      # t6 = &cos_table[(k*m) % n]
    lw t7, 0(t6)        # t7 = cos(2π*k*m/n)
    
    add t6, s6, t5      # t6 = &sin_table[(k*m) % n]
    lw t8, 0(t6)        # t8 = sin(2π*k*m/n)
    
    # Calculate index for next time sample
    addi t9, t4, 1      # t9 = m + 1
    mul t5, s7, t9      # t5 = k * (m+1)
    rem t5, t5, s4      # t5 = (k * (m+1)) % n
    slli t5, t5, 2      # t5 = ((k * (m+1)) % n) * 4
    
    # Get cos(2π*k*(m+1)/n) and sin(2π*k*(m+1)/n)
    add t6, s5, t5      # t6 = &cos_table[(k*(m+1)) % n]
    lw t9, 0(t6)        # t9 = cos(2π*k*(m+1)/n)
    
    add t6, s6, t5      # t6 = &sin_table[(k*(m+1)) % n]
    lw a7, 0(t6)        # a7 = sin(2π*k*(m+1)/n)
    
    # Pack cos/sin values
    slli t9, t9, 16     # shift to upper 16 bits
    or t7, t7, t9       # t7 = packed cos values
    
    slli a7, a7, 16     # shift to upper 16 bits
    or t8, t8, a7       # t8 = packed sin values
    
    # Get input samples for time m and m+1
    slli t5, t4, 2      # t5 = m * 4
    add t6, s0, t5      # t6 = &x_real[m]
    lw t9, 0(t6)        # t9 = x_real[m]
    
    add t6, s1, t5      # t6 = &x_imag[m]
    lw a7, 0(t6)        # a7 = x_imag[m]
    
    addi t5, t5, 4      # t5 = (m+1) * 4
    add t6, s0, t5      # t6 = &x_real[m+1]
    lw a0, 0(t6)        # a0 = x_real[m+1]
    
    add t6, s1, t5      # t6 = &x_imag[m+1]
    lw a1, 0(t6)        # a1 = x_imag[m+1]
    
    # Pack real and imaginary parts
    slli a0, a0, 16     # shift to upper 16 bits
    or t9, t9, a0       # t9 = packed real values
    
    slli a1, a1, 16     # shift to upper 16 bits
    or a7, a7, a1       # a7 = packed imag values
    
    # Complex multiplication using P-extensions
    # (a+bi) * (c+di) = (ac-bd) + (ad+bc)i
    
    # Real part: x_real*cos - x_imag*sin
    .word 0x02907733    # smul16 a4, t9, t7 (x_real * cos)
    .word 0x028377b3    # smul16 a5, a7, t8 (x_imag * sin)
    
    # Use kadd16/ksub16 for saturating addition/subtraction
    .word 0x02A0A833    # ksub16 a6, a4, a5 (real part)
    
    # Extract and accumulate results
    srai a0, a6, 16     # a0 = high product
    add t0, t0, a0      # accumulate high real
    
    andi a0, a6, 0xFFFF # a0 = low product
    add t0, t0, a0      # accumulate low real
    
    # Imaginary part: x_real*sin + x_imag*cos
    .word 0x02807733    # smul16 a4, t9, t8 (x_real * sin)
    .word 0x027377b3    # smul16 a5, a7, t7 (x_imag * cos)
    
    # Use kadd16 for saturating addition
    .word 0x02A0A833    # kadd16 a6, a4, a5 (imag part)
    
    # Extract and accumulate results
    srai a0, a6, 16     # a0 = high product
    add t1, t1, a0      # accumulate high imag
    
    andi a0, a6, 0xFFFF # a0 = low product
    add t1, t1, a0      # accumulate low imag
    
    addi t4, t4, 2      # m += 2 (processed two time samples)
    addi t2, t2, -1     # decrement pair counter
    j pair_loop
    
odd_check:
    beqz t3, store_result  # if even length, we're done
    
    # Process the last odd element
    mul t5, s7, t4      # t5 = k * m
    rem t5, t5, s4      # t5 = (k * m) % n
    slli t5, t5, 2      # t5 = ((k * m) % n) * 4
    
    # Get cos and sin values
    add t6, s5, t5      # t6 = &cos_table[(k*m) % n]
    lw t7, 0(t6)        # t7 = cos(2π*k*m/n)
    
    add t6, s6, t5      # t6 = &sin_table[(k*m) % n]
    lw t8, 0(t6)        # t8 = sin(2π*k*m/n)
    
    # Get input values
    slli t5, t4, 2      # t5 = m * 4
    add t6, s0, t5      # t6 = &x_real[m]
    lw t9, 0(t6)        # t9 = x_real[m]
    
    add t6, s1, t5      # t6 = &x_imag[m]
    lw a7, 0(t6)        # a7 = x_imag[m]
    
    # Standard complex multiplication
    mul a0, t9, t7      # a0 = x_real[m] * cos
    mul a1, a7, t8      # a1 = x_imag[m] * sin
    sub a0, a0, a1      # a0 = real part
    add t0, t0, a0      # accumulate real
    
    mul a0, t9, t8      # a0 = x_real[m] * sin
    mul a1, a7, t7      # a1 = x_imag[m] * cos
    add a0, a0, a1      # a0 = imag part
    add t1, t1, a0      # accumulate imag
    
store_result:
    # Store result for this frequency
    slli t5, s7, 2      # t5 = k * 4
    
    add t6, s2, t5      # t6 = &X_real[k]
    sw t0, 0(t6)        # X_real[k] = real_sum
    
    add t6, s3, t5      # t6 = &X_imag[k]
    sw t1, 0(t6)        # X_imag[k] = imag_sum
    
    addi s7, s7, 1      # k++
    j freq_loop
    
dft_done:
    # Restore arguments for caller
    mv a0, s0
    mv a1, s1
    mv a2, s2
    mv a3, s3
    mv a4, s4
    mv a5, s5
    mv a6, s6
    
    # Restore registers
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    lw s7, 32(sp)
    addi sp, sp, 36
    ret