module cpu
	#(parameter ADDR_WIDTH = 32,
	  parameter DATA_WIDTH = 32)
	(input clk,
	output reg [ADDR_WIDTH-1:0] APB_paddr,
	output reg [DATA_WIDTH-1:0] APB_pdata,
	input [DATA_WIDTH-1:0] APB_prdata,
	output APB_psel,
	output APB_penable,
	output APB_pwrite,
	output [3:0] APB_pstb,
	input APB_pready,
	input APB_perr,
	input interrupt,
	input rts, output halted,
	output [31:0]odat,output reg [31:0] oldpc);
	reg [31:0] pc;
	/* We dont use ra0 or ra1 */
	reg [31:0] instruction;
	reg halt = 0;
	assign halted = halt;

/* ALU start */
	wire [31:0] alu_out;
	reg [31:0] aluRB;
	reg [3:0] alu_op;
	wire cmp_flag;
/* ALU end */

/* Regfile start*/
	wire [4:0]ra0;
	wire [4:0]ra1;
	wire [4:0]wa;
	reg [31:0]rd0;
	reg [31:0]rd1;
	reg [31:0] regfile[31:0];
/* Regfile end*/

/* Microcode start */
	reg[3:0] op_jmp;
	reg [15:0] microop_prog[0:127];
	reg [15:0] microop;
	wire [6:0] microop_pc = microop[15:9];
	reg [6:0] microop_addr;
initial begin
	$readmemh("microop.mem", microop_prog);
end
/* Microcode end */

/* AHB start */
	assign APB_psel = microop[0];
	assign APB_penable = microop[1];
	wire pwrite = microop[2];
	assign APB_pwrite = (pwrite && APB_psel);
	reg [3:0] dsize;
	/* APB spec dissalows read Byte mask */
	assign APB_pstb = (APB_pwrite)?dsize:4'b1111;
	/* If we are not writing or writing this is high*/
	wire APB_Dready = !APB_penable || !APB_psel || APB_pready;
	reg [31:0] odata;
/* AHB end */

/* flags start */
	wire load_insr = microop[3];
	wire mem_access = microop[4];
	wire alu_flags = microop[5];
	wire load_pc = microop[6];
	wire sys_load = microop[7];
	wire store_alu = microop[8];
	/* These happen in the same cycle as load_insr */
/*
	wire lui_flag = (load_insr)?microop_prog[op_jmp][9]:0;
	wire jal_flag = (load_insr)?microop_prog[op_jmp][10]:0;
*/
	/* Microcode reads need to be synchronous */
	wire lui_flag = (load_insr && op_jmp == (0 | 7));
	wire jal_flag = (load_insr && op_jmp == (8 | 7));
/* flags end */

/* Instruction operands start */
	wire [31:0] imm_j = {{12{odata[31]}}, odata[19:12], odata[20], odata[30:21], 1'b0};
	wire [31:0] imm_u = {odata[31:12], 12'b0};
	assign ra0 = odata[19:15];
	assign ra1 = odata[24:20];
	assign wa = instruction[11:7];
	wire [6:0] op = instruction[6:0];
	wire [2:0] sub_op = instruction[14:12];
	wire [31:0] imm_s = {{21{instruction[31]}}, instruction[30:25], instruction[11:7]};
	wire [31:0] imm_i = {{21{instruction[31]}}, instruction[30:20]};
	wire [31:0] imm_b = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
/* Instruction operands end */

/* Read/Write mask */
	always @(*) begin
		if(mem_access) begin
			case (sub_op[1:0])
				2'b00: dsize = 4'b0001;
				2'b01: dsize = 4'b0011;
				2'b10: dsize = 4'b1111;
				/* TODO: below is invalid */
				default: dsize = 4'b1111;
			endcase
		end else
			dsize = 4'b1111;
	end
/* Read/Write mask end */
/* READ byte mask start */
	integer i;
	always @(*) begin
		for( i = 0; i <= (32/8)-1;i = i + 1) begin
			if(dsize[i]) odata[8*i+:8] = APB_prdata[8*i+:8];
			else odata[8*i+:8] = 8'b0;
		end
	end
/* READ byte mask end */

/* debug start */
/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off WIDTH */
	wire not_use = APB_perr;
	assign odat = microop;
/* verilator lint_on WIDTH */
/* verilator lint_on UNUSEDSIGNAL */
/* debug end */

/* ALU decode start */
	always @(*) begin
		// use add imm for 1100111 AKA JALR
		if(instruction[5] && op != 7'b1100111 && !mem_access)
			aluRB = rd1;
		else if (pwrite)
			aluRB = imm_s;
		else
			aluRB = imm_i;

		// use extra ops for SRAI/SRA and non-imm(sub/add)
		if (mem_access)
			alu_op = 4'b0000;
		else if (sub_op == 5 || op == 7'b0110011)
			alu_op = {instruction[30],sub_op};
		else
			alu_op = {1'b0,sub_op};

	end
	alu alu(alu_op,rd0,aluRB,alu_out,cmp_flag);
/* ALU decode end */

/* Decode instruction groups start */
	always @(*) begin
		casez (odata[6:0])
			7'b0100011: begin // STORE
				op_jmp = 1;
			end
			7'b0000011: begin // LOAD
				op_jmp = 2;
			end
			7'b0?10111: begin //LUI/AUIPC
				op_jmp = 0 | 7;
			end
			7'b0?10011: begin // ALU
				op_jmp = 4;
			end
			7'b1101111: begin // JAL
				op_jmp = 8 | 7;
			end
			7'b1100111: begin // JALR
				op_jmp = 5;
			end
			7'b1100011: begin // BRANCH
				op_jmp = 6;
			end
			7'b1110011: begin // SYSTEM
				op_jmp = 3;
			end
			default: begin // SYSTEM
				op_jmp = 3;
			end
		endcase
	end

/* Microop PC start */
	always @(*) begin
		if(load_insr)
			microop_addr = {op_jmp[2:0], microop_pc[3:0]};
		/* Don't interrupt if we are in the interrupt handler */
		else if(microop_pc == 0 && interrupt && pc > 'h1000)
			microop_addr = 3*16 + 2; // System
		else
			microop_addr = microop_pc;
	end
/* Microop PC end */
/* Decode instruction groups end */

/* LUI/AUIPC/JAL/BRANCH start */
	reg [31:0] LAJ_val;
	always @(*) begin
		if(lui_flag && odata[5])
			LAJ_val = imm_u;
		else if(jal_flag)
			LAJ_val = oldpc + imm_j;
		else if(alu_flags)
			LAJ_val = oldpc + imm_b;
		else
			LAJ_val = oldpc + imm_u;
	end
/* LUI/AUIPC/JAL end */

/* CPU start */
	always @(posedge clk) begin
		if(rts) begin
			pc <= 0;
			APB_paddr <= 0;
			microop <= 0;
			halt <= 0;
			instruction <= 0;
		end else if(!halt) begin
			// halt till APB_pready is ready
			if(load_insr && APB_Dready) begin
				instruction <= odata;
				if(odata == 32'b0) halt <= 1;
				microop <= microop_prog[microop_addr];
				if(lui_flag) begin
					regfile[odata[11:7]] <= LAJ_val;
				end
				else if(jal_flag) begin
					regfile[odata[11:7]] <= pc;
					pc <= LAJ_val;
				end else begin
					rd0 <= ra0 == 5'b0 ? 0 : regfile[ra0];
					rd1 <= ra1 == 5'b0 ? 0 : regfile[ra1];
				end
			end
			else begin
				// halt till APB_pready is ready
				if(APB_Dready)
					microop <= microop_prog[microop_addr];

				if(microop_pc == 0) begin
					instruction <= 0;
					APB_paddr <= pc;
					pc <= pc + 4;
					oldpc <= pc;
				end else if(mem_access) begin
					APB_paddr <= alu_out;
					APB_pdata <= rd1;
					if(APB_penable && APB_psel && APB_pready && !APB_pwrite) begin
						if(sub_op[2] == 1'b0) begin
							case (sub_op[1:0])
								2'b00: regfile[wa] <= {{24{odata[7]}},odata[7:0]};
								2'b01: regfile[wa] <= {{16{odata[15]}},odata[15:0]};
								2'b10: regfile[wa] <= odata;
								default: regfile[wa] <= odata;
							endcase
						end else
							regfile[wa] <= odata;
					end
				end else if(sys_load) begin
					APB_paddr <= 4;
					APB_pdata <= pc;
					if(APB_penable && APB_psel && APB_pready) begin
						if(APB_pwrite)
							pc <= instruction;
						else
							instruction <= odata;
					end
				end else if(store_alu) regfile[wa] <= alu_out;
				else if(load_pc) begin
					if(alu_flags && cmp_flag)
						pc <= LAJ_val;
					else if(!alu_flags) begin
						pc <= alu_out;
						regfile[odata[11:7]] <= pc;
					end
				end
			end
		end
	end
/* CPU end */
endmodule
