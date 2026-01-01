// Unit Test for Register Alias Table (RAT)
module test_rat;
    logic clk = 0, rst;
    logic [4:0] rs1, rs2, rd;
    logic rat_we;
    logic [4:0] rob_tag_in;
    logic [4:0] cdb_tag;
    logic cdb_valid;
    logic rs1_valid, rs2_valid;
    logic [4:0] rs1_tag, rs2_tag;
    logic flush;
    
    rat dut (.*);
    
    always #5 clk = ~clk;
    
    initial begin
        $display("Testing RAT...");
        
        // Reset
        rst = 1; #10; rst = 0; #10;
        rs1 = 5'd1; rs2 = 5'd2;
        #1;
        assert(!rs1_valid && !rs2_valid) else $error("Reset failed");
        
        // Test write (dispatch)
        rd = 5'd1; rob_tag_in = 5'd5; rat_we = 1;
        @(posedge clk); #1;
        rs1 = 5'd1;
        #1;
        assert(rs1_valid && rs1_tag == 5'd5) else $error("RAT write failed");
        
        // Test CDB update
        cdb_tag = 5'd5; cdb_valid = 1;
        @(posedge clk); #1;
        rs1 = 5'd1;
        #1;
        assert(!rs1_valid) else $error("CDB update failed");
        
        // Test x0 never renamed
        rd = 5'd0; rob_tag_in = 5'd10; rat_we = 1;
        @(posedge clk); #1;
        rs1 = 5'd0;
        #1;
        assert(!rs1_valid) else $error("x0 renamed (should not happen)");
        
        // Test flush
        rd = 5'd2; rob_tag_in = 5'd7; rat_we = 1;
        @(posedge clk); #1;
        rs2 = 5'd2;
        #1;
        assert(rs2_valid) else $error("RAT write before flush failed");
        flush = 1;
        @(posedge clk); #1;
        rs2 = 5'd2;
        #1;
        assert(!rs2_valid) else $error("Flush failed");
        
        $display("OK: RAT tests passed");
        $finish;
    end
endmodule

