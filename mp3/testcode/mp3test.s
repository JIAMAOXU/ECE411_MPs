# 1 "testcode/mp3test.S"
# 1 "<built-in>"
# 1 "<command-line>"
# 31 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 32 "<command-line>" 2
# 1 "testcode/mp3test.S"
mp3test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!! They are merely provided
    # in an effort to help you understand the assembly style.

    # Note that one/two/eight are data labels
    # la x1, bad
    # lb x2, 0(x1)
    # lb x2, 1(x1)
    # lb x2, 2(x1)
    # lb x2, 3(x1)

    lw x1, threshold # X1 <- 0x80
    lui x2, 2 # X2 <= 2
    andi x2,x2,2
    lui x3, 8 # X3 <= 8
    addi x4, x3, 4 # X4 <= X3 + 2

    # load test
    lh x11, good # for lh instruction
    lb x12, good # for lb instruction

    # store test
    la x13, result # load result addr to x13
    lw x14, good # load good to x14
    sh x14, 0(x13) # [Result] <= 0x600d
    lh x15, result # x15<= 0x600d
    sb x14, 0(x13) # [Result] <= 0xd
    lb x16, result # x16 <= 0xd

    # srl test
    lui x11, 8
    srli x11, x11, 1

    # sub test
    sub x17, x14,x15 # x14<= 0x600d_600d - 0x600d

    lw x11, good
    lw x12, shift

    # and test
    and x21, x11, x12

    # or test
    or x22, x11, x12
    lb x20, shift
    sll x20, x20, x20
    sll x20, x20, x20
    sll x20, x20, x20
    sll x20, x20, x20
    sll x20, x20, x20
    # jal test
    # jal x20, 1
loop1:
    slli x3, x3, 1 # X3 <= X3 << 1
    xori x5, x2, 127 # X5 <= XOR (X2, 7b'1111111)
    addi x5, x5, 1 # X5 <= X5 + 1
    addi x4, x4, 4 # X4 <= X4 + 8

    bleu x4, x1, loop1 # Branch if last result was zero or positive.

    andi x6, x3, 64 # X6 <= X3 + 64

    auipc x7, 8 # X7 <= PC + 8
    lw x8, good # X8 <= 0x600d600d
    la x10, result # X10 <= Addr[result]
    sw x8, 0(x10) # [Result] <= 0x600d600d
    lw x9, result # X9 <= [Result]
    bne x8, x9, deadend # PC <= bad if x8 != x9

halt: # Infinite loop to keep the processor
    beq x0, x0, halt # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

deadend:
    lw x8, bad # X8 <= 0xdeadbeef
deadloop:
    beq x8, x8, deadloop

.section .rodata

bad: .word 0xdeadbeef
threshold: .word 0x00000040
result: .word 0x00000000
good: .word 0x600d600d
shift: .word 0x00000001
