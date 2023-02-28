/* verilator lint_off UNUSEDSIGNAL */

module sys_sram
	#(parameter ADDR_WIDTH = 32,
		parameter DATA_WIDTH = 32,
		parameter RAM_SIZE = 'hfff)
	(
		input pclk,
		input [ADDR_WIDTH-1:0] paddr,
		input [DATA_WIDTH-1:0] pdata,
		output reg [DATA_WIDTH-1:0] prdata,

		input psel,
		input penable,
		input pwrite,
		input [3:0] pstb,
		output pready,
		output perr);

integer i;
reg [ADDR_WIDTH-1:0] addr;
reg ready;
reg [DATA_WIDTH-1:0] mem[0:RAM_SIZE-1];

assign prdata = mem[{2'b0, addr[ADDR_WIDTH-1:2]}];


assign pready = ready;
assign perr = 0;
always @(posedge pclk) begin: write_process
	if(psel && penable  && !ready) begin
		if (pwrite) begin
			for( i = 0; i < (ADDR_WIDTH/8);i = i + 1) begin
				if(pstb[i])
					mem[{2'b0,paddr[ADDR_WIDTH-1:2]}][8*i+:8] <= pdata[8*i+:8];
			end
		end else addr <= paddr;
		ready <= 1;
	end
	else ready <= 0;
end
endmodule
