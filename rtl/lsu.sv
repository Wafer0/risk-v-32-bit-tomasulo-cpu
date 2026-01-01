// lsu.sv
// Load/Store Unit
// Manages memory access and address calculation

module lsu (
    input logic clk,
    input logic rst,
    input logic [31:0] base_addr,
    input logic [31:0] offset,
    input logic [31:0] store_data,
    input logic [2:0] mem_op,
    input logic mem_req,
    input logic [31:0] mem_rdata,
    output logic [31:0] mem_addr,
    output logic mem_we,
    output logic mem_re,
    output logic [31:0] load_data,
    output logic ready
);

    assign mem_addr = base_addr + offset;
    assign mem_we = mem_req && (mem_op[2] == 1'b1);
    assign mem_re = mem_req && (mem_op[2] == 1'b0);
    assign load_data = mem_rdata;
    assign ready = 1'b1;

endmodule
