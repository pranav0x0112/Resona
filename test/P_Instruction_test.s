# all grey lines are written by me for testing purposes :)

.section .text
.global _start

_start:
  # ------------------------------------------------------------
  # Setup: x1 = [hi=1000, lo=208] = 0x03E800D0
  #        x2 = [hi=3000, lo=400] = 0x0BB80190
  li x1, 0x03E800D0
  li x2, 0x0BB80190

  # ------------------------------------------------------------
  # kadd16 x5, x1, x2
  # Expected: hi = 1000 + 3000 = 4000 = 0x0FA0
  #           lo = 208 + 400  = 608  = 0x0260
  # Final x5 = 0x0FA00260
  .word 0x0220A2B3  # kadd16 x5, x1, x2

  # ------------------------------------------------------------
  # ksub16 x6, x1, x2
  # Expected: hi = 1000 - 3000 = -2000 = 0xF830
  #           lo = 208  - 400  = -192  = 0xFF40
  # Final x6 = 0xF830FF40
  .word 0x0220B333  # ksub16 x6, x1, x2

  # ------------------------------------------------------------
  # kslra16 x7, x2, x0
  # x0 = 0, so shift amount = 0 → result = x2
  # Expect x7 = 0x0BB80190
  .word 0x0200C3B3  # kslra16 x7, x2, x0

  # ------------------------------------------------------------
  # pkbb16 x8, x1, x2
  # Takes low 2 bytes of x1: 0x00D0 → split: 0xD0, 0x00
  # Takes low 2 bytes of x2: 0x0190 → split: 0x90, 0x01
  # Lower half finna be: [x2_byte0][x1_byte0] = 0x90D0
  # Upper half finna be: [x2_byte1][x1_byte1] = 0x01 00 = 0x0100
  # Finally x8 = 0x010090D0
  .word 0x0220D433  # pkbb16 x8, x1, x2

  # ------------------------------------------------------------
  # shfl x9, x2
  # This will do bit-level interleaving (so its hard to verify manually)
  .word 0x0012A0B3  

halt:
  j halt