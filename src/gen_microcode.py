#!/usr/bin/python3
import enum


class Micro_ops(enum.IntEnum):
	NOP = 0,
	APB_PSEL = 0x1,
	APB_PEN = 0x2,
	APB_WRITE = 0x4,
	LOAD_ISR = 0x8,
	MEM_ACCESS = 0x10,
	ALU_FLAGS = 0x20,
	LOAD_PC = 0x40,
	SYS_LOAD = 0x80,
	ALU_STORE= 0x100,


LOADINS = [Micro_ops.APB_PSEL,
	   Micro_ops.APB_PSEL | Micro_ops.APB_PEN | Micro_ops.LOAD_ISR,
	   Micro_ops.NOP]

STORE = [Micro_ops.MEM_ACCESS | Micro_ops.APB_WRITE,
	 Micro_ops.APB_PSEL | Micro_ops.MEM_ACCESS | Micro_ops.APB_WRITE,
         Micro_ops.APB_PSEL | Micro_ops.MEM_ACCESS | Micro_ops.APB_WRITE | Micro_ops.APB_PEN,Micro_ops.NOP]

LOAD = [Micro_ops.MEM_ACCESS,
	Micro_ops.APB_PSEL | Micro_ops.MEM_ACCESS,
	Micro_ops.APB_PSEL | Micro_ops.MEM_ACCESS | Micro_ops.APB_PEN,
	Micro_ops.NOP]

SYSTEM = [Micro_ops.SYS_LOAD,
	  Micro_ops.APB_PSEL | Micro_ops.SYS_LOAD,
	  Micro_ops.APB_PSEL | Micro_ops.SYS_LOAD | Micro_ops.APB_PEN,
	  Micro_ops.NOP,
	  Micro_ops.APB_PSEL | Micro_ops.SYS_LOAD | Micro_ops.APB_WRITE,
	  Micro_ops.APB_PSEL | Micro_ops.SYS_LOAD | Micro_ops.APB_PEN | Micro_ops.APB_WRITE, Micro_ops.NOP]

ALU = [Micro_ops.ALU_STORE,Micro_ops.NOP]
JALR = [Micro_ops.LOAD_PC,Micro_ops.NOP]
BRANCH = [Micro_ops.ALU_FLAGS | Micro_ops.LOAD_PC,Micro_ops.NOP]

def gen_opcodes(index, microcode):
	if(len(microcode) > 16-len(LOADINS)):
		print("Too many microcode instructions")
		return
	ofs = 1 if index == 0 else len(LOADINS)
	for i in range(16):
		if(i >= len(microcode)):
			code = 0
		else:
			#top 3 bits are the opcode index next 4 bits are the microcode index
			#last 9 bits are the microcode
			code = microcode[i] | (((i+ofs)*0x200) + (index*0x2000))
			# end jump to start
			if(i == len(microcode)-1):
				code = 0
		print("{:04x}".format(code))
	if index == 0:
		for _ in range(len(LOADINS)-1):
			print("0"*4)
def gen_microcode():
	gen_opcodes(0, LOADINS)
	gen_opcodes(1, STORE)
	gen_opcodes(2, LOAD)
	gen_opcodes(3, SYSTEM)
	gen_opcodes(4, ALU)
	gen_opcodes(5, JALR)
	gen_opcodes(6, BRANCH)
	# pad out the rest of the microcode
	# this allows for 7 opcodes
	# the last opcode is a jump to the start
	for _ in range(16-(len(LOADINS)-1)):
		print("0"*4)
	#for i in range(9):
	#	print(i*8)


gen_microcode()
