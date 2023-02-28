module soc_top
	#(parameter ADDR_WIDTH = 32,
	  parameter DATA_WIDTH = 32)
	(input clk, input rts,output halted,
	output [31:0]odat,output [31:0] oldpc);

	wire [ADDR_WIDTH-1:0] APB_paddr;
	wire [DATA_WIDTH-1:0] APB_pdata;
	wire [DATA_WIDTH-1:0] APB_prdata;
	wire APB_psel;
	wire APB_penable;
	wire APB_pwrite;
	wire [3:0] APB_pstb;
	wire APB_pready;
	wire APB_perr;

	wire sram_sel;
	wire sram_enable;
	wire [DATA_WIDTH-1:0]sram_data;
	wire sram_ready;
	wire sram_perr;

	wire uart_sel;
	wire uart_enable;
	wire [DATA_WIDTH-1:0]uart_data;
	wire uart_ready;
	wire uart_perr;

	wire system_sel;
	wire system_enable;
	wire [DATA_WIDTH-1:0]system_data;
	wire system_ready;
	wire system_perr;

	cpu 	    riscv_cpu(clk,APB_paddr,APB_pdata,APB_prdata,APB_psel,APB_penable,APB_pwrite,APB_pstb,APB_pready,APB_perr,rts,halted,odat,oldpc);
	APB 	      apb_bus(clk,APB_paddr,APB_pdata,APB_prdata,APB_psel,APB_penable,APB_pwrite,APB_pstb,APB_pready,APB_perr,sram_sel,sram_enable,sram_data,sram_ready,sram_perr,uart_sel,uart_enable,uart_data,uart_ready,uart_perr,system_sel,system_enable,system_data,system_ready,system_perr);

	sram	    ram(clk,{1'b0,APB_paddr[30:0]},APB_pdata,sram_data,sram_sel,sram_enable,APB_pwrite,APB_pstb,sram_ready,sram_perr);
	sys_sram    system(clk,APB_paddr,APB_pdata,system_data,system_sel,system_enable,APB_pwrite,APB_pstb,system_ready,system_perr);

	uart	    console(clk,APB_paddr,APB_pdata,uart_data,uart_sel,uart_enable,APB_pwrite,APB_pstb,uart_ready,uart_perr);
endmodule
