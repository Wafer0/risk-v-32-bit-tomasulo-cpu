// Unit Test for Load/Store Unit
module test_lsu;
    logic clk = 0, rst;
    logic [31:0] base_addr, offset, store_data;
    logic [2:0] mem_op;
    logic mem_req;
    logic [31:0] mem_rdata;
    logic [31:0] mem_addr;
    logic mem_we, mem_re;
    logic [31:0] load_data;
    logic ready;

    lsu dut (.*);

    always #5 clk = ~clk;

    initial begin
        $display("Testing Load/Store Unit...");

        // Reset
        rst = 1; #10; rst = 0; #10;

        // Test address calculation
        base_addr = 32'h1000; offset = 32'h100;
        #1;
        assert(mem_addr == 32'h1100) else $error("Address calculation failed");

        // Test store request
        mem_req = 1; mem_op = 3'b100; // Store (bit 2 = 1)
        #1;
        assert(mem_we && !mem_re) else $error("Store request failed");

        // Test load request
        mem_req = 1; mem_op = 3'b000; // Load
        mem_rdata = 32'hDEADBEEF;
        #1;
        assert(!mem_we && mem_re) else $error("Load request failed");
        assert(load_data == 32'hDEADBEEF) else $error("Load data failed");

        // Test ready signal
        assert(ready) else $error("Ready signal failed");

        $display("OK: Load/Store Unit tests passed");
        $finish;
    end
endmodule

