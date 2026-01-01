// dispatch.sv
// Dispatch Unit
// Allocates ROB and RS slots, reads operands from RAT/RegFile

module dispatch (
    input logic clk,
    input logic rst,
    input logic [31:0] instruction,
    input logic [31:0] pc,
    input logic rs1_valid,
    input logic rs2_valid,
    input logic [4:0] rs1_tag,
    input logic [4:0] rs2_tag,
    input logic [31:0] rs1_val,
    input logic [31:0] rs2_val,
    input logic rob_full,
    input logic rs_full,
    input logic [4:0] rob_tail,
    input logic [2:0] rs_slot,
    input logic ifq_empty,
    output logic rob_we,
    output logic rs_we,
    output logic rat_we,
    output logic ifq_rd_en,
    output logic stall
);

    assign stall = rob_full || rs_full || ifq_empty;
    // Only dispatch when not stalling and IFQ has valid instruction
    // Check that instruction is not NOP (addi x0, x0, 0)
    logic valid_instruction;
    assign valid_instruction = (instruction != 32'h00000013) && (instruction != 32'h00000000);
    assign rob_we = !stall && !ifq_empty && valid_instruction;
    assign rs_we = !stall && !ifq_empty && valid_instruction;
    assign rat_we = !stall && !ifq_empty && valid_instruction;
    assign ifq_rd_en = !stall && !ifq_empty && valid_instruction;

endmodule
