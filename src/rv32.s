.section .asm, "ax"
.global start

.align 4
start:
	lb x4, (x0)
	sw x4, 0x60(x0)
	la x10, 0x1000000
	la x6, .texts
1:
	lw x5, 0(x6)
	sw x5, 0(x10)
	addi x6,x6,1
	bne x5,x8,1b
	j start


.texts:
	.ascii "test\n";
	.byte 0x00;
	.balign 4, 0;
