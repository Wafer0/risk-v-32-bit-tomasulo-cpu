// cdb.sv
// Common Data Bus Arbiter
// Decides which execution unit broadcasts results when multiple finish simultaneously

module cdb (
    input logic alu_req,
    input logic [4:0] alu_tag,
    input logic [31:0] alu_value,
    input logic branch_req,
    input logic [4:0] branch_tag,
    input logic [31:0] branch_value,
    input logic lsu_req,
    input logic [4:0] lsu_tag,
    input logic [31:0] lsu_value,
    output logic cdb_valid,
    output logic [4:0] cdb_tag,
    output logic [31:0] cdb_value
);

    // Priority: Branch > ALU > LSU
    always_comb begin
        if (branch_req) begin
            cdb_valid = 1'b1;
            cdb_tag = branch_tag;
            cdb_value = branch_value;
        end else if (alu_req) begin
            cdb_valid = 1'b1;
            cdb_tag = alu_tag;
            cdb_value = alu_value;
        end else if (lsu_req) begin
            cdb_valid = 1'b1;
            cdb_tag = lsu_tag;
            cdb_value = lsu_value;
        end else begin
            cdb_valid = 1'b0;
            cdb_tag = 5'b0;
            cdb_value = 32'b0;
        end
    end

endmodule
