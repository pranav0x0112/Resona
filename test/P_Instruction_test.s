.section .text
.global _start

_start:
  # ---------------------------------------------
  # Setup: x1 = [hi=0x0002, lo=0x0003] = 0x00020003
  #         x2 = [hi=0x0004, lo=0x0005] = 0x00040005
  li x1, 0x00020003
  li x2, 0x00040005
  
  .word 0x40C122B3
halt:
  j halt