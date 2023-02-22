ENTRY(start)

SECTIONS
{
	. = 0x00000000;
	.text : ALIGN(16) {
		*(.asm)
	}
	/DISCARD/ : { *(.riscv.attributes) }
}
