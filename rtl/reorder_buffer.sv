// reorder_buffer.sv
// Reorder Buffer
// Enables in-order commit and precise exceptions

module reorder_buffer (
    input logic clk,
    input logic rst,
    input logic rob_we,
    input logic [4:0] rob_tail_in,
    input logic [4:0] rd,
    input logic [31:0] pc,
    input logic [2:0] inst_type,
    input logic [4:0] cdb_tag,
    input logic [31:0] cdb_value,
    input logic cdb_valid,
    input logic flush,
    input logic [31:0] flush_pc,
    output logic [4:0] rob_head,
    output logic [4:0] commit_rd,
    output logic [31:0] commit_value,
    output logic commit_valid,
    output logic full
);

    logic [15:0] valid;
    logic [4:0] rd_arr [0:15];
    logic [31:0] value_arr [0:15];
    logic [31:0] pc_arr [0:15];
    logic [2:0] inst_type_arr [0:15];
    logic [4:0] head_ptr, tail_ptr;

    assign rob_head = head_ptr;
    assign full = ((tail_ptr + 1) % 16) == head_ptr;

    // Commit logic
    always_comb begin
        commit_valid = valid[head_ptr] && !flush;
        commit_rd = rd_arr[head_ptr];
        commit_value = value_arr[head_ptr];
    end

    // ROB update
    always_ff @(posedge clk) begin
        if (rst || flush) begin
            head_ptr <= 5'b0;
            tail_ptr <= 5'b0;
            valid <= 16'b0;
            for (int i = 0; i < 16; i++) begin
                rd_arr[i] <= 5'b0;
                value_arr[i] <= 32'b0;
                pc_arr[i] <= 32'b0;
                inst_type_arr[i] <= 3'b0;
            end
        end else begin
            // CDB completion - update ROB entry with result
            if (cdb_valid) begin
                valid[cdb_tag] <= 1'b1;
                value_arr[cdb_tag] <= cdb_value;
            end

            // Dispatch allocation - allocate new ROB entry
            if (rob_we) begin
                rd_arr[rob_tail_in] <= rd;
                pc_arr[rob_tail_in] <= pc;
                inst_type_arr[rob_tail_in] <= inst_type;
                valid[rob_tail_in] <= 1'b0;  // Not ready yet
                tail_ptr <= (rob_tail_in + 1) % 16;
            end

            // Commit - advance head pointer when entry is valid
            if (commit_valid) begin
                valid[head_ptr] <= 1'b0;  // Clear valid bit after commit
                head_ptr <= (head_ptr + 1) % 16;
            end
        end
    end

endmodule
