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
		input uart_perr);
	reg access_fault;
	assign perr = sram_perr | uart_perr | access_fault;

	always_comb begin
		if(paddr >= 'h80000000) begin
			access_fault = 0;
			uart_sel = 0;
			uart_enable = 0;
			sram_sel = psel;
			sram_enable = penable;
			pready = sram_ready;
			prdata = sram_data;
		end else if (paddr == 'h1000000) begin
			access_fault = 0;
			uart_sel = psel;
			uart_enable = penable;
			pready = uart_ready;
			prdata = uart_data;
			sram_sel = 0;
			sram_enable = 0;
		end else begin
			access_fault = 1;
			uart_sel = 0;
			uart_enable = 0;
			sram_sel = 0;
			sram_enable = 0;
			pready = 0;
			prdata = 0;
		end
	end
endmodule
