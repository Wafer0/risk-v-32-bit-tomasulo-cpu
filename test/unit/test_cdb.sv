// Unit Test for Common Data Bus
module test_cdb;
    logic alu_req, branch_req, lsu_req;
    logic [4:0] alu_tag, branch_tag, lsu_tag;
    logic [31:0] alu_value, branch_value, lsu_value;
    logic cdb_valid;
    logic [4:0] cdb_tag;
    logic [31:0] cdb_value;

    cdb dut (.*);

    initial begin
        $display("Testing Common Data Bus...");

        // Test no requests
        alu_req = 0; branch_req = 0; lsu_req = 0;
        #1;
        assert(!cdb_valid) else $error("No request failed");

        // Test branch priority (highest)
        branch_req = 1; branch_tag = 5'd1; branch_value = 32'h11111111;
        alu_req = 1; alu_tag = 5'd2; alu_value = 32'h22222222;
        lsu_req = 1; lsu_tag = 5'd3; lsu_value = 32'h33333333;
        #1;
        assert(cdb_valid && cdb_tag == 5'd1 && cdb_value == 32'h11111111)
            else $error("Branch priority failed");

        // Test ALU priority (second)
        branch_req = 0;
        #1;
        assert(cdb_valid && cdb_tag == 5'd2 && cdb_value == 32'h22222222)
            else $error("ALU priority failed");

        // Test LSU priority (lowest)
        alu_req = 0;
        #1;
        assert(cdb_valid && cdb_tag == 5'd3 && cdb_value == 32'h33333333)
            else $error("LSU priority failed");

        $display("OK: Common Data Bus tests passed");
        $finish;
    end
endmodule

