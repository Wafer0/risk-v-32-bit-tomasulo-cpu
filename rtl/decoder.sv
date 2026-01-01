// decoder.sv
// Instruction Decoder
// Decodes 32-bit RISC-V instructions into control signals and immediate values

module decoder (
    input logic [31:0] instruction,
    output logic [6:0] opcode,
    output logic [4:0] rs1, rs2, rd,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic [31:0] imm,
    output logic [1:0] imm_type
);

    // Extract fields
    assign opcode = instruction[6:0];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign funct7 = instruction[31:25];

    // Immediate generation based on instruction type
    always_comb begin
        imm_type = 2'b00;
        imm = 32'b0;

        case (opcode)
            7'b0010011, 7'b0000011, 7'b1100111: begin // I-type
                imm_type = 2'b01;
                imm = {{20{instruction[31]}}, instruction[31:20]};
            end
            7'b0100011: begin // S-type
                imm_type = 2'b10;
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            7'b1100011: begin // B-type
                imm_type = 2'b11;
                imm = {{20{instruction[31]}}, instruction[7],
                       instruction[30:25], instruction[11:8], 1'b0};
            end
            7'b0110111, 7'b0010111: begin // U-type
                imm = {instruction[31:12], 12'b0};
            end
            7'b1101111: begin // J-type
                imm = {{12{instruction[31]}}, instruction[19:12],
                       instruction[20], instruction[30:21], 1'b0};
            end
            default: imm = 32'b0;
        endcase
    end

endmodule
