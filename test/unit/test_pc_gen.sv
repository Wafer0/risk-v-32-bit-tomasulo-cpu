// Unit Test for PC Generator
module test_pc_gen;
    logic clk = 0, rst;
    logic stall, branch_taken, flush;
    logic [31:0] branch_target, correct_pc, pc;

    pc_gen dut (.*);

    always #5 clk = ~clk;

    initial begin
        $display("Testing PC Generator...");

        // Reset
        rst = 1; #10; rst = 0; #10;
        assert(pc == 32'h00000000) else $error("Reset failed");

        // Test normal increment
        @(posedge clk); #1;
        // PC should increment after reset

        // Test stall
        stall = 1;
        logic [31:0] pc_before_stall = pc;
        @(posedge clk); #1;
        assert(pc == pc_before_stall) else $error("PC stall failed");

        // Test branch taken
        stall = 0; branch_taken = 1; branch_target = 32'h00001000;
        @(posedge clk); #1;
        assert(pc == 32'h00001000) else $error("Branch taken failed");

        // Test flush (highest priority)
        flush = 1; correct_pc = 32'h00002000;
        @(posedge clk); #1;
        assert(pc == 32'h00002000) else $error("Flush failed");

        $display("OK: PC Generator tests passed");
        $finish;
    end
endmodule

