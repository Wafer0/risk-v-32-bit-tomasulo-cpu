// Unit Test for ALU
module test_alu;
    logic [31:0] a, b, result;
    logic [3:0] op;
    logic zero;
    
    alu dut (.*);
    
    initial begin
        $display("Testing ALU...");
        
        // Test ADD
        a = 10; b = 20; op = 4'b0000;
        #1; 
        $display("ADD: a=%0d b=%0d result=%0d (expected 30)", a, b, result);
        assert(result == 30) else $error("ADD failed");
        
        // Test SUB
        a = 50; b = 30; op = 4'b0001;
        #1; 
        $display("SUB: a=%0d b=%0d result=%0d (expected 20)", a, b, result);
        assert(result == 20) else $error("SUB failed");
        
        // Test AND
        a = 32'hFF; b = 32'h0F; op = 4'b0010;
        #1; 
        $display("AND: a=%h b=%h result=%h (expected 0xF)", a, b, result);
        assert(result == 32'h0F) else $error("AND failed");
        
        // Test OR
        a = 32'hF0; b = 32'h0F; op = 4'b0011;
        #1;
        $display("OR: a=%h b=%h result=%h (expected 0xFF)", a, b, result);
        assert(result == 32'hFF) else $error("OR failed");
        
        // Test XOR
        a = 32'hFF; b = 32'h0F; op = 4'b0100;
        #1; 
        $display("XOR: a=%h b=%h result=%h (expected 0xF0)", a, b, result);
        assert(result == 32'hF0) else $error("XOR failed");
        
        // Test SLL (shift left)
        a = 32'h1; b = 32'h4; op = 4'b0101;
        #1; 
        $display("SLL: a=%h b=%h result=%h (expected 0x10)", a, b, result);
        assert(result == 32'h10) else $error("SLL failed");
        
        // Test SRL (shift right logical)
        a = 32'h10; b = 32'h2; op = 4'b0110;
        #1; 
        $display("SRL: a=%h b=%h result=%h (expected 0x4)", a, b, result);
        assert(result == 32'h4) else $error("SRL failed");
        
        // Test SLT (set less than)
        a = -5; b = 10; op = 4'b0111;
        #1;
        $display("SLT: a=%d b=%d result=%d (expected 1)", $signed(a), $signed(b), result);
        assert(result == 1) else $error("SLT failed");
        
        // Test zero flag
        a = 5; b = 5; op = 4'b0001;  // SUB
        #1; 
        $display("ZERO: a=%d b=%d result=%d zero=%b (expected 0, 1)", a, b, result, zero);
        assert(zero == 1) else $error("Zero flag failed");
        
        $display("OK: ALU tests passed");
        $finish;
    end
endmodule

