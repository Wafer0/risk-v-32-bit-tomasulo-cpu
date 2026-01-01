// pc_gen.sv
// Program Counter generator
// Handles PC increments, stalls, branch predictions, and misprediction recovery

module pc_gen (
    input logic clk,
    input logic rst,
    input logic stall,
    input logic branch_taken,
    input logic [31:0] branch_target,
    input logic flush,
    input logic [31:0] correct_pc,
    input logic stop_fetch,  // Stop fetching when program completes
    output logic [31:0] pc
);

    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 32'h00000000;
        end else if (flush) begin
            pc <= correct_pc;
        end else if (!stall && !stop_fetch) begin
            if (branch_taken) begin
                pc <= branch_target;
            end else begin
                pc <= pc + 4;
            end
        end
    end

endmodule
