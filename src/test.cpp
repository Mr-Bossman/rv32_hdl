#include "verilated.h"
#define CONCAT(A, B) A##B
#define CAT(A, B) CONCAT(A, B)
#define SUFF(x) CONCAT(x,_)
#define PREFIX(x) CAT(SUFF(VPREFIX),x)

#include <iostream>

int main(int argc, char **argv, char **env) {
	Verilated::commandArgs(argc, argv);
	VPREFIX* sim = new VPREFIX;


	sim->rts = 1;
	sim->eval();
	sim->rts = 0;
	for(int i = 0; i < 30000;i++){
		//printf("microop_pc 0x%0x pc: 0x%0x\n",sim->odat,sim->oldpc);
		sim->clk = 0;
		sim->eval();
		sim->clk = 1;
		sim->eval();
	}
	for(int i = 0; i < 32;i++){
		printf("regs %d: 0x%0x\n",i,sim->rootp->prog_counter__DOT__regfile[i]);
	}
		for(int i = 0; i < 32;i++){
		printf("mem 0x%02x: 0x%08lx\n",i*4,sim->rootp->prog_counter__DOT__apb_bus__DOT__ram__DOT__mem[i]);
	}
	sim->final();
	delete sim;
	return 0;
}
