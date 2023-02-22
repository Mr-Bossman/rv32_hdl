/* verilator lint_off UNUSEDSIGNAL */

module uart
	#(parameter ADDR_WIDTH = 32,
		parameter DATA_WIDTH = 32)
	(
		input pclk,
		input [ADDR_WIDTH-1:0] paddr,
		input [DATA_WIDTH-1:0] pdata,
		output reg [DATA_WIDTH-1:0] prdata,

		input psel,
		input penable,
		input pwrite,
		input [3:0] pstb,
		output reg ready,
		output perr);
assign prdata = 0;
always @(posedge pclk) begin
	if(psel && penable && !ready) begin
		if (pwrite) $display("%c",pdata[7:0]);
    		else perr <= 1;
		ready <= 1;
	end
	else ready <= 0;
end
endmodule
