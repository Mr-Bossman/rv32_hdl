
/* TODO
LBU
LHU
*/
module cpu
	(input clk,
	input rts,
	output [31:0]odat,output reg [31:0] oldpc);

	reg [31:0] pc = 0;
	reg [31:0] instruction;
	reg halt = 0;

/* Regfile start*/
	wire [4:0]ra0;
	wire [4:0]ra1;
	wire [4:0]wa;
	wire [31:0]rd0;
	wire [31:0]rd1;
	reg [31:0] regfile[31:0];

	assign rd0 = ra0 == 5'b0 ? 0 : regfile[ra0];
	assign rd1 = ra1 == 5'b0 ? 0 : regfile[ra1];
/* Regfile end*/

	reg [3:0] microop_pc = 0;
	reg [7:0] microop_prog[0:15];
	reg [7:0] microop;

	wire [31:0] alu_out;

/* AHB start */
	wire APB_ready;
	wire APB_err;
	wire APB_sel = microop[0];
	wire APB_en = microop[1];
	wire APB_wr = (op == 7'b0100011);
	reg [3:0] dsize = 4'b1111;
	/* APB spec dissalows read Byte mask */
	wire [3:0] pstb = (APB_wr)?dsize:4'b1111;

	reg [31:0] data;
	wire [31:0]rd_data;
	reg [31:0] odata;
	reg [31:0] addr;
/* AHB end */
/* flags start */
	wire store_alu = microop[2];
	wire load_insr = microop[3];
	wire mem_access = microop[4];
	wire alu_flags = microop[5];
	wire load_pc = microop[6];

	wire cmp_flag;
/* flags end */
initial begin
	$readmemh("microop.vh", microop_prog);
end

	assign ra0 = instruction[19:15];
	assign ra1 = instruction[24:20];
	assign wa = instruction[11:7];
	wire [6:0] op = instruction[6:0];
	wire [2:0] sub_op = instruction[14:12];
	wire [31:0] imm_s = {{21{instruction[31]}}, instruction[30:25], instruction[11:7]};
	wire [31:0] imm_i = {{21{instruction[31]}}, instruction[30:20]};
	wire [31:0] imm_b = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
	APB apb_bus(clk,addr,data,rd_data,APB_sel,APB_en,APB_wr,pstb,APB_ready,APB_err);

/* READ byte mask start */
	integer i;
	always_comb begin
		for( i = 0; i <= (32/8)-1;i = i + 1) begin
			if(dsize[i]) odata[8*i+:8] = rd_data[8*i+:8];
			else odata[8*i+:8] = 8'b0;
		end
	end
/* READ byte mask end */

/* debug start */
/* verilator lint_off WIDTH */
	assign odat = microop;
/* verilator lint_on WIDTH */
/* debug end */
	wire ex_alu = (sub_op == 5 || op == 7'b0110011)?instruction[30]:0; // use extra ops for SRAI/SRA and non-imm(sub/add)
	// use add imm for 1100111 AKA JALR
	alu alu({ex_alu,sub_op},rd0,(instruction[5] || op == 7'b1100111)?rd1:imm_i,alu_out,cmp_flag);

	wire [31:0] imm_j = {{12{odata[31]}}, odata[19:12], odata[20], odata[30:21], 1'b0};
	wire [31:0] imm_u = {odata[31:12], 12'b0};
	always @(posedge clk or posedge rts) begin
		if(rts)
			pc <= 0;
		else if(!halt) begin
			// TODO: do trap
			if(APB_err) halt <= 1;
			if(load_insr) begin
				instruction <= odata;
				if(odata == 32'b0) halt <= 1;
				casez (odata[6:0])
					7'b0?00011: begin // LOAD/STORE
						microop_pc <= 8;
						microop <= microop_prog[8];
					end
					7'b0?10111: begin //LUI/AUIPC
						// TODO: check if pc is +4 or not
						regfile[odata[11:7]] <= imm_u + ((odata[5])?0:pc-4);
						microop <= 0;
					end
					7'b0?10011: begin // ALU
						microop <= 4;
					end
					7'b1101111: begin // JAL
						regfile[odata[11:7]] <= pc;
						pc <= pc + imm_j - 4;
						microop <= 0;
					end
					7'b1100111: begin // JALR
						regfile[odata[11:7]] <= pc;
						microop <= 8'h40;
					end
					7'b1100011: begin // BRANCH
						microop <= 8'h20;
					end
					default:microop <= 0;


				endcase
			end
			// halt till APB_ready is ready
			else if(!(APB_en && APB_sel && !APB_ready)) begin
				if(microop != 8'b0) begin
					microop_pc <= microop_pc + 1;
					microop <= microop_prog[microop_pc];
				end else begin
					instruction <= 0;
					microop_pc <= 1;
					addr <= pc;
					pc <= pc + 4;
					dsize <= 4'b1111;
					microop <= microop_prog[0];
					oldpc <= pc;
				end
			end
			if(mem_access) begin
				unique case (sub_op[1:0])
					2'b00: dsize <= 4'b0001;
					2'b01: dsize <= 4'b0011;
					2'b10: dsize <= 4'b1111;
					default: dsize <= 4'b1111;
				endcase
				addr <= (op == 7'b0100011)?imm_s:imm_i + rd0;
				data <= rd1;
				/* TODO: cast 00 and 01 as ints if sub_op[2] is 0 */
				if(APB_en && APB_sel && APB_ready && (op == 7'b0000011))
					regfile[wa] <= odata;
			end
			if(store_alu) regfile[wa] <= alu_out;
			if(alu_flags && cmp_flag) pc <= imm_b + pc - 4;
			if(load_pc) pc <= alu_out;
		end
	end

endmodule