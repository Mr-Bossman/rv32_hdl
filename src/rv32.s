.section .asm, "ax"
.global start

.align 4
start:
	la x10, 0x1000000
	la x5, call
	sw x5,0(x0)
	ebreak
	ecall
halt:
	j halt
2:
	la x6, .texts
1:
	lw x5, 0(x6)
	sw x5, 0(x10)
	addi x6,x6,1
	bne x5,x8,1b
	.word 0x00;


call:
	lw x5, 4(x0)
	addi x5,x5,8
	sw x5,0(x0)
	ecall

.texts:
	.ascii "test\n";
	.byte 0x00;
	.balign 4, 0;
