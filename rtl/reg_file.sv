// reg_file.sv
// Physical Register File
// Architectural state - only updated upon commit from ROB

module reg_file (
    input logic clk,
    input logic rst,
    input logic reg_write,
    input logic [4:0] read_addr1,
    input logic [4:0] read_addr2,
    input logic [4:0] write_addr,
    input logic [31:0] write_data,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);

    logic [31:0] registers [0:31];

    // Read ports (combinational)
    assign read_data1 = (read_addr1 == 5'b0) ? 32'b0 : registers[read_addr1];
    assign read_data2 = (read_addr2 == 5'b0) ? 32'b0 : registers[read_addr2];

    // Write port (synchronous)
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'b0;
            end
        end else if (reg_write && write_addr != 5'b0) begin
            registers[write_addr] <= write_data;
        end
    end

endmodule
