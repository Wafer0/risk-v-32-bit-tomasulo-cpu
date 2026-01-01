// Unit Test for Instruction Fetch Queue
module test_ifq;
    logic clk = 0, rst;
    logic wr_en, rd_en, flush;
    logic [31:0] instruction_in, instruction_out;
    logic [31:0] pc_in, pc_out;
    logic empty, full;

    ifq dut (.*);

    always #5 clk = ~clk;

    initial begin
        $display("Testing Instruction Fetch Queue...");

        // Reset
        rst = 1; #10; rst = 0; #10;
        assert(empty && !full) else $error("Reset failed");

        // Test write
        wr_en = 1; rd_en = 0;
        instruction_in = 32'h00500093; pc_in = 32'h00000000;
        @(posedge clk); #1;
        assert(!empty) else $error("Write failed");

        // Test read
        wr_en = 0; rd_en = 1;
        @(posedge clk); #1;
        assert(instruction_out == 32'h00500093 && pc_out == 32'h00000000)
            else $error("Read failed");

        // Test flush
        wr_en = 1; rd_en = 0;
        instruction_in = 32'h00A00113; pc_in = 32'h00000004;
        @(posedge clk); #1;
        flush = 1;
        @(posedge clk); #1;
        assert(empty) else $error("Flush failed");

        $display("OK: Instruction Fetch Queue tests passed");
        $finish;
    end
endmodule

