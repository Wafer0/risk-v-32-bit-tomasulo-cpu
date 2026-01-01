// Unit Test for Register File
module test_reg_file;
    logic clk = 0, rst;
    logic reg_write;
    logic [4:0] read_addr1, read_addr2, write_addr;
    logic [31:0] write_data, read_data1, read_data2;
    
    reg_file dut (.*);
    
    always #5 clk = ~clk;
    
    initial begin
        $display("Testing Register File...");
        
        // Reset
        rst = 1; #10; rst = 0; #10;
        
        // Test write and read
        write_addr = 5'd1; write_data = 32'hDEADBEEF; reg_write = 1;
        @(posedge clk); #1;
        read_addr1 = 5'd1;
        #1; assert(read_data1 == 32'hDEADBEEF) else $error("Write/Read failed");
        
        // Test x0 always zero
        write_addr = 5'd0; write_data = 32'hFFFFFFFF; reg_write = 1;
        @(posedge clk); #1;
        read_addr1 = 5'd0;
        #1; assert(read_data1 == 32'h0) else $error("x0 not zero");
        
        // Test dual read ports
        write_addr = 5'd2; write_data = 32'h12345678; reg_write = 1;
        @(posedge clk); #1;
        read_addr1 = 5'd1; read_addr2 = 5'd2;
        #1; 
        assert(read_data1 == 32'hDEADBEEF) else $error("Dual read port 1 failed");
        assert(read_data2 == 32'h12345678) else $error("Dual read port 2 failed");
        
        $display("OK: Register File tests passed");
        $finish;
    end
endmodule

