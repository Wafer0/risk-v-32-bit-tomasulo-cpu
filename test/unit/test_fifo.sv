// Unit Test for FIFO
module test_fifo;
    logic clk = 0, rst;
    logic wr_en, rd_en;
    logic [31:0] wr_data, rd_data;
    logic full, empty, error;
    
    fifo #(.DEPTH(8), .WIDTH(32)) dut (.*);
    
    always #5 clk = ~clk;
    
    initial begin
        $display("Testing FIFO...");
        
        // Reset
        rst = 1; #10; rst = 0; #10;
        assert(empty && !full) else $error("Reset failed");
        
        // Test write
        wr_data = 32'hDEADBEEF; wr_en = 1; rd_en = 0;
        @(posedge clk); #1;
        assert(!empty) else $error("Write failed - still empty");
        
        // Test read
        wr_en = 0; rd_en = 1;
        @(posedge clk); #1;
        assert(rd_data == 32'hDEADBEEF) else $error("Read failed");
        assert(empty) else $error("Read failed - not empty");
        
        // Test multiple writes
        wr_en = 1; rd_en = 0;
        wr_data = 32'h11111111; @(posedge clk); #1;
        wr_data = 32'h22222222; @(posedge clk); #1;
        wr_data = 32'h33333333; @(posedge clk); #1;
        
        // Test reads in order
        wr_en = 0; rd_en = 1;
        @(posedge clk); #1;
        assert(rd_data == 32'h11111111) else $error("FIFO order failed 1");
        @(posedge clk); #1;
        assert(rd_data == 32'h22222222) else $error("FIFO order failed 2");
        @(posedge clk); #1;
        assert(rd_data == 32'h33333333) else $error("FIFO order failed 3");
        
        // Test full condition
        wr_en = 1; rd_en = 0;
        repeat(8) begin
            wr_data = $random;
            @(posedge clk); #1;
        end
        assert(full) else $error("Full flag failed");
        
        // Test overflow error
        wr_data = 32'hFFFFFFFF;
        @(posedge clk); #1;
        assert(error) else $error("Overflow error not detected");
        
        $display("OK: FIFO tests passed");
        $finish;
    end
endmodule

