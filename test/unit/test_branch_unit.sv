// Unit Test for Branch Unit
module test_branch_unit;
    logic [31:0] rs1_val, rs2_val, pc, imm;
    logic [2:0] branch_type;
    logic predicted_taken;
    logic [31:0] predicted_target;
    logic taken;
    logic [31:0] target;
    logic mispredict;
    logic [31:0] correct_pc;
    
    branch_unit dut (.*);
    
    initial begin
        $display("Testing Branch Unit...");
        
        // Test BEQ (taken)
        rs1_val = 32'd10; rs2_val = 32'd10;
        pc = 32'h1000; imm = 32'd100;
        branch_type = 3'b000; // BEQ
        predicted_taken = 0; predicted_target = 32'h0;
        #1;
        assert(taken) else $error("BEQ taken failed");
        assert(target == 32'h1064) else $error("BEQ target failed"); // PC + imm
        
        // Test BEQ (not taken)
        rs1_val = 32'd10; rs2_val = 32'd20;
        #1;
        assert(!taken) else $error("BEQ not taken failed");
        
        // Test BNE
        rs1_val = 32'd10; rs2_val = 32'd20;
        branch_type = 3'b001; // BNE
        #1;
        assert(taken) else $error("BNE taken failed");
        
        // Test BLT (signed)
        rs1_val = -5; rs2_val = 10;
        branch_type = 3'b100; // BLT
        #1;
        assert(taken) else $error("BLT taken failed");
        
        // Test JAL
        branch_type = 3'b111; // JAL (special encoding)
        #1;
        assert(taken) else $error("JAL always taken failed");
        
        // Test misprediction
        predicted_taken = 0; predicted_target = 32'h1100;
        rs1_val = 32'd10; rs2_val = 32'd10;
        branch_type = 3'b000; // BEQ
        #1;
        assert(mispredict) else $error("Misprediction detection failed");
        
        $display("OK: Branch Unit tests passed");
        $finish;
    end
endmodule

