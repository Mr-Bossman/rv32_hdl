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
		output perr);
	reg sram_sel;
	reg sram_enable;
	reg [DATA_WIDTH-1:0]sram_data;
	reg sram_ready;
	wire sram_perr;

	reg uart_sel;
	reg uart_enable;
	reg [DATA_WIDTH-1:0]uart_data;
	reg uart_ready;
	wire uart_perr;

	assign perr = sram_perr | uart_perr;

  sram ram(pclk,paddr,pdata,sram_data,sram_sel,sram_enable,pwrite,pstb,sram_ready,sram_perr);
	uart console(pclk,paddr,pdata,uart_data,uart_sel,uart_enable,pwrite,pstb,uart_ready,uart_perr);

	always_comb begin
		if(paddr != 'h0x400) begin
			uart_sel = 0;
			uart_enable = 0;
			sram_sel = psel;
			sram_enable = penable;
			pready = sram_ready;
			prdata = sram_data;
		end else begin
			uart_sel = psel;
			uart_enable = penable;
			pready = uart_ready;
			prdata = uart_data;
			sram_sel = 0;
			sram_enable = 0;
		end
	end
endmodule
