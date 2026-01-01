// ifq.sv
// Instruction Fetch Queue
// FIFO buffering fetched instructions before decode

module ifq (
    input logic clk,
    input logic rst,
    input logic wr_en,
    input logic [31:0] instruction_in,
    input logic [31:0] pc_in,
    input logic rd_en,
    input logic flush,
    output logic [31:0] instruction_out,
    output logic [31:0] pc_out,
    output logic empty,
    output logic full
);

    logic [63:0] fifo_rd_data;

    fifo #(.DEPTH(8), .WIDTH(64)) ifq_fifo (
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

    // Provide peek functionality - always output head when not empty
    assign {pc_out, instruction_out} = empty ? 64'b0 : fifo_rd_data;

endmodule
