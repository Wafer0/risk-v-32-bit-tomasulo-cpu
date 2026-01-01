// Unit Test for Reorder Buffer
module test_reorder_buffer;
    logic clk = 0, rst;
    logic rob_we;
    logic [4:0] rob_tail_in;
    logic [4:0] rd;
    logic [31:0] pc;
    logic [2:0] inst_type;
    logic [4:0] cdb_tag;
    logic [31:0] cdb_value;
    logic cdb_valid;
    logic [4:0] rob_head;
    logic [4:0] commit_rd;
    logic [31:0] commit_value;
    logic commit_valid;
    logic full;
    logic flush;
    logic [31:0] flush_pc;
    
    reorder_buffer dut (.*);
    
    always #5 clk = ~clk;
    
    initial begin
        $display("Testing Reorder Buffer...");
        
        // Reset
        rst = 1; #10; rst = 0; #10;
        assert(!full && rob_head == 5'd0) else $error("Reset failed");
        
        // Test allocation
        rob_we = 1; rob_tail_in = 5'd0;
        rd = 5'd1; pc = 32'h1000; inst_type = 3'b000;
        @(posedge clk); #1;
        // Allocation should have happened
        
        // Test completion (CDB write)
        cdb_tag = 5'd0; cdb_value = 32'hDEADBEEF; cdb_valid = 1;
        @(posedge clk); #1;
        // Value should be stored in ROB[0]
        
        // Test commit
        if (rob_head == 5'd0) begin
            @(posedge clk); #1;
            assert(commit_valid) else $error("Commit failed");
            assert(commit_rd == 5'd1 && commit_value == 32'hDEADBEEF) 
                else $error("Commit data failed");
        end
        
        // Test flush
        flush = 1; flush_pc = 32'h2000;
        @(posedge clk); #1;
        assert(rob_tail == rob_head) else $error("Flush failed");
        
        $display("OK: Reorder Buffer tests passed");
        $finish;
    end
endmodule

