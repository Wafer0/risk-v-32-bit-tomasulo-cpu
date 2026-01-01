// rat.sv
// Register Alias Table
// Maps architectural registers to ROB tags for register renaming

module rat (
    input logic clk,
    input logic rst,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic rat_we,
    input logic [4:0] rob_tag_in,
    input logic [4:0] cdb_tag,
    input logic cdb_valid,
    input logic flush,
    output logic rs1_valid,
    output logic rs2_valid,
    output logic [4:0] rs1_tag,
    output logic [4:0] rs2_tag
);

    logic [31:0] rat_valid;
    logic [4:0] rat_tag [0:31];

    // Read ports
    assign rs1_valid = (rs1 == 5'b0) ? 1'b0 : rat_valid[rs1];
    assign rs1_tag = (rs1 == 5'b0) ? 5'b0 : rat_tag[rs1];
    assign rs2_valid = (rs2 == 5'b0) ? 1'b0 : rat_valid[rs2];
    assign rs2_tag = (rs2 == 5'b0) ? 5'b0 : rat_tag[rs2];

    // Write and update logic
    always_ff @(posedge clk) begin
        if (rst || flush) begin
            rat_valid <= 32'b0;
            for (int i = 0; i < 32; i++) begin
                rat_tag[i] <= 5'b0;
            end
        end else begin
            // CDB update (clear valid if tag matches)
            if (cdb_valid) begin
                for (int i = 0; i < 32; i++) begin
                    if (rat_valid[i] && (rat_tag[i] == cdb_tag)) begin
                        rat_valid[i] <= 1'b0;
                    end
                end
            end

            // Dispatch write (rename)
            if (rat_we && rd != 5'b0) begin
                rat_valid[rd] <= 1'b1;
                rat_tag[rd] <= rob_tag_in;
            end
        end
    end

endmodule
