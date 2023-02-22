module alu
	(
	input [3:0]m,
	input [31:0]a, b,
	output reg [31:0]y,
	output cmp
	);
	// zf: zero
	// cf: carry out, WIDTH bit
	// of: overflow
	// sf: sign, WIDTH-1

	wire signed [31:0]a_signed = a;
	wire [31:0]addition = a + b;
	wire [32:0]subtraction = a - b;
	wire sub_of = (!a[31] & b[31] & subtraction[31]) |
				 (a[31] & !b[31] & !subtraction[31]);
	wire sub_zf = (subtraction[31:0] == 32'h0);
	wire sub_sf = subtraction[31];
	wire sub_cf = subtraction[32];
	reg compare;
	assign cmp = compare ^ m[0];
	always_comb begin
		unique case(m[2:1])
			2'b00:
				compare = sub_zf;
			2'b10:
				compare = sub_sf;
			2'b11:
				compare = sub_cf;
			//TODO: bad instruction
			2'b01:
				compare = 0;
		endcase
		case(m)
			4'b0000: // add
				y = addition[31:0];
			4'b1000: // sub
				y = subtraction[31:0];
			4'b0001: // sll
				y = a << b[4:0];
			4'b0010: // slt
				y = {31'b0, (sub_of ^ sub_sf) & !sub_zf};
			4'b0011: // sltu
				y = {31'b0, sub_cf};
			4'b0100: // xor
				y = a ^ b;
			4'b0101: // srl
				y = a >> b[4:0];
			4'b1101: // sra
				y = a_signed >>> b[4:0];
			4'b0110: // or
				y = a | b;
			4'b0111: // and
				y = a & b;
			//TODO: bad instruction
			default: begin // error
				y = 32'hDEADBEEF;
			end
		endcase
	end
endmodule
