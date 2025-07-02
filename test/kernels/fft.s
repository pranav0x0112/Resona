ft_8point_p.s
# 8-point radix-2 FFT with P-extensions
# Input:
#   a0 = pointer to real input (length 8)
#   a1 = pointer to imaginary input (length 8, usually zeros)
#   a2 = pointer to real output (length 8)
#   a3 = pointer to imaginary output (length 8)
# Output:
#   Results stored in memory at a2 (real) and a3 (imaginary)

.section .data
# Pre-computed twiddle factors (scaled by 1000)
# W_N^k = e^(-j2πk/N) = cos(2πk/N) - j*sin(2πk/N)
cos_table:
    .word 1000    # cos(0) = 1.0
    .word 707     # cos(π/4) = 0.7071
    .word 0       # cos(π/2) = 0
    .word -707    # cos(3π/4) = -0.7071

sin_table:
    .word 0       # sin(0) = 0
    .word -707    # sin(π/4) = -0.7071
    .word -1000   # sin(π/2) = -1.0
    .word -707    # sin(3π/4) = -0.7071

.global fft_8point
.text

fft_8point:
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
    mv s0, a0    # s0 = x_real
    mv s1, a1    # s1 = x_imag
    mv s2, a2    # s2 = X_real
    mv s3, a3    # s3 = X_imag
    
    # Allocate temporary buffers on stack (64 bytes = 16 words)
    addi sp, sp, -64
    mv s4, sp          # s4 = temp_real
    addi s5, sp, 32    # s5 = temp_imag
    
    # Stage 1: Bit reversal permutation (can use shfl instruction)
    # Bit-reversed indices for n=8: 0->0, 1->4, 2->2, 3->6, 4->1, 5->5, 6->3, 7->7
    
    # Use P-extension shfl for bit reversal (where applicable)
    lw t0, 0(s0)      # t0 = x_real[0]
    .word 0x001520B3  # shfl t1, t0 (reverse bits in t0)
    sw t1, 0(s4)      # temp_real[0] = bit-reversed x_real[0]
    
    lw t0, 0(s1)      # t0 = x_imag[0]
    .word 0x001520B3  # shfl t1, t0
    sw t1, 0(s5)      # temp_imag[0] = bit-reversed x_imag[0]
    
    # Continue with explicit bit reversal for remaining elements
    # (The following is a simplified approach - in a real implementation,
    # you would use shfl more extensively)
    
    # Input 0 -> Output 0
    lw t0, 0(s0)      # t0 = x_real[0]
    lw t1, 0(s1)      # t1 = x_imag[0]
    sw t0, 0(s4)      # temp_real[0] = x_real[0]
    sw t1, 0(s5)      # temp_imag[0] = x_imag[0]
    
    # Input 1 -> Output 4
    lw t0, 4(s0)      # t0 = x_real[1]
    lw t1, 4(s1)      # t1 = x_imag[1]
    sw t0, 16(s4)     # temp_real[4] = x_real[1]
    sw t1, 16(s5)     # temp_imag[4] = x_imag[1]
    
    # Input 2 -> Output 2
    lw t0, 8(s0)      # t0 = x_real[2]
    lw t1, 8(s1)      # t1 = x_imag[2]
    sw t0, 8(s4)      # temp_real[2] = x_real[2]
    sw t1, 8(s5)      # temp_imag[2] = x_imag[2]
    
    # Input 3 -> Output 6
    lw t0, 12(s0)     # t0 = x_real[3]
    lw t1, 12(s1)     # t1 = x_imag[3]
    sw t0, 24(s4)     # temp_real[6] = x_real[3]
    sw t1, 24(s5)     # temp_imag[6] = x_imag[3]
    
    # Input 4 -> Output 1
    lw t0, 16(s0)     # t0 = x_real[4]
    lw t1, 16(s1)     # t1 = x_imag[4]
    sw t0, 4(s4)      # temp_real[1] = x_real[4]
    sw t1, 4(s5)      # temp_imag[1] = x_imag[4]
    
    # Input 5 -> Output 5
    lw t0, 20(s0)     # t0 = x_real[5]
    lw t1, 20(s1)     # t1 = x_imag[5]
    sw t0, 20(s4)     # temp_real[5] = x_real[5]
    sw t1, 20(s5)     # temp_imag[5] = x_imag[5]
    
    # Input 6 -> Output 3
    lw t0, 24(s0)     # t0 = x_real[6]
    lw t1, 24(s1)     # t1 = x_imag[6]
    sw t0, 12(s4)     # temp_real[3] = x_real[6]
    sw t1, 12(s5)     # temp_imag[3] = x_imag[6]
    
    # Input 7 -> Output 7
    lw t0, 28(s0)     # t0 = x_real[7]
    lw t1, 28(s1)     # t1 = x_imag[7]
    sw t0, 28(s4)     # temp_real[7] = x_real[7]
    sw t1, 28(s5)     # temp_imag[7] = x_imag[7]
    
    # Stage 2: Process butterfly stages
    # Each butterfly operation: X[k] = x[k] + x[k+d], X[k+d] = x[k] - x[k+d]
    
    # Process first stage butterflies (pairs 0-4, 1-5, 2-6, 3-7)

    # Butterfly 0-4 and 1-5 (can be packed together)
    lw t0, 0(s4)      # t0 = temp_real[0]
    lw t1, 16(s4)     # t1 = temp_real[4]
    lw t2, 4(s4)      # t2 = temp_real[1]
    lw t3, 20(s4)     # t3 = temp_real[5]
    
    # Pack values for P-extension operations
    slli t2, t2, 16   # shift to upper 16 bits
    or t0, t0, t2     # t0 = packed temp_real[0,1]
    
    slli t3, t3, 16   # shift to upper 16 bits
    or t1, t1, t3     # t1 = packed temp_real[4,5]
    
    .word 0x0210A0B3  # kadd16 t1, t0, t1 (packed sums)
    .word 0x0210B133  # ksub16 t2, t0, t1 (packed differences)
    
    # Unpack and store results
    andi t3, t1, 0xFFFF  # t3 = temp_real[0] + temp_real[4]
    sw t3, 0(s4)         # temp_real[0] = t3
    
    srli t3, t1, 16      # t3 = temp_real[1] + temp_real[5]
    sw t3, 4(s4)         # temp_real[1] = t3
    
    andi t3, t2, 0xFFFF  # t3 = temp_real[0] - temp_real[4]
    sw t3, 16(s4)        # temp_real[4] = t3
    
    srli t3, t2, 16      # t3 = temp_real[1] - temp_real[5]
    sw t3, 20(s4)        # temp_real[5] = t3
    
    lw t0, 0(s5)      # t0 = temp_imag[0]
    lw t1, 16(s5)     # t1 = temp_imag[4]
    lw t2, 4(s5)      # t2 = temp_imag[1]
    lw t3, 20(s5)     # t3 = temp_imag[5]
    
    slli t2, t2, 16   # shift to upper 16 bits
    or t0, t0, t2     # t0 = packed temp_imag[0,1]
    
    slli t3, t3, 16   # shift to upper 16 bits
    or t1, t1, t3     # t1 = packed temp_imag[4,5]
    
    .word 0x0210A0B3  # kadd16 t1, t0, t1 (packed sums)
    .word 0x0210B133  # ksub16 t2, t0, t1 (packed differences)
    
    # Unpack and store results
    andi t3, t1, 0xFFFF  # t3 = temp_imag[0] + temp_imag[4]
    sw t3, 0(s5)         # temp_imag[0] = t3
    
    srli t3, t1, 16      # t3 = temp_imag[1] + temp_imag[5]
    sw t3, 4(s5)         # temp_imag[1] = t3
    
    andi t3, t2, 0xFFFF  # t3 = temp_imag[0] - temp_imag[4]
    sw t3, 16(s5)        # temp_imag[4] = t3
    
    srli t3, t2, 16      # t3 = temp_imag[1] - temp_imag[5]
    sw t3, 20(s5)        # temp_imag[5] = t3
    
    # Butterfly 2-6 and 3-7 (similar pattern)
    lw t0, 8(s4)      # t0 = temp_real[2]
    lw t1, 24(s4)     # t1 = temp_real[6]
    lw t2, 12(s4)     # t2 = temp_real[3]
    lw t3, 28(s4)     # t3 = temp_real[7]
    
    slli t2, t2, 16   # shift to upper 16 bits
    or t0, t0, t2     # t0 = packed temp_real[2,3]
    
    slli t3, t3, 16   # shift to upper 16 bits
    or t1, t1, t3     # t1 = packed temp_real[6,7]
    
    .word 0x0210A0B3  # kadd16 t1, t0, t1 (packed sums)
    .word 0x0210B133  # ksub16 t2, t0, t1 (packed differences)
    
    # Unpack and store results
    andi t3, t1, 0xFFFF  # t3 = temp_real[2] + temp_real[6]
    sw t3, 8(s4)         # temp_real[2] = t3
    
    srli t3, t1, 16      # t3 = temp_real[3] + temp_real[7]
    sw t3, 12(s4)        # temp_real[3] = t3
    
    andi t3, t2, 0xFFFF  # t3 = temp_real[2] - temp_real[6]
    sw t3, 24(s4)        # temp_real[6] = t3
    
    srli t3, t2, 16      # t3 = temp_real[3] - temp_real[7]
    sw t3, 28(s4)        # temp_real[7] = t3
    
    lw t0, 8(s5)      # t0 = temp_imag[2]
    lw t1, 24(s5)     # t1 = temp_imag[6]
    lw t2, 12(s5)     # t2 = temp_imag[3]
    lw t3, 28(s5)     # t3 = temp_imag[7]
    
    # Pack values for P-extension operations
    slli t2, t2, 16   # shift to upper 16 bits
    or t0, t0, t2     # t0 = packed temp_imag[2,3]
    
    slli t3, t3, 16   # shift to upper 16 bits
    or t1, t1, t3     # t1 = packed temp_imag[6,7]
    
    .word 0x0210A0B3  # kadd16 t1, t0, t1 (packed sums)
    .word 0x0210B133  # ksub16 t2, t0, t1 (packed differences)
    
    # Unpack and store results
    andi t3, t1, 0xFFFF  # t3 = temp_imag[2] + temp_imag[6]
    sw t3, 8(s5)         # temp_imag[2] = t3
    
    srli t3, t1, 16      # t3 = temp_imag[3] + temp_imag[7]
    sw t3, 12(s5)        # temp_imag[3] = t3
    
    andi t3, t2, 0xFFFF  # t3 = temp_imag[2] - temp_imag[6]
    sw t3, 24(s5)        # temp_imag[6] = t3
    
    srli t3, t2, 16      # t3 = temp_imag[3] - temp_imag[7]
    sw t3, 28(s5)        # temp_imag[7] = t3
    
    # Stage 3: Second butterfly stage with twiddle factors
    # Butterfly 0-2 with W_8^0 = 1+0j (no twiddle factor multiplication)
    lw t0, 0(s4)      # t0 = temp_real[0]
    lw t1, 8(s4)      # t1 = temp_real[2]
    lw t2, 0(s5)      # t2 = temp_imag[0]
    lw t3, 8(s5)      # t3 = temp_imag[2]
    
    # Pack for P-extension operations
    slli t2, t2, 16   # shift to upper 16 bits
    or t0, t0, t2     # t0 = packed real/imag for 0
    
    slli t3, t3, 16   # shift to upper 16 bits
    or t1, t1, t3     # t1 = packed real/imag for 2
    
    .word 0x0210A0B3  # kadd16 t1, t0, t1 (packed sum)
    .word 0x0210B133  # ksub16 t2, t0, t1 (packed diff)
    
    # Unpack and store results
    andi t3, t1, 0xFFFF  # t3 = real sum
    sw t3, 0(s4)         # temp_real[0] = t3
    
    srli t3, t1, 16      # t3 = imag sum
    sw t3, 0(s5)         # temp_imag[0] = t3
    
    andi t3, t2, 0xFFFF  # t3 = real diff
    sw t3, 8(s4)         # temp_real[2] = t3
    
    srli t3, t2, 16      # t3 = imag diff
    sw t3, 8(s5)         # temp_imag[2] = t3
    
    # Butterfly 1-3 with W_8^2 = 0-1j 
    lw t0, 4(s4)      # t0 = temp_real[1]
    lw t1, 12(s4)     # t1 = temp_real[3]
    lw t2, 4(s5)      # t2 = temp_imag[1]
    lw t3, 12(s5)     # t3 = temp_imag[3]
    
    # Multiply temp[3] by W_8^2 = 0-j
    # For W_8^2 = 0-j, (a+bi)*(0-j) = b-ai
    # This means: new_real = old_imag, new_imag = -old_real
    mv t4, t1         # t4 = temp_real[3]
    mv t1, t3         # t1 = temp_imag[3] (new real)
    neg t3, t4        # t3 = -temp_real[3] (new imag)
    
    add t4, t0, t1    # t4 = temp_real[1] + new_real
    sub t5, t0, t1    # t5 = temp_real[1] - new_real
    add t6, t2, t3    # t6 = temp_imag[1] + new_imag
    sub t7, t2, t3    # t7 = temp_imag[1] - new_imag
    
    sw t4, 4(s4)      # temp_real[1] = t4
    sw t5, 12(s4)     # temp_real[3] = t5
    sw t6, 4(s5)      # temp_imag[1] = t6
    sw t7, 12(s5)     # temp_imag[3] = t7
    
    # Butterfly 4-6 with W_8^0 = 1+0j (no twiddle factor)
    lw t0, 16(s4)     # t0 = temp_real[4]
    lw t1, 24(s4)     # t1 = temp_real[6]
    lw t2, 16(s5)     # t2 = temp_imag[4]
    lw t3, 24(s5)     # t3 = temp_imag[6]
    
    # Pack for P-extension operations
    slli t2, t2, 16   # shift to upper 16 bits
    or t0, t0, t2     # t0 = packed real/imag for 4
    
    slli t3, t3, 16   # shift to upper 16 bits
    or t1, t1, t3     # t1 = packed real/imag for 6
    
    .word 0x0210A0B3  # kadd16 t1, t0, t1 (packed sum)
    .word 0x0210B133  # ksub16 t2, t0, t1 (packed diff)
    
    # Unpack and store results
    andi t3, t1, 0xFFFF  # t3 = real sum
    sw t3, 16(s4)        # temp_real[4] = t3
    
    srli t3, t1, 16      # t3 = imag sum
    sw t3, 16(s5)        # temp_imag[4] = t3
    
    andi t3, t2, 0xFFFF  # t3 = real diff
    sw t3, 24(s4)        # temp_real[6] = t3
    
    srli t3, t2, 16      # t3 = imag diff
    sw t3, 24(s5)        # temp_imag[6] = t3
    
    # Butterfly 5-7 with W_8^2 = 0-1j (complex multiply needed)
    lw t0, 20(s4)     # t0 = temp_real[5]
    lw t1, 28(s4)     # t1 = temp_real[7]
    lw t2, 20(s5)     # t2 = temp_imag[5]
    lw t3, 28(s5)     # t3 = temp_imag[7]
    
    # Multiply temp[7] by W_8^2 = 0-j
    mv t4, t1         # t4 = temp_real[7]
    mv t1, t3         # t1 = temp_imag[7] (new real)
    neg t3, t4        # t3 = -temp_real[7] (new imag)
    
    add t4, t0, t1    # t4 = temp_real[5] + new_real
    sub t5, t0, t1    # t5 = temp_real[5] - new_real
    add t6, t2, t3    # t6 = temp_imag[5] + new_imag
    sub t7, t2, t3    # t7 = temp_imag[5] - new_imag
    
    sw t4, 20(s4)     # temp_real[5] = t4
    sw t5, 28(s4)     # temp_real[7] = t5
    sw t6, 20(s5)     # temp_imag[5] = t6
    sw t7, 28(s5)     # temp_imag[7] = t7
    
    # Stage 4: Final butterfly stage
    # Load twiddle factors
    la t8, cos_table
    la t9, sin_table
    
    # Butterfly 0-1 with W_8^0 = 1+0j
    lw t0, 0(s4)      # t0 = temp_real[0]
    lw t1, 4(s4)      # t1 = temp_real[1]
    lw t2, 0(s5)      # t2 = temp_imag[0]
    lw t3, 4(s5)      # t3 = temp_imag[1]
    
    # Pack for P-extension operations
    slli t2, t2, 16   # shift to upper 16 bits
    or t0, t0, t2     # t0 = packed real/imag for 0
    
    slli t3, t3, 16   # shift to upper 16 bits
    or t1, t1, t3     # t1 = packed real/imag for 1
    
    .word 0x0210A0B3  # kadd16 t1, t0, t1 (packed sum)
    .word 0x0210B133  # ksub16 t2, t0, t1 (packed diff)
    
    # Unpack and store results
    andi t3, t1, 0xFFFF  # t3 = real sum
    sw t3, 0(s2)         # X_real[0] = t3
    
    srli t3, t1, 16      # t3 = imag sum
    sw t3, 0(s3)         # X_imag[0] = t3
    
    andi t3, t2, 0xFFFF  # t3 = real diff
    sw t3, 4(s2)         # X_real[1] = t3
    
    srli t3, t2, 16      # t3 = imag diff
    sw t3, 4(s3)         # X_imag[1] = t3
    
    # Butterfly 2-3 with W_8^1 = 0.7071-0.7071j
    lw t0, 8(s4)      # t0 = temp_real[2]
    lw t1, 12(s4)     # t1 = temp_real[3]
    lw t2, 8(s5)      # t2 = temp_imag[2]
    lw t3, 12(s5)     # t3 = temp_imag[3]
    
    # Load W_8^1 twiddle factor
    lw s6, 4(t8)      # s6 = cos(π/4) = 0.7071
    lw s7, 4(t9)      # s7 = sin(π/4) = -0.7071
    
    # Multiply temp[3] by W_8^1 using smul16
    # Pack cos/sin values
    slli s7, s7, 16   # shift to upper 16 bits
    or t4, s6, s7     # t4 = packed cos/sin
    
    # Pack real/imag values
    slli t3, t3, 16   # shift to upper 16 bits
    or t5, t1, t3     # t5 = packed real/imag for 3

    .word 0x024572B3  # smul16 t5, t4, t5
    
    # Scaling for fixed-point
    li t6, 1000
    
    andi t1, t5, 0xFFFF # t1 = new real part
    div t1, t1, t6      # scale by 1000
    
    srli t3, t5, 16    # t3 = new imag part
    div t3, t3, t6     # scale by 1000
    
    add t4, t0, t1    # t4 = temp_real[2] + new_real
    sub t5, t0, t1    # t5 = temp_real[2] - new_real
    add t6, t2, t3    # t6 = temp_imag[2] + new_imag
    sub t7, t2, t3    # t7 = temp_imag[2] - new_imag
    
    sw t4, 8(s2)      # X_real[2] = t4
    sw t5, 12(s2)     # X_real[3] = t5
    sw t6, 8(s3)      # X_imag[2] = t6
    sw t7, 12(s3)     # X_imag[3] = t7

    lw t0, 16(s4)     # t0 = temp_real[4]
    lw t1, 20(s4)     # t1 = temp_real[5]
    lw t2, 16(s5)     # t2 = temp_imag[4]
    lw t3, 20(s5)     # t3 = temp_imag[5]
    
    # Pack for P-extension operations
    slli t2, t2, 16   # shift to upper 16 bits
    or t0, t0, t2     # t0 = packed real/imag for 4
    
    slli t3, t3, 16   # shift to upper 16 bits
    or t1, t1, t3     # t1 = packed real/imag for 5
    
    .word 0x0210A0B3  # kadd16 t1, t0, t1 (packed sum)
    .word 0x0210B133  # ksub16 t2, t0, t1 (packed diff)
    
    # Unpack and store results
    andi t3, t1, 0xFFFF  # t3 = real sum
    sw t3, 16(s2)        # X_real[4] = t3
    
    srli t3, t1, 16      # t3 = imag sum
    sw t3, 16(s3)        # X_imag[4] = t3
    
    andi t3, t2, 0xFFFF  # t3 = real diff
    sw t3, 20(s2)        # X_real[5] = t3
    
    srli t3, t2, 16      # t3 = imag diff
    sw t3, 20(s3)        # X_imag[5] = t3
    
    # Butterfly 6-7 with W_8^1 = 0.7071-0.7071j
    lw t0, 24(s4)     # t0 = temp_real[6]
    lw t1, 28(s4)     # t1 = temp_real[7]
    lw t2, 24(s5)     # t2 = temp_imag[6]
    lw t3, 28(s5)     # t3 = temp_imag[7]
    
    # Load W_8^3 twiddle factor
    lw s6, 12(t8)     # s6 = cos(3π/4) = -0.7071
    lw s7, 12(t9)     # s7 = sin(3π/4) = -0.7071
    
    # Multiply temp[7] by W_8^3 using smul16
    # Pack cos/sin values
    slli s7, s7, 16   # shift to upper 16 bits
    or t4, s6, s7     # t4 = packed cos/sin
    
    # Pack real/imag values
    slli t3, t3, 16   # shift to upper 16 bits
    or t5, t1, t3     # t5 = packed real/imag for 7
    
    # Use smul16 for complex multiplication parts
    .word 0x024572B3  # smul16 t5, t4, t5
    
    # Scaling for fixed-point
    li t6, 1000
    
    andi t1, t5, 0xFFFF # t1 = new real part
    div t1, t1, t6      # scale by 1000
    
    srli t3, t5, 16    # t3 = new imag part
    div t3, t3, t6     # scale by 1000
    
    add t4, t0, t1    # t4 = temp_real[6] + new_real
    sub t5, t0, t1    # t5 = temp_real[6] - new_real
    add t6, t2, t3    # t6 = temp_imag[6] + new_imag
    sub t7, t2, t3    # t7 = temp_imag[6] - new_imag
    
    sw t4, 24(s2)     # X_real[6] = t4
    sw t5, 28(s2)     # X_real[7] = t5
    sw t6, 24(s3)     # X_imag[6] = t6
    sw t7, 28(s3)     # X_imag[7] = t7

    addi sp, sp, 64
    
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