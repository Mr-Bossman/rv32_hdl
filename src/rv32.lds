ENTRY(start)

SECTIONS
{
	. = 0x80000000;
	.text : ALIGN(16) {
		*(.asm)
	}
	/DISCARD/ : { *(.riscv.attributes) }
}
