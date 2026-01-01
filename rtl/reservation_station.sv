// reservation_station.sv
// Reservation Stations
// Stores instructions waiting for operands, snoops CDB

module reservation_station (
    input logic clk,
    input logic rst,
    input logic rs_we,
    input logic [2:0] rs_slot,
    input logic [3:0] op,
    input logic [6:0] opcode,
    input logic [31:0] vj,
    input logic [31:0] vk,
    input logic [31:0] imm,
    input logic [4:0] qj,
    input logic [4:0] qk,
    input logic [4:0] rob_tag,
    input logic [4:0] cdb_tag,
    input logic [31:0] cdb_value,
    input logic cdb_valid,
    input logic flush,
    input logic execute_clear,  // Signal to clear busy bit when instruction executes
    input logic [2:0] execute_slot,  // Slot being executed
    output logic [2:0] ready_slot,
    output logic ready,
    output logic full,
    // Outputs for ready instruction
    output logic [3:0] ready_op,
    output logic [6:0] ready_opcode,
    output logic [31:0] ready_vj,
    output logic [31:0] ready_vk,
    output logic [31:0] ready_imm,
    output logic [4:0] ready_rob_tag,
    // Output for free slot detection
    output logic [2:0] free_slot
);

    logic [7:0] busy;
    logic [3:0] op_arr [0:7];
    logic [6:0] opcode_arr [0:7];
    logic [31:0] vj_arr [0:7], vk_arr [0:7];
    logic [4:0] qj_arr [0:7], qk_arr [0:7];
    logic [4:0] rob_tag_arr [0:7];
    logic [31:0] imm_arr [0:7];
    logic [7:0] ready_vec;

    // Ready detection
    always_comb begin
        ready = 1'b0;
        ready_slot = 3'b0;
        ready_vec = 8'b0;

        for (int i = 0; i < 8; i++) begin
            ready_vec[i] = busy[i] && (qj_arr[i] == 5'b0) && (qk_arr[i] == 5'b0);
            if (ready_vec[i] && !ready) begin
                ready = 1'b1;
                ready_slot = i[2:0];
            end
        end

        full = &busy;
        
        // Find first free slot
        free_slot = 3'b0;
        for (int i = 0; i < 8; i++) begin
            if (!busy[i] && free_slot == 3'b0) begin
                free_slot = i[2:0];
            end
        end
        
        // Output ready instruction data
        if (ready) begin
            ready_op = op_arr[ready_slot];
            ready_opcode = opcode_arr[ready_slot];
            ready_vj = vj_arr[ready_slot];
            ready_vk = vk_arr[ready_slot];
            ready_imm = imm_arr[ready_slot];
            ready_rob_tag = rob_tag_arr[ready_slot];
        end else begin
            ready_op = 4'b0;
            ready_opcode = 7'b0;
            ready_vj = 32'b0;
            ready_vk = 32'b0;
            ready_imm = 32'b0;
            ready_rob_tag = 5'b0;
        end
    end

    // CDB snooping and update
    always_ff @(posedge clk) begin
        if (rst || flush) begin
            busy <= 8'b0;
            for (int i = 0; i < 8; i++) begin
                op_arr[i] <= 4'b0;
                opcode_arr[i] <= 7'b0;
                vj_arr[i] <= 32'b0;
                vk_arr[i] <= 32'b0;
                qj_arr[i] <= 5'b0;
                qk_arr[i] <= 5'b0;
                rob_tag_arr[i] <= 5'b0;
                imm_arr[i] <= 32'b0;
            end
        end else begin
            // CDB snooping
            if (cdb_valid) begin
                for (int i = 0; i < 8; i++) begin
                    if (busy[i]) begin
                        if (qj_arr[i] == cdb_tag) begin
                            vj_arr[i] <= cdb_value;
                            qj_arr[i] <= 5'b0;
                        end
                        if (qk_arr[i] == cdb_tag) begin
                            vk_arr[i] <= cdb_value;
                            qk_arr[i] <= 5'b0;
                        end
                    end
                end
            end

            // Clear busy bit when instruction executes
            if (execute_clear) begin
                busy[execute_slot] <= 1'b0;
            end

            // Dispatch write
            if (rs_we) begin
                busy[rs_slot] <= 1'b1;
                op_arr[rs_slot] <= op;
                opcode_arr[rs_slot] <= opcode;
                vj_arr[rs_slot] <= vj;
                vk_arr[rs_slot] <= vk;
                qj_arr[rs_slot] <= qj;
                qk_arr[rs_slot] <= qk;
                rob_tag_arr[rs_slot] <= rob_tag;
                imm_arr[rs_slot] <= imm;
            end
        end
    end

endmodule
