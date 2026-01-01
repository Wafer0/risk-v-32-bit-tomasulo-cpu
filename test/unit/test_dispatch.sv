// Unit Test for Dispatch Unit
module test_dispatch;
    logic clk = 0, rst;
    logic [31:0] instruction, pc;
    logic rs1_valid, rs2_valid;
    logic [4:0] rs1_tag, rs2_tag;
    logic [31:0] rs1_val, rs2_val;
    logic rob_full, rs_full;
    logic [4:0] rob_tail;
    logic [2:0] rs_slot;
    logic rob_we, rs_we, rat_we, ifq_rd_en, stall;

    dispatch dut (.*);

    always #5 clk = ~clk;

    initial begin
        $display("Testing Dispatch Unit...");

        // Reset
        rst = 1; #10; rst = 0; #10;

        // Test no stall (resources available)
        rob_full = 0; rs_full = 0;
        #1;
        assert(!stall && rob_we && rs_we && rat_we && ifq_rd_en)
            else $error("No stall failed");

        // Test stall (ROB full)
        rob_full = 1; rs_full = 0;
        #1;
        assert(stall && !rob_we && !rs_we && !rat_we && !ifq_rd_en)
            else $error("ROB full stall failed");

        // Test stall (RS full)
        rob_full = 0; rs_full = 1;
        #1;
        assert(stall && !rob_we && !rs_we && !rat_we && !ifq_rd_en)
            else $error("RS full stall failed");

        $display("OK: Dispatch Unit tests passed");
        $finish;
    end
endmodule

