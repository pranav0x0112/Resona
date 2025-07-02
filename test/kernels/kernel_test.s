_kernels.s
.section .data
# Test vectors for dot product
vector_a:
    .word 1, 2, 3, 4, 5
vector_b:
    .word 5, 4, 3, 2, 1
dot_result:
    .word 0  # Will hold result

# Test matrices for matrix multiplication
matrix_a:  # 2x3 matrix
    .word 1, 2, 3
    .word 4, 5, 6
matrix_b:  # 3x2 matrix
    .word 7, 8
    .word 9, 10
    .word 11, 12
matrix_c:  # 2x2 result matrix
    .word 0, 0
    .word 0, 0

# Test data for DFT/FFT
real_input:
    .word 1, 0, 0, 0, 0, 0, 0, 0  # Impulse signal
imag_input:
    .word 0, 0, 0, 0, 0, 0, 0, 0
real_output:
    .word 0, 0, 0, 0, 0, 0, 0, 0
imag_output:
    .word 0, 0, 0, 0, 0, 0, 0, 0

# Pre-computed cosine/sine tables for DFT
# Values for cos(2πkn/8) and sin(2πkn/8), k=0..7, n=0..7
cos_table_dft:
    .word 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000  # k=0
    .word 1000, 707, 0, -707, -1000, -707, 0, 707         # k=1
    .word 1000, 0, -1000, 0, 1000, 0, -1000, 0            # k=2
    .word 1000, -707, 0, 707, -1000, 707, 0, -707         # k=3
    .word 1000, -1000, 1000, -1000, 1000, -1000, 1000, -1000 # k=4
    .word 1000, -707, 0, 707, -1000, 707, 0, -707         # k=5
    .word 1000, 0, -1000, 0, 1000, 0, -1000, 0            # k=6
    .word 1000, 707, 0, -707, -1000, -707, 0, 707         # k=7

sin_table_dft:
    .word 0, 0, 0, 0, 0, 0, 0, 0                          # k=0
    .word 0, -707, -1000, -707, 0, 707, 1000, 707         # k=1
    .word 0, -1000, 0, 1000, 0, -1000, 0, 1000            # k=2
    .word 0, -707, 1000, -707, 0, 707, -1000, 707         # k=3
    .word 0, 0, 0, 0, 0, 0, 0, 0                          # k=4
    .word 0, 707, -1000, 707, 0, -707, 1000, -707         # k=5
    .word 0, 1000, 0, -1000, 0, 1000, 0, -1000            # k=6
    .word 0, 707, 1000, 707, 0, -707, -1000, -707         # k=7

.section .text
.global _start

_start:
    # Test dot product
    la a0, vector_a
    la a1, vector_b
    li a2, 5           # Length
    jal ra, dot_product
    
    # Save result
    la t0, dot_result
    sw a0, 0(t0)
    
    # Test matrix multiplication
    la a0, matrix_a
    la a1, matrix_b
    la a2, matrix_c
    li a3, 2           # Rows in A
    li a4, 3           # Cols in A / Rows in B
    li a5, 2           # Cols in B
    jal ra, matrix_mult
    
    # Test DFT
    la a0, real_input
    la a1, imag_input
    la a2, real_output
    la a3, imag_output
    li a4, 8           # Size
    la a5, cos_table_dft
    la a6, sin_table_dft
    jal ra, dft
    
    # Reset output arrays for FFT test
    la t0, real_output
    la t1, imag_output
    li t2, 0
    li t3, 8
clear_loop:
    beq t2, t3, clear_done
    slli t4, t2, 2     # t4 = i * 4
    add t5, t0, t4     # t5 = &real_output[i]
    add t6, t1, t4     # t6 = &imag_output[i]
    sw zero, 0(t5)     # real_output[i] = 0
    sw zero, 0(t6)     # imag_output[i] = 0
    addi t2, t2, 1     # i++
    j clear_loop
clear_done:
    
    # Test FFT
    la a0, real_input
    la a1, imag_input
    la a2, real_output
    la a3, imag_output
    jal ra, fft_8point
    
    li a7, 10 
    ecall