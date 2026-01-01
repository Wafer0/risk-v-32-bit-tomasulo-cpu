module fifo (
	clk,
	rst,
	wr_en,
	wr_data,
	rd_en,
	rd_data,
	full,
	empty,
	error
);
	parameter signed [31:0] DEPTH = 32;
	parameter signed [31:0] WIDTH = 32;
	input wire clk;
	input wire rst;
	input wire wr_en;
	input wire [WIDTH - 1:0] wr_data;
	input wire rd_en;
	output wire [WIDTH - 1:0] rd_data;
	output wire full;
	output wire empty;
	output reg error;
	reg [$clog2(DEPTH) - 1:0] rd_ptr;
	reg [$clog2(DEPTH) - 1:0] wr_ptr;
	reg [WIDTH - 1:0] mem [0:DEPTH - 1];
	reg [$clog2(DEPTH):0] count;
	reg [WIDTH - 1:0] rd_data_reg;
	assign empty = count == 0;
	assign full = count == DEPTH;
	assign rd_data = (empty ? {WIDTH {1'sb0}} : mem[rd_ptr]);
	always @(posedge clk or posedge rst)
		if (rst) begin
			rd_ptr <= 1'sb0;
			wr_ptr <= 1'sb0;
			count <= 1'sb0;
			error <= 1'sb0;
			rd_data_reg <= 1'sb0;
		end
		else begin
			error <= 1'sb0;
			case ({wr_en, rd_en})
				2'b10:
					if (!full) begin
						mem[wr_ptr] <= wr_data;
						wr_ptr <= (wr_ptr + 1) % DEPTH;
						count <= count + 1;
					end
					else
						error <= 1'b1;
				2'b01:
					if (!empty) begin
						rd_data_reg <= mem[rd_ptr];
						rd_ptr <= (rd_ptr + 1) % DEPTH;
						count <= count - 1;
					end
					else
						error <= 1'b1;
				2'b11:
					if (!empty && !full) begin
						mem[wr_ptr] <= wr_data;
						wr_ptr <= (wr_ptr + 1) % DEPTH;
						rd_data_reg <= mem[rd_ptr];
						rd_ptr <= (rd_ptr + 1) % DEPTH;
					end
					else if (!full) begin
						mem[wr_ptr] <= wr_data;
						wr_ptr <= (wr_ptr + 1) % DEPTH;
						count <= count + 1;
					end
					else if (!empty) begin
						rd_data_reg <= mem[rd_ptr];
						rd_ptr <= (rd_ptr + 1) % DEPTH;
						count <= count - 1;
					end
				default:
					;
			endcase
		end
endmodule
module pc_gen (
	clk,
	rst,
	stall,
	branch_taken,
	branch_target,
	flush,
	correct_pc,
	stop_fetch,
	pc
);
	input wire clk;
	input wire rst;
	input wire stall;
	input wire branch_taken;
	input wire [31:0] branch_target;
	input wire flush;
	input wire [31:0] correct_pc;
	input wire stop_fetch;
	output reg [31:0] pc;
	always @(posedge clk)
		if (rst)
			pc <= 32'h00000000;
		else if (flush)
			pc <= correct_pc;
		else if (!stall && !stop_fetch) begin
			if (branch_taken)
				pc <= branch_target;
			else
				pc <= pc + 4;
		end
endmodule
module instr_mem (
	addr,
	instruction
);
	parameter signed [31:0] MEM_SIZE = 128;
	input wire [31:0] addr;
	output wire [31:0] instruction;
	reg [31:0] mem [0:MEM_SIZE - 1];
	integer i;
	initial for (i = 0; i < MEM_SIZE; i = i + 1)
		mem[i] = 32'h00000013;
	assign instruction = (addr[31:2] < MEM_SIZE ? mem[addr[31:2]] : 32'h00000013);
endmodule
module ifq (
	clk,
	rst,
	wr_en,
	instruction_in,
	pc_in,
	rd_en,
	flush,
	instruction_out,
	pc_out,
	empty,
	full
);
	input wire clk;
	input wire rst;
	input wire wr_en;
	input wire [31:0] instruction_in;
	input wire [31:0] pc_in;
	input wire rd_en;
	input wire flush;
	output wire [31:0] instruction_out;
	output wire [31:0] pc_out;
	output wire empty;
	output wire full;
	wire [63:0] fifo_rd_data;
	fifo #(
		.DEPTH(8),
		.WIDTH(64)
	) ifq_fifo(
		.clk(clk),
		.rst(rst || flush),
		.wr_en(wr_en),
		.wr_data({pc_in, instruction_in}),
		.rd_en(rd_en),
		.rd_data(fifo_rd_data),
		.empty(empty),
		.full(full),
		.error()
	);
	assign {pc_out, instruction_out} = (empty ? 64'b0000000000000000000000000000000000000000000000000000000000000000 : fifo_rd_data);
endmodule
module decoder (
	instruction,
	opcode,
	rs1,
	rs2,
	rd,
	funct3,
	funct7,
	imm,
	imm_type
);
	reg _sv2v_0;
	input wire [31:0] instruction;
	output wire [6:0] opcode;
	output wire [4:0] rs1;
	output wire [4:0] rs2;
	output wire [4:0] rd;
	output wire [2:0] funct3;
	output wire [6:0] funct7;
	output reg [31:0] imm;
	output reg [1:0] imm_type;
	assign opcode = instruction[6:0];
	assign rd = instruction[11:7];
	assign funct3 = instruction[14:12];
	assign rs1 = instruction[19:15];
	assign rs2 = instruction[24:20];
	assign funct7 = instruction[31:25];
	always @(*) begin
		if (_sv2v_0)
			;
		imm_type = 2'b00;
		imm = 32'b00000000000000000000000000000000;
		case (opcode)
			7'b0010011, 7'b0000011, 7'b1100111: begin
				imm_type = 2'b01;
				imm = {{20 {instruction[31]}}, instruction[31:20]};
			end
			7'b0100011: begin
				imm_type = 2'b10;
				imm = {{20 {instruction[31]}}, instruction[31:25], instruction[11:7]};
			end
			7'b1100011: begin
				imm_type = 2'b11;
				imm = {{20 {instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
			end
			7'b0110111, 7'b0010111: imm = {instruction[31:12], 12'b000000000000};
			7'b1101111: imm = {{12 {instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
			default: imm = 32'b00000000000000000000000000000000;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module rat (
	clk,
	rst,
	rs1,
	rs2,
	rd,
	rat_we,
	rob_tag_in,
	cdb_tag,
	cdb_valid,
	flush,
	rs1_valid,
	rs2_valid,
	rs1_tag,
	rs2_tag
);
	input wire clk;
	input wire rst;
	input wire [4:0] rs1;
	input wire [4:0] rs2;
	input wire [4:0] rd;
	input wire rat_we;
	input wire [4:0] rob_tag_in;
	input wire [4:0] cdb_tag;
	input wire cdb_valid;
	input wire flush;
	output wire rs1_valid;
	output wire rs2_valid;
	output wire [4:0] rs1_tag;
	output wire [4:0] rs2_tag;
	reg [31:0] rat_valid;
	reg [4:0] rat_tag [0:31];
	assign rs1_valid = (rs1 == 5'b00000 ? 1'b0 : rat_valid[rs1]);
	assign rs1_tag = (rs1 == 5'b00000 ? 5'b00000 : rat_tag[rs1]);
	assign rs2_valid = (rs2 == 5'b00000 ? 1'b0 : rat_valid[rs2]);
	assign rs2_tag = (rs2 == 5'b00000 ? 5'b00000 : rat_tag[rs2]);
	always @(posedge clk)
		if (rst || flush) begin
			rat_valid <= 32'b00000000000000000000000000000000;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < 32; i = i + 1)
					rat_tag[i] <= 5'b00000;
			end
		end
		else begin
			if (cdb_valid) begin : sv2v_autoblock_2
				reg signed [31:0] i;
				for (i = 0; i < 32; i = i + 1)
					if (rat_valid[i] && (rat_tag[i] == cdb_tag))
						rat_valid[i] <= 1'b0;
			end
			if (rat_we && (rd != 5'b00000)) begin
				rat_valid[rd] <= 1'b1;
				rat_tag[rd] <= rob_tag_in;
			end
		end
endmodule
module reg_file (
	clk,
	rst,
	reg_write,
	read_addr1,
	read_addr2,
	write_addr,
	write_data,
	read_data1,
	read_data2
);
	input wire clk;
	input wire rst;
	input wire reg_write;
	input wire [4:0] read_addr1;
	input wire [4:0] read_addr2;
	input wire [4:0] write_addr;
	input wire [31:0] write_data;
	output wire [31:0] read_data1;
	output wire [31:0] read_data2;
	reg [31:0] registers [0:31];
	assign read_data1 = (read_addr1 == 5'b00000 ? 32'b00000000000000000000000000000000 : registers[read_addr1]);
	assign read_data2 = (read_addr2 == 5'b00000 ? 32'b00000000000000000000000000000000 : registers[read_addr2]);
	always @(posedge clk)
		if (rst) begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				registers[i] <= 32'b00000000000000000000000000000000;
		end
		else if (reg_write && (write_addr != 5'b00000))
			registers[write_addr] <= write_data;
endmodule
module dispatch (
	clk,
	rst,
	instruction,
	pc,
	rs1_valid,
	rs2_valid,
	rs1_tag,
	rs2_tag,
	rs1_val,
	rs2_val,
	rob_full,
	rs_full,
	rob_tail,
	rs_slot,
	ifq_empty,
	rob_we,
	rs_we,
	rat_we,
	ifq_rd_en,
	stall
);
	input wire clk;
	input wire rst;
	input wire [31:0] instruction;
	input wire [31:0] pc;
	input wire rs1_valid;
	input wire rs2_valid;
	input wire [4:0] rs1_tag;
	input wire [4:0] rs2_tag;
	input wire [31:0] rs1_val;
	input wire [31:0] rs2_val;
	input wire rob_full;
	input wire rs_full;
	input wire [4:0] rob_tail;
	input wire [2:0] rs_slot;
	input wire ifq_empty;
	output wire rob_we;
	output wire rs_we;
	output wire rat_we;
	output wire ifq_rd_en;
	output wire stall;
	assign stall = (rob_full || rs_full) || ifq_empty;
	wire valid_instruction;
	assign valid_instruction = (instruction != 32'h00000013) && (instruction != 32'h00000000);
	assign rob_we = (!stall && !ifq_empty) && valid_instruction;
	assign rs_we = (!stall && !ifq_empty) && valid_instruction;
	assign rat_we = (!stall && !ifq_empty) && valid_instruction;
	assign ifq_rd_en = (!stall && !ifq_empty) && valid_instruction;
endmodule
module reservation_station (
	clk,
	rst,
	rs_we,
	rs_slot,
	op,
	opcode,
	vj,
	vk,
	imm,
	qj,
	qk,
	rob_tag,
	cdb_tag,
	cdb_value,
	cdb_valid,
	flush,
	execute_clear,
	execute_slot,
	ready_slot,
	ready,
	full,
	ready_op,
	ready_opcode,
	ready_vj,
	ready_vk,
	ready_imm,
	ready_rob_tag,
	free_slot
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	input wire rs_we;
	input wire [2:0] rs_slot;
	input wire [3:0] op;
	input wire [6:0] opcode;
	input wire [31:0] vj;
	input wire [31:0] vk;
	input wire [31:0] imm;
	input wire [4:0] qj;
	input wire [4:0] qk;
	input wire [4:0] rob_tag;
	input wire [4:0] cdb_tag;
	input wire [31:0] cdb_value;
	input wire cdb_valid;
	input wire flush;
	input wire execute_clear;
	input wire [2:0] execute_slot;
	output reg [2:0] ready_slot;
	output reg ready;
	output reg full;
	output reg [3:0] ready_op;
	output reg [6:0] ready_opcode;
	output reg [31:0] ready_vj;
	output reg [31:0] ready_vk;
	output reg [31:0] ready_imm;
	output reg [4:0] ready_rob_tag;
	output reg [2:0] free_slot;
	reg [7:0] busy;
	reg [3:0] op_arr [0:7];
	reg [6:0] opcode_arr [0:7];
	reg [31:0] vj_arr [0:7];
	reg [31:0] vk_arr [0:7];
	reg [4:0] qj_arr [0:7];
	reg [4:0] qk_arr [0:7];
	reg [4:0] rob_tag_arr [0:7];
	reg [31:0] imm_arr [0:7];
	reg [7:0] ready_vec;
	always @(*) begin
		if (_sv2v_0)
			;
		ready = 1'b0;
		ready_slot = 3'b000;
		ready_vec = 8'b00000000;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 8; i = i + 1)
				begin
					ready_vec[i] = (busy[i] && (qj_arr[i] == 5'b00000)) && (qk_arr[i] == 5'b00000);
					if (ready_vec[i] && !ready) begin
						ready = 1'b1;
						ready_slot = i[2:0];
					end
				end
		end
		full = &busy;
		free_slot = 3'b000;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < 8; i = i + 1)
				if (!busy[i] && (free_slot == 3'b000))
					free_slot = i[2:0];
		end
		if (ready) begin
			ready_op = op_arr[ready_slot];
			ready_opcode = opcode_arr[ready_slot];
			ready_vj = vj_arr[ready_slot];
			ready_vk = vk_arr[ready_slot];
			ready_imm = imm_arr[ready_slot];
			ready_rob_tag = rob_tag_arr[ready_slot];
		end
		else begin
			ready_op = 4'b0000;
			ready_opcode = 7'b0000000;
			ready_vj = 32'b00000000000000000000000000000000;
			ready_vk = 32'b00000000000000000000000000000000;
			ready_imm = 32'b00000000000000000000000000000000;
			ready_rob_tag = 5'b00000;
		end
	end
	always @(posedge clk)
		if (rst || flush) begin
			busy <= 8'b00000000;
			begin : sv2v_autoblock_3
				reg signed [31:0] i;
				for (i = 0; i < 8; i = i + 1)
					begin
						op_arr[i] <= 4'b0000;
						opcode_arr[i] <= 7'b0000000;
						vj_arr[i] <= 32'b00000000000000000000000000000000;
						vk_arr[i] <= 32'b00000000000000000000000000000000;
						qj_arr[i] <= 5'b00000;
						qk_arr[i] <= 5'b00000;
						rob_tag_arr[i] <= 5'b00000;
						imm_arr[i] <= 32'b00000000000000000000000000000000;
					end
			end
		end
		else begin
			if (cdb_valid) begin : sv2v_autoblock_4
				reg signed [31:0] i;
				for (i = 0; i < 8; i = i + 1)
					if (busy[i]) begin
						if (qj_arr[i] == cdb_tag) begin
							vj_arr[i] <= cdb_value;
							qj_arr[i] <= 5'b00000;
						end
						if (qk_arr[i] == cdb_tag) begin
							vk_arr[i] <= cdb_value;
							qk_arr[i] <= 5'b00000;
						end
					end
			end
			if (execute_clear)
				busy[execute_slot] <= 1'b0;
			if (rs_we) begin
				busy[rs_slot] <= 1'b1;
				op_arr[rs_slot] <= op;
				opcode_arr[rs_slot] <= opcode;
				vj_arr[rs_slot] <= vj;
				vk_arr[rs_slot] <= vk;
				qj_arr[rs_slot] <= qj;
				qk_arr[rs_slot] <= qk;
				rob_tag_arr[rs_slot] <= rob_tag;
				imm_arr[rs_slot] <= imm;
			end
		end
	initial _sv2v_0 = 0;
endmodule
module issue_queue (
	clk,
	rst,
	flush,
	empty
);
	input wire clk;
	input wire rst;
	input wire flush;
	output wire empty;
	assign empty = 1'b1;
endmodule
module alu (
	a,
	b,
	op,
	result,
	zero
);
	reg _sv2v_0;
	input wire [31:0] a;
	input wire [31:0] b;
	input wire [3:0] op;
	output reg [31:0] result;
	output reg zero;
	always @(*) begin
		if (_sv2v_0)
			;
		case (op)
			4'b0000: result = a + b;
			4'b0001: result = a - b;
			4'b0010: result = a & b;
			4'b0011: result = a | b;
			4'b0100: result = a ^ b;
			4'b0101: result = a << b[4:0];
			4'b0110: result = a >> b[4:0];
			4'b0111: result = ($signed(a) < $signed(b) ? 32'd1 : 32'd0);
			4'b1000: result = (a < b ? 32'd1 : 32'd0);
			4'b1001: result = $signed(a) >>> b[4:0];
			default: result = 32'b00000000000000000000000000000000;
		endcase
		zero = result == 32'b00000000000000000000000000000000;
	end
	initial _sv2v_0 = 0;
endmodule
module branch_unit (
	rs1_val,
	rs2_val,
	pc,
	imm,
	branch_type,
	predicted_taken,
	predicted_target,
	taken,
	target,
	mispredict,
	correct_pc
);
	reg _sv2v_0;
	input wire [31:0] rs1_val;
	input wire [31:0] rs2_val;
	input wire [31:0] pc;
	input wire [31:0] imm;
	input wire [2:0] branch_type;
	input wire predicted_taken;
	input wire [31:0] predicted_target;
	output reg taken;
	output reg [31:0] target;
	output reg mispredict;
	output reg [31:0] correct_pc;
	reg condition_met;
	always @(*) begin
		if (_sv2v_0)
			;
		condition_met = 1'b0;
		if (branch_type == 3'b111) begin
			taken = 1'b1;
			target = pc + imm;
		end
		else begin
			case (branch_type)
				3'b000: condition_met = rs1_val == rs2_val;
				3'b001: condition_met = rs1_val != rs2_val;
				3'b100: condition_met = $signed(rs1_val) < $signed(rs2_val);
				3'b101: condition_met = $signed(rs1_val) >= $signed(rs2_val);
				3'b110: condition_met = rs1_val < rs2_val;
				default: condition_met = 1'b0;
			endcase
			taken = condition_met;
			target = (taken ? pc + imm : pc + 4);
		end
		mispredict = (predicted_taken != taken) || (predicted_target != target);
		correct_pc = target;
	end
	initial _sv2v_0 = 0;
endmodule
module lsu (
	clk,
	rst,
	base_addr,
	offset,
	store_data,
	mem_op,
	mem_req,
	mem_rdata,
	mem_addr,
	mem_we,
	mem_re,
	load_data,
	ready
);
	input wire clk;
	input wire rst;
	input wire [31:0] base_addr;
	input wire [31:0] offset;
	input wire [31:0] store_data;
	input wire [2:0] mem_op;
	input wire mem_req;
	input wire [31:0] mem_rdata;
	output wire [31:0] mem_addr;
	output wire mem_we;
	output wire mem_re;
	output wire [31:0] load_data;
	output wire ready;
	assign mem_addr = base_addr + offset;
	assign mem_we = mem_req && (mem_op[2] == 1'b1);
	assign mem_re = mem_req && (mem_op[2] == 1'b0);
	assign load_data = mem_rdata;
	assign ready = 1'b1;
endmodule
module cdb (
	alu_req,
	alu_tag,
	alu_value,
	branch_req,
	branch_tag,
	branch_value,
	lsu_req,
	lsu_tag,
	lsu_value,
	cdb_valid,
	cdb_tag,
	cdb_value
);
	reg _sv2v_0;
	input wire alu_req;
	input wire [4:0] alu_tag;
	input wire [31:0] alu_value;
	input wire branch_req;
	input wire [4:0] branch_tag;
	input wire [31:0] branch_value;
	input wire lsu_req;
	input wire [4:0] lsu_tag;
	input wire [31:0] lsu_value;
	output reg cdb_valid;
	output reg [4:0] cdb_tag;
	output reg [31:0] cdb_value;
	always @(*) begin
		if (_sv2v_0)
			;
		if (branch_req) begin
			cdb_valid = 1'b1;
			cdb_tag = branch_tag;
			cdb_value = branch_value;
		end
		else if (alu_req) begin
			cdb_valid = 1'b1;
			cdb_tag = alu_tag;
			cdb_value = alu_value;
		end
		else if (lsu_req) begin
			cdb_valid = 1'b1;
			cdb_tag = lsu_tag;
			cdb_value = lsu_value;
		end
		else begin
			cdb_valid = 1'b0;
			cdb_tag = 5'b00000;
			cdb_value = 32'b00000000000000000000000000000000;
		end
	end
	initial _sv2v_0 = 0;
endmodule
module reorder_buffer (
	clk,
	rst,
	rob_we,
	rob_tail_in,
	rd,
	pc,
	inst_type,
	cdb_tag,
	cdb_value,
	cdb_valid,
	flush,
	flush_pc,
	rob_head,
	commit_rd,
	commit_value,
	commit_valid,
	full
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	input wire rob_we;
	input wire [4:0] rob_tail_in;
	input wire [4:0] rd;
	input wire [31:0] pc;
	input wire [2:0] inst_type;
	input wire [4:0] cdb_tag;
	input wire [31:0] cdb_value;
	input wire cdb_valid;
	input wire flush;
	input wire [31:0] flush_pc;
	output wire [4:0] rob_head;
	output reg [4:0] commit_rd;
	output reg [31:0] commit_value;
	output reg commit_valid;
	output wire full;
	reg [15:0] valid;
	reg [4:0] rd_arr [0:15];
	reg [31:0] value_arr [0:15];
	reg [31:0] pc_arr [0:15];
	reg [2:0] inst_type_arr [0:15];
	reg [4:0] head_ptr;
	reg [4:0] tail_ptr;
	assign rob_head = head_ptr;
	assign full = ((tail_ptr + 1) % 16) == head_ptr;
	always @(*) begin
		if (_sv2v_0)
			;
		commit_valid = valid[head_ptr] && !flush;
		commit_rd = rd_arr[head_ptr];
		commit_value = value_arr[head_ptr];
	end
	always @(posedge clk)
		if (rst || flush) begin
			head_ptr <= 5'b00000;
			tail_ptr <= 5'b00000;
			valid <= 16'b0000000000000000;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < 16; i = i + 1)
					begin
						rd_arr[i] <= 5'b00000;
						value_arr[i] <= 32'b00000000000000000000000000000000;
						pc_arr[i] <= 32'b00000000000000000000000000000000;
						inst_type_arr[i] <= 3'b000;
					end
			end
		end
		else begin
			if (cdb_valid) begin
				valid[cdb_tag] <= 1'b1;
				value_arr[cdb_tag] <= cdb_value;
			end
			if (rob_we) begin
				rd_arr[rob_tail_in] <= rd;
				pc_arr[rob_tail_in] <= pc;
				inst_type_arr[rob_tail_in] <= inst_type;
				valid[rob_tail_in] <= 1'b0;
				tail_ptr <= (rob_tail_in + 1) % 16;
			end
			if (commit_valid) begin
				valid[head_ptr] <= 1'b0;
				head_ptr <= (head_ptr + 1) % 16;
			end
		end
	initial _sv2v_0 = 0;
endmodule
module top (
	clk,
	rst,
	imem_addr,
	dmem_addr,
	dmem_wdata,
	dmem_rdata,
	dmem_we,
	dmem_re
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	output wire [31:0] imem_addr;
	output wire [31:0] dmem_addr;
	output wire [31:0] dmem_wdata;
	input wire [31:0] dmem_rdata;
	output wire dmem_we;
	output wire dmem_re;
	wire [31:0] pc;
	wire [31:0] instruction;
	wire stall;
	wire flush;
	wire [31:0] correct_pc;
	wire [31:0] ifq_instruction;
	wire [31:0] ifq_pc;
	wire ifq_empty;
	wire ifq_full;
	wire ifq_wr_en;
	wire ifq_rd_en;
	wire [4:0] rs1;
	wire [4:0] rs2;
	wire [4:0] rd;
	wire [31:0] imm;
	wire [2:0] funct3;
	wire [6:0] funct7;
	wire [6:0] opcode;
	wire [31:0] reg_data1;
	wire [31:0] reg_data2;
	reg reg_write;
	reg [4:0] write_addr;
	reg [31:0] write_data;
	wire [31:0] alu_result;
	wire alu_zero;
	reg [3:0] alu_op;
	reg [31:0] cycle_counter;
	reg [31:0] state_reg;
	assign stall = cycle_counter[3:0] == 4'b1111;
	assign flush = 1'b0;
	assign correct_pc = state_reg;
	always @(*) begin
		if (_sv2v_0)
			;
		if (opcode == 7'b0110011)
			case (funct3)
				3'b000: alu_op = (funct7[5] == 1'b1 ? 4'b0001 : 4'b0000);
				3'b100: alu_op = 4'b0100;
				3'b110: alu_op = 4'b0011;
				3'b111: alu_op = 4'b0010;
				default: alu_op = 4'b0000;
			endcase
		else if (opcode == 7'b0010011)
			case (funct3)
				3'b000: alu_op = 4'b0000;
				default: alu_op = 4'b0000;
			endcase
		else
			alu_op = 4'b0000;
	end
	wire stop_fetch;
	wire fetching_nop;
	reg program_started;
	assign fetching_nop = instruction == 32'h00000013;
	always @(posedge clk)
		if (rst)
			program_started <= 1'b0;
		else if (!stall) begin
			if (!fetching_nop && (pc >= 32'h00000000))
				program_started <= 1'b1;
		end
	assign stop_fetch = fetching_nop && program_started;
	reg branch_execute_valid;
	wire branch_taken;
	wire [31:0] branch_target;
	pc_gen pc_inst(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.branch_taken(branch_taken && branch_execute_valid),
		.branch_target(branch_target),
		.flush(flush),
		.correct_pc(correct_pc),
		.stop_fetch(stop_fetch),
		.pc(pc)
	);
	assign imem_addr = pc;
	instr_mem imem_inst(
		.addr(pc),
		.instruction(instruction)
	);
	ifq ifq_inst(
		.clk(clk),
		.rst(rst),
		.wr_en(ifq_wr_en),
		.instruction_in(instruction),
		.pc_in(pc),
		.rd_en(ifq_rd_en),
		.flush(flush),
		.instruction_out(ifq_instruction),
		.pc_out(ifq_pc),
		.empty(ifq_empty),
		.full(ifq_full)
	);
	decoder decoder_inst(
		.instruction(ifq_instruction),
		.rs1(rs1),
		.rs2(rs2),
		.rd(rd),
		.imm(imm),
		.funct3(funct3),
		.funct7(funct7),
		.opcode(opcode)
	);
	wire rs1_valid;
	wire rs2_valid;
	wire [4:0] rs1_tag;
	wire [4:0] rs2_tag;
	wire rat_we;
	wire [4:0] rob_tail;
	wire [4:0] cdb_tag;
	wire cdb_valid;
	rat rat_inst(
		.clk(clk),
		.rst(rst),
		.rs1(rs1),
		.rs2(rs2),
		.rd(rd),
		.rat_we(rat_we),
		.rob_tag_in(rob_tail),
		.cdb_tag(cdb_tag),
		.cdb_valid(cdb_valid),
		.flush(flush),
		.rs1_valid(rs1_valid),
		.rs2_valid(rs2_valid),
		.rs1_tag(rs1_tag),
		.rs2_tag(rs2_tag)
	);
	reg_file reg_file_inst(
		.clk(clk),
		.rst(rst),
		.reg_write(reg_write),
		.read_addr1(rs1),
		.read_addr2(rs2),
		.write_addr(write_addr),
		.write_data(write_data),
		.read_data1(reg_data1),
		.read_data2(reg_data2)
	);
	wire rob_we;
	wire rob_full;
	wire [4:0] rob_head;
	wire [4:0] commit_rd;
	wire [31:0] commit_value;
	wire commit_valid;
	wire [2:0] inst_type;
	assign inst_type = (opcode == 7'b0010011 ? 3'b001 : (opcode == 7'b0110011 ? 3'b010 : (opcode == 7'b1100011 ? 3'b011 : ((opcode == 7'b1101111) || (opcode == 7'b1100111) ? 3'b100 : 3'b000))));
	wire [31:0] cdb_value;
	reorder_buffer rob_inst(
		.clk(clk),
		.rst(rst),
		.rob_we(rob_we),
		.rob_tail_in(rob_tail),
		.rd(rd),
		.pc(ifq_pc),
		.inst_type(inst_type),
		.cdb_tag(cdb_tag),
		.cdb_value(cdb_value),
		.cdb_valid(cdb_valid),
		.flush(flush),
		.flush_pc(32'b00000000000000000000000000000000),
		.rob_head(rob_head),
		.commit_rd(commit_rd),
		.commit_value(commit_value),
		.commit_valid(commit_valid),
		.full(rob_full)
	);
	reg [4:0] rob_tail_ptr;
	always @(posedge clk)
		if (rst)
			rob_tail_ptr <= 5'b00000;
		else if (!stall) begin
			if (rob_we)
				rob_tail_ptr <= (rob_tail_ptr + 1) % 16;
		end
	assign rob_tail = rob_tail_ptr;
	wire rs_we;
	wire [2:0] rs_slot;
	wire rs_full;
	wire rs_ready;
	wire [2:0] ready_slot;
	wire [3:0] rs_ready_op;
	wire [6:0] rs_ready_opcode;
	wire [31:0] rs_ready_vj;
	wire [31:0] rs_ready_vk;
	wire [31:0] rs_ready_imm;
	wire [4:0] rs_ready_rob_tag;
	wire rs_execute_clear;
	wire [2:0] rs_free_slot;
	reservation_station rs_inst(
		.clk(clk),
		.rst(rst),
		.rs_we(rs_we),
		.rs_slot(rs_slot),
		.op(alu_op),
		.opcode(opcode),
		.vj((!rs1_valid ? reg_data1 : 32'b00000000000000000000000000000000)),
		.vk((!rs2_valid ? reg_data2 : 32'b00000000000000000000000000000000)),
		.imm(imm),
		.qj((rs1_valid ? rs1_tag : 5'b00000)),
		.qk((rs2_valid ? rs2_tag : 5'b00000)),
		.rob_tag(rob_tail),
		.cdb_tag(cdb_tag),
		.cdb_value(cdb_value),
		.cdb_valid(cdb_valid),
		.flush(flush),
		.execute_clear(rs_execute_clear),
		.execute_slot(ready_slot),
		.ready_slot(ready_slot),
		.ready(rs_ready),
		.full(rs_full),
		.ready_op(rs_ready_op),
		.ready_opcode(rs_ready_opcode),
		.ready_vj(rs_ready_vj),
		.ready_vk(rs_ready_vk),
		.ready_imm(rs_ready_imm),
		.ready_rob_tag(rs_ready_rob_tag),
		.free_slot(rs_free_slot)
	);
	assign rs_slot = rs_free_slot;
	wire issue_stall;
	dispatch dispatch_inst(
		.clk(clk),
		.rst(rst),
		.instruction(ifq_instruction),
		.pc(ifq_pc),
		.rs1_valid(rs1_valid),
		.rs2_valid(rs2_valid),
		.rs1_tag(rs1_tag),
		.rs2_tag(rs2_tag),
		.rs1_val(reg_data1),
		.rs2_val(reg_data2),
		.rob_full(rob_full),
		.rs_full(rs_full),
		.rob_tail(rob_tail),
		.rs_slot(rs_slot),
		.ifq_empty(ifq_empty),
		.rob_we(rob_we),
		.rs_we(rs_we),
		.rat_we(rat_we),
		.ifq_rd_en(ifq_rd_en),
		.stall(issue_stall)
	);
	assign ifq_wr_en = (!ifq_full && !fetching_nop) && !stop_fetch;
	reg rs_execute_clear_alu;
	reg rs_execute_clear_branch;
	assign rs_execute_clear = rs_execute_clear_alu | rs_execute_clear_branch;
	reg issue_valid;
	reg [31:0] issue_instruction;
	reg [4:0] issue_rd;
	reg [31:0] issue_imm;
	reg [2:0] issue_funct3;
	reg [6:0] issue_funct7;
	reg [6:0] issue_opcode;
	reg [4:0] issue_rob_tag;
	reg [31:0] issue_vj;
	reg [31:0] issue_vk;
	reg [3:0] issue_alu_op;
	always @(posedge clk)
		if (rst) begin
			issue_valid <= 1'b0;
			issue_instruction <= 32'h00000013;
			issue_rd <= 5'b00000;
			issue_imm <= 32'b00000000000000000000000000000000;
			issue_funct3 <= 3'b000;
			issue_funct7 <= 7'b0000000;
			issue_opcode <= 7'b0000000;
			issue_rob_tag <= 5'b00000;
			issue_vj <= 32'b00000000000000000000000000000000;
			issue_vk <= 32'b00000000000000000000000000000000;
			issue_alu_op <= 4'b0000;
		end
		else if (((!stall && !issue_stall) && !ifq_empty) && ifq_rd_en) begin
			issue_valid <= 1'b1;
			issue_instruction <= ifq_instruction;
			issue_rd <= rd;
			issue_imm <= imm;
			issue_funct3 <= funct3;
			issue_funct7 <= funct7;
			issue_opcode <= opcode;
			issue_rob_tag <= rob_tail;
			issue_vj <= reg_data1;
			issue_vk <= reg_data2;
			if (opcode == 7'b0110011)
				case (funct3)
					3'b000: issue_alu_op = (funct7[5] == 1'b1 ? 4'b0001 : 4'b0000);
					3'b100: issue_alu_op = 4'b0100;
					3'b110: issue_alu_op = 4'b0011;
					3'b111: issue_alu_op = 4'b0010;
					default: issue_alu_op = 4'b0000;
				endcase
			else if (opcode == 7'b0010011)
				case (funct3)
					3'b000: issue_alu_op = 4'b0000;
					default: issue_alu_op = 4'b0000;
				endcase
			else
				issue_alu_op = 4'b0000;
		end
		else
			issue_valid <= 1'b0;
	reg execute_valid;
	reg [3:0] alu_op_execute;
	reg [31:0] alu_a_execute;
	reg [31:0] alu_b_execute;
	reg [4:0] rob_tag_execute;
	always @(posedge clk)
		if (rst) begin
			execute_valid <= 1'b0;
			alu_op_execute <= 4'b0000;
			alu_a_execute <= 32'b00000000000000000000000000000000;
			alu_b_execute <= 32'b00000000000000000000000000000000;
			rob_tag_execute <= 5'b00000;
			rs_execute_clear_alu <= 1'b0;
		end
		else if ((!stall && rs_ready) && (((rs_ready_opcode != 7'b1100011) && (rs_ready_opcode != 7'b1101111)) && (rs_ready_opcode != 7'b1100111))) begin
			execute_valid <= 1'b1;
			alu_op_execute <= rs_ready_op;
			alu_a_execute <= rs_ready_vj;
			if (rs_ready_opcode == 7'b0010011)
				alu_b_execute <= rs_ready_imm;
			else if (rs_ready_opcode == 7'b0110011)
				alu_b_execute <= rs_ready_vk;
			else
				alu_b_execute <= rs_ready_imm;
			rob_tag_execute <= rs_ready_rob_tag;
			rs_execute_clear_alu <= 1'b1;
		end
		else begin
			execute_valid <= 1'b0;
			rs_execute_clear_alu <= 1'b0;
		end
	alu alu_inst(
		.a(alu_a_execute),
		.b(alu_b_execute),
		.op(alu_op_execute),
		.result(alu_result),
		.zero(alu_zero)
	);
	reg [2:0] branch_funct3_execute;
	reg [31:0] branch_pc_execute;
	reg [31:0] branch_imm_execute;
	reg [31:0] branch_rs1_val_execute;
	reg [31:0] branch_rs2_val_execute;
	reg [4:0] branch_rob_tag_execute;
	wire branch_mispredict;
	wire [31:0] branch_correct_pc;
	always @(posedge clk)
		if (rst) begin
			branch_execute_valid <= 1'b0;
			branch_funct3_execute <= 3'b000;
			branch_pc_execute <= 32'b00000000000000000000000000000000;
			branch_imm_execute <= 32'b00000000000000000000000000000000;
			branch_rs1_val_execute <= 32'b00000000000000000000000000000000;
			branch_rs2_val_execute <= 32'b00000000000000000000000000000000;
			branch_rob_tag_execute <= 5'b00000;
		end
		else if ((!stall && rs_ready) && (((rs_ready_opcode == 7'b1100011) || (rs_ready_opcode == 7'b1101111)) || (rs_ready_opcode == 7'b1100111))) begin
			branch_execute_valid <= 1'b1;
			branch_funct3_execute <= ((rs_ready_opcode == 7'b1101111) || (rs_ready_opcode == 7'b1100111) ? 3'b111 : rs_ready_op[2:0]);
			branch_pc_execute <= rs_ready_rob_tag * 4;
			branch_imm_execute <= rs_ready_imm;
			branch_rs1_val_execute <= rs_ready_vj;
			branch_rs2_val_execute <= rs_ready_vk;
			branch_rob_tag_execute <= rs_ready_rob_tag;
			rs_execute_clear_branch <= 1'b1;
		end
		else begin
			branch_execute_valid <= 1'b0;
			rs_execute_clear_branch <= 1'b0;
		end
	branch_unit branch_unit_inst(
		.rs1_val(branch_rs1_val_execute),
		.rs2_val(branch_rs2_val_execute),
		.pc(branch_pc_execute),
		.imm(branch_imm_execute),
		.branch_type(branch_funct3_execute),
		.predicted_taken(1'b0),
		.predicted_target(32'b00000000000000000000000000000000),
		.taken(branch_taken),
		.target(branch_target),
		.mispredict(branch_mispredict),
		.correct_pc(branch_correct_pc)
	);
	reg wb_valid;
	reg [4:0] wb_tag;
	reg [31:0] wb_value;
	reg branch_wb_valid;
	reg [4:0] branch_wb_tag;
	reg [31:0] branch_wb_value;
	always @(posedge clk)
		if (rst) begin
			wb_valid <= 1'b0;
			wb_tag <= 5'b00000;
			wb_value <= 32'b00000000000000000000000000000000;
			branch_wb_valid <= 1'b0;
			branch_wb_tag <= 5'b00000;
			branch_wb_value <= 32'b00000000000000000000000000000000;
		end
		else if (!stall) begin
			wb_valid <= execute_valid;
			wb_tag <= rob_tag_execute;
			wb_value <= alu_result;
			branch_wb_valid <= branch_execute_valid;
			branch_wb_tag <= branch_rob_tag_execute;
			branch_wb_value <= (branch_funct3_execute == 3'b111 ? branch_pc_execute + 4 : branch_target);
		end
	cdb cdb_inst(
		.alu_req(wb_valid),
		.alu_tag(wb_tag),
		.alu_value(wb_value),
		.branch_req(branch_wb_valid),
		.branch_tag(branch_wb_tag),
		.branch_value(branch_wb_value),
		.lsu_req(1'b0),
		.lsu_tag(5'b00000),
		.lsu_value(32'b00000000000000000000000000000000),
		.cdb_valid(cdb_valid),
		.cdb_tag(cdb_tag),
		.cdb_value(cdb_value)
	);
	always @(posedge clk)
		if (rst) begin
			reg_write <= 1'b0;
			write_addr <= 5'b00000;
			write_data <= 32'b00000000000000000000000000000000;
		end
		else if (!stall) begin
			if (commit_valid && (commit_rd != 5'b00000)) begin
				reg_write <= 1'b1;
				write_addr <= commit_rd;
				write_data <= commit_value;
			end
			else
				reg_write <= 1'b0;
		end
	always @(posedge clk)
		if (rst) begin
			cycle_counter <= 32'b00000000000000000000000000000000;
			state_reg <= 32'b00000000000000000000000000000000;
		end
		else begin
			cycle_counter <= cycle_counter + 1;
			state_reg <= ((reg_data1 + reg_data2) + alu_result) + pc;
		end
	wire [31:0] pc_plus_4;
	assign pc_plus_4 = pc + 4;
	wire [31:0] combined_data;
	assign combined_data = (((reg_data1 + reg_data2) + alu_result) + pc_plus_4) + cycle_counter;
	assign dmem_addr = alu_result;
	assign dmem_wdata = reg_data2;
	assign dmem_we = reg_write && (opcode == 7'b0100011);
	assign dmem_re = !ifq_empty && (opcode == 7'b0000011);
	initial _sv2v_0 = 0;
endmodule
