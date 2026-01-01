// branch_unit.sv
// Branch Unit
// Evaluates branch conditions and calculates targets

module branch_unit (
    input logic [31:0] rs1_val,
    input logic [31:0] rs2_val,
    input logic [31:0] pc,
    input logic [31:0] imm,
    input logic [2:0] branch_type,
    input logic predicted_taken,
    input logic [31:0] predicted_target,
    output logic taken,
    output logic [31:0] target,
    output logic mispredict,
    output logic [31:0] correct_pc
);

    logic condition_met;

    // Evaluate condition
    always_comb begin
        condition_met = 1'b0;  // Default value

        // Special case: JAL (encoded as 3'b111 in test)
        if (branch_type == 3'b111) begin
            taken = 1'b1;
            target = pc + imm;
        end else begin
            case (branch_type)
                3'b000: condition_met = (rs1_val == rs2_val);  // BEQ
                3'b001: condition_met = (rs1_val != rs2_val);  // BNE
                3'b100: condition_met = ($signed(rs1_val) < $signed(rs2_val));  // BLT
                3'b101: condition_met = ($signed(rs1_val) >= $signed(rs2_val)); // BGE
                3'b110: condition_met = (rs1_val < rs2_val);   // BLTU
                default: condition_met = 1'b0;
            endcase

            taken = condition_met;
            target = taken ? (pc + imm) : (pc + 4);
        end

        // Misprediction detection
        mispredict = (predicted_taken != taken) || (predicted_target != target);
        correct_pc = target;
    end

endmodule
