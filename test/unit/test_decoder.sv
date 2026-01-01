// Unit Test for Decoder
module test_decoder;
    logic [31:0] instruction;
    logic [6:0] opcode;
    logic [4:0] rs1, rs2, rd;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [31:0] imm;
    logic [1:0] imm_type;
    
    decoder dut (.*);
    
    initial begin
        $display("Testing Decoder...");
        
        // Test R-type (ADD: add x1, x2, x3)
        instruction = 32'b0000000_00011_00010_000_00001_0110011;
        #1;
        assert(opcode == 7'b0110011) else $error("R-type opcode failed");
        assert(rs1 == 5'd2 && rs2 == 5'd3 && rd == 5'd1) else $error("R-type regs failed");
        assert(funct3 == 3'b000 && funct7 == 7'b0000000) else $error("R-type funct failed");
        
        // Test I-type (ADDI: addi x1, x2, 10)
        instruction = 32'b000000001010_00010_000_00001_0010011;
        #1;
        assert(opcode == 7'b0010011) else $error("I-type opcode failed");
        assert(rs1 == 5'd2 && rd == 5'd1) else $error("I-type regs failed");
        assert(imm == 32'd10) else $error("I-type imm failed");
        
        // Test S-type (SW: sw x3, 4(x2))
        instruction = 32'b0000000_00011_00010_010_00100_0100011;
        #1;
        assert(opcode == 7'b0100011) else $error("S-type opcode failed");
        assert(rs1 == 5'd2 && rs2 == 5'd3) else $error("S-type regs failed");
        assert(imm == 32'd4) else $error("S-type imm failed");
        
        // Test B-type (BEQ: beq x1, x2, label)
        instruction = 32'b0_000000_00010_00001_000_0000_0_1100011;
        #1;
        assert(opcode == 7'b1100011) else $error("B-type opcode failed");
        assert(rs1 == 5'd1 && rs2 == 5'd2) else $error("B-type regs failed");
        
        // Test U-type (LUI: lui x1, 0x12345)
        instruction = 32'b0001_0010_0011_0100_0101_00001_0110111;
        #1;
        assert(opcode == 7'b0110111) else $error("U-type opcode failed");
        assert(rd == 5'd1) else $error("U-type rd failed");
        
        // Test J-type (JAL: jal x1, label)
        instruction = 32'b0_0000000010_0_00000001_00001_1101111;
        #1;
        assert(opcode == 7'b1101111) else $error("J-type opcode failed");
        assert(rd == 5'd1) else $error("J-type rd failed");
        
        $display("OK: Decoder tests passed");
        $finish;
    end
endmodule

