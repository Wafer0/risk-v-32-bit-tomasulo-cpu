// instr_mem.sv
// Instruction Memory (ROM/RAM wrapper)

module instr_mem #(
    parameter int MEM_SIZE = 128
)(
    input logic [31:0] addr,
    output logic [31:0] instruction
);

    logic [31:0] mem [0:MEM_SIZE-1];
    integer i;

    initial begin
        // Initialize with NOPs
        for (i = 0; i < MEM_SIZE; i++) begin
            mem[i] = 32'h00000013; // NOP (ADDI x0, x0, 0)
        end
        // Load program from hex file
        `ifndef SYNTHESIS
        `ifdef PROGRAM_FILE
        $readmemh(`PROGRAM_FILE, mem);
        `endif
        `endif
    end

    assign instruction = (addr[31:2] < MEM_SIZE) ? mem[addr[31:2]] : 32'h00000013;

endmodule
