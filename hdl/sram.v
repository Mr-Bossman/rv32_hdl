/* verilator lint_off UNUSEDSIGNAL */

module sram
	#(parameter ADDR_WIDTH = 32,
		parameter DATA_WIDTH = 32,
		parameter RAM_SIZE = 1000000)
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
initial begin
	$readmemh("test.vh", mem);
end
always_comb begin: read_process


	unique case(addr[1:0])
		2'b00: prdata = mem[{2'b0, addr[ADDR_WIDTH-1:2]}];
		2'b01: begin
			prdata[23:0] = mem[{2'b0, addr[ADDR_WIDTH-1:2]}][31:8];
			prdata[31:24] = mem[{2'b0, addr[ADDR_WIDTH-1:2]} + 1][7:0];
		end
		2'b10: begin
			prdata[15:0] = mem[{2'b0, addr[ADDR_WIDTH-1:2]}][31:16];
			prdata[31:16] = mem[{2'b0, addr[ADDR_WIDTH-1:2]} + 1][15:0];
		end
		2'b11: begin
			prdata[7:0] = mem[{2'b0, addr[ADDR_WIDTH-1:2]}][31:24];
			prdata[31:8] = mem[{2'b0, addr[ADDR_WIDTH-1:2]} + 1][23:0];
		end
	endcase
end

assign pready = ready;
assign perr = (paddr[1] | paddr[0]) & pwrite;
always @(posedge pclk) begin: write_process
	if(psel && penable  && !ready) begin
		if (pwrite) begin
			for( i = 0; i <= (ADDR_WIDTH/8)-1;i = i + 1) begin
				if(pstb[i])
					mem[{2'b0,paddr[ADDR_WIDTH-1:2]}][8*i+:8] <= pdata[8*i+:8];
			end
		end else addr <= paddr;
		ready <= 1;
	end
	else ready <= 0;
end
endmodule
