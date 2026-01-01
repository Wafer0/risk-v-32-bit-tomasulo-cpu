// Unit Test for Issue Queue
module test_issue_queue;
    logic clk = 0, rst, flush;
    logic empty;

    issue_queue dut (.*);

    always #5 clk = ~clk;

    initial begin
        $display("Testing Issue Queue...");

        // Reset
        rst = 1; #10; rst = 0; #10;
        assert(empty) else $error("Reset failed");

        // Test flush
        flush = 1;
        @(posedge clk); #1;
        assert(empty) else $error("Flush failed");

        $display("OK: Issue Queue tests passed");
        $finish;
    end
endmodule

