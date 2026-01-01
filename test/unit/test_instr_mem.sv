// Unit Test for Instruction Memory
module test_instr_mem;
    logic [31:0] addr, instruction;

    instr_mem #(.MEM_SIZE(1024)) dut (.*);

    initial begin
        $display("Testing Instruction Memory...");

        // Test default NOP
        addr = 32'h0;
        #1;
        assert(instruction == 32'h00000013) else $error("Default NOP failed");

        // Test word alignment
        addr = 32'h4;
        #1;
        assert(instruction == 32'h00000013) else $error("Word alignment failed");

        // Test out of bounds
        addr = 32'h10000;
        #1;
        assert(instruction == 32'h00000013) else $error("Out of bounds failed");

        $display("OK: Instruction Memory tests passed");
        $finish;
    end
endmodule

