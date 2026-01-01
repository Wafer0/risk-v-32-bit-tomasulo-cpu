// fifo.sv
// Generic synchronous FIFO for instruction fetch queue

module fifo #(
    parameter int DEPTH = 32,
    parameter int WIDTH = 32
)(
    input logic clk,
    input logic rst,
    input logic wr_en,
    input logic [WIDTH-1:0] wr_data,
    input logic rd_en,
    output logic [WIDTH-1:0] rd_data,
    output logic full,
    output logic empty,
    output logic error
);

logic [$clog2(DEPTH)-1:0] rd_ptr;
logic [$clog2(DEPTH)-1:0] wr_ptr;
logic [WIDTH-1:0] mem [0:DEPTH-1];
logic [$clog2(DEPTH):0] count;
logic [WIDTH-1:0] rd_data_reg;

assign empty = (count == 0);
assign full = (count == DEPTH);
// For peek functionality, always output current head when not empty
assign rd_data = empty ? '0 : mem[rd_ptr];

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        rd_ptr <= '0;
        wr_ptr <= '0;
        count <= '0;
        error <= '0;
        rd_data_reg <= '0;
    end else begin
        error <= '0;

        case ({wr_en, rd_en})
            2'b10: begin
                if(!full) begin
                    mem[wr_ptr] <= wr_data;
                    wr_ptr <= (wr_ptr + 1) % DEPTH;
                    count <= count + 1;
                end else begin
                    error <= 1'b1;
                end
            end

            2'b01: begin
                if(!empty) begin
                    rd_data_reg <= mem[rd_ptr];
                    rd_ptr <= (rd_ptr + 1) % DEPTH;
                    count <= count - 1;
                end else begin
                    error <= 1'b1;
                end
            end

            2'b11: begin
                if(!empty && !full) begin
                    mem[wr_ptr] <= wr_data;
                    wr_ptr <= (wr_ptr + 1) % DEPTH;
                    rd_data_reg <= mem[rd_ptr];
                    rd_ptr <= (rd_ptr + 1) % DEPTH;
                end else if(!full) begin
                    mem[wr_ptr] <= wr_data;
                    wr_ptr <= (wr_ptr + 1) % DEPTH;
                    count <= count + 1;
                end else if(!empty) begin
                    rd_data_reg <= mem[rd_ptr];
                    rd_ptr <= (rd_ptr + 1) % DEPTH;
                    count <= count - 1;
                end
            end

            default: begin
                // Do nothing
            end
        endcase
    end
end

endmodule
