#include "verilated.h"
#include "verilated_fst_c.h"
#define CONCAT(A, B) A##B
#define CAT(A, B) CONCAT(A, B)
#define SUFF(x) CONCAT(x,_)
#define PREFIX(x) CAT(SUFF(VPREFIX),x)

#include <iostream>
#include <signal.h>
#include <unistd.h>

static uint64_t instruction_count = 0;
static uint64_t clock_count = 0;
static VPREFIX* sim = NULL;
static VerilatedContext* contextp =  NULL;
static VerilatedFstC* tfp = NULL;

static void exit_now(int signo){
	puts("\n\n");
	for(int i = 0; i < 32;i++){
	//	printf("regs %d: 0x%0x\n",i,sim->rootp->soc_top__DOT__riscv_cpu__DOT__regfile[i]);
	}
	//for(int i = 0; i < 32;i++){
	//	printf("mem 0x%02x: 0x%08lx\n",i*4,sim->rootp->soc_top__DOT__ram__DOT__mem[i]);
//	}
	for(int i = 0; i < 4;i++){
		//printf("sys_mem 0x%02x: 0x%08lx\n",i*4,sim->rootp->soc_top__DOT__system__DOT__mem[i]);
	}
	tfp->close();
	sim->final();
	delete tfp;
	delete sim;
	delete contextp;
	printf("IPC: %lf instructions/clock\nCPI: %lf clock/instructions\n",(double)instruction_count/clock_count,(double)clock_count/instruction_count);
	exit(signo);
}

int main(int argc, char **argv, char **env) {
	signal(SIGINT, exit_now);
	Verilated::commandArgs(argc, argv);
	contextp = new VerilatedContext;
	tfp = new VerilatedFstC;
	sim = new VPREFIX;
	Verilated::traceEverOn(true);
  sim->trace(tfp, 99);  // Trace 99 levels of hierarchy (or see below)
	sim->rts = 0;
	contextp->timeInc(1);
	sim->eval();
  tfp->dump(contextp->time());
	sim->rts = 1;
	contextp->timeInc(1);
	sim->eval();
  tfp->dump(contextp->time());
	sim->rts = 0;
	uint32_t oldpc = sim->oldpc;
	while(!sim->halted){
		//printf("microop_pc 0x%0x pc: 0x%0x\n",sim->odat,sim->oldpc);
		//usleep(50000);
		sim->clk = 0;
		contextp->timeInc(1);
  	tfp->dump(contextp->time());
		sim->eval();
		sim->clk = 1;
		contextp->timeInc(1);
		sim->eval();
  	tfp->dump(contextp->time());
		if(sim->oldpc != oldpc){
			oldpc = sim->oldpc;
			instruction_count++;
			//printf("IPC: %lf instructions/clock,\tCPI: %lf clock/instructions\n",(double)instruction_count/clock_count,(double)clock_count/instruction_count);
		}
		clock_count++;
	}
	exit_now(0);
	return 0;
}
