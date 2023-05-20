mp3test.s:
.align 4
.section .text
.globl _start

_start:
    lw x8, good # X8 <= 0x600d600d
    lw x8, good # X8 <= 0x600d600d

halt: # Infinite loop to keep the processor
    beq x0, x0, halt # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.



bad: .word 0xdeadbeef
threshold: .word 0x00000040
result: .word 0x00000000
good: .word 0x600d600d
shift: .word 0x00000001