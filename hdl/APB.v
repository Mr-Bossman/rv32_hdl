/* verilator lint_off UNUSEDSIGNAL */

module APB
	#(parameter ADDR_WIDTH = 32,
		parameter DATA_WIDTH = 32)
	(
		input pclk,
		input [ADDR_WIDTH-1:0] paddr,
		input [DATA_WIDTH-1:0] pdata,
		output reg [DATA_WIDTH-1:0]  prdata,

		input psel,
		input penable,
		input pwrite,
		input [3:0] pstb,
		output reg pready,
		output perr,

		output reg sram_sel,
		output reg sram_enable,
		input [DATA_WIDTH-1:0]sram_data,
		input sram_ready,
		input sram_perr,

		output reg uart_sel,
		output reg uart_enable,
		input [DATA_WIDTH-1:0]uart_data,
		input uart_ready,
		input uart_perr,

		output reg system_sel,
		output reg system_enable,
		input [DATA_WIDTH-1:0]system_data,
		input system_ready,
		input system_perr);
	reg access_fault;
	assign perr = sram_perr | uart_perr | system_perr | access_fault;

	always_comb begin
		if(paddr >= 'h80000000) begin
			access_fault = 0;
			uart_sel = 0;
			uart_enable = 0;
			system_sel = 0;
			system_enable = 0;
			sram_sel = psel;
			sram_enable = penable;
			pready = sram_ready;
			prdata = sram_data;
		end else if (paddr == 'h1000000) begin
			access_fault = 0;
			sram_sel = 0;
			sram_enable = 0;
			system_sel = 0;
			system_enable = 0;
			uart_sel = psel;
			uart_enable = penable;
			pready = uart_ready;
			prdata = uart_data;
		end else if (paddr <= 'hfff)begin
			access_fault = 0;
			uart_sel = 0;
			uart_enable = 0;
			sram_sel = 0;
			sram_enable = 0;
			system_sel = psel;
			system_enable = penable;
			pready = system_ready;
			prdata = system_data;
		end else begin
			access_fault = 1;
			system_sel = 0;
			system_enable = 0;
			uart_sel = 0;
			uart_enable = 0;
			sram_sel = 0;
			sram_enable = 0;
			pready = 0;
			prdata = 0;
		end
	end
endmodule
