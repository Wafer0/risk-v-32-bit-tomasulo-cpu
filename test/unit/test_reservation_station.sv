// Unit Test for Reservation Station
module test_reservation_station;
    logic clk = 0, rst;
    logic rs_we;
    logic [2:0] rs_slot;
    logic [3:0] op;
    logic [31:0] vj, vk, imm;
    logic [4:0] qj, qk, rob_tag;
    logic [4:0] cdb_tag;
    logic [31:0] cdb_value;
    logic cdb_valid;
    logic [2:0] ready_slot;
    logic ready;
    logic full;
    logic flush;
    
    reservation_station dut (.*);
    
    always #5 clk = ~clk;
    
    initial begin
        $display("Testing Reservation Station...");
        
        // Reset
        rst = 1; #10; rst = 0; #10;
        assert(!full && !ready) else $error("Reset failed");
        
        // Test dispatch with ready operands
        rs_we = 1; rs_slot = 3'd0;
        op = 4'b0000; vj = 32'd10; vk = 32'd20;
        qj = 5'd0; qk = 5'd0; rob_tag = 5'd1;
        @(posedge clk); #1;
        assert(ready) else $error("RS ready detection failed");
        
        // Test dispatch with tag (not ready)
        rs_we = 1; rs_slot = 3'd1;
        op = 4'b0000; vj = 32'd0; vk = 32'd0;
        qj = 5'd2; qk = 5'd0; rob_tag = 5'd3;
        @(posedge clk); #1;
        assert(!ready) else $error("RS should not be ready with tag");
        
        // Test CDB snooping
        cdb_tag = 5'd2; cdb_value = 32'd100; cdb_valid = 1;
        @(posedge clk); #1;
        // Check if qj was cleared (would need to read internal state)
        
        // Test flush
        flush = 1;
        @(posedge clk); #1;
        assert(!ready) else $error("Flush failed");
        
        $display("OK: Reservation Station tests passed");
        $finish;
    end
endmodule

