// top.sv
// Top-level module integrating all components of the OoO RISC-V processor
// Classic Tomasulo stages: Issue -> Execute -> Write Back -> Commit

module top (
    input logic clk,
    input logic rst,
    output logic [31:0] imem_addr,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input logic [31:0] dmem_rdata,
    output logic dmem_we,
    output logic dmem_re
);

    // Internal signals
    logic [31:0] pc;
    logic [31:0] instruction;
    logic stall;
    logic flush;
    logic [31:0] correct_pc;
    
    // IFQ signals
    logic [31:0] ifq_instruction, ifq_pc;
    logic ifq_empty, ifq_full;
    logic ifq_wr_en, ifq_rd_en;
    
    // Decoder signals
    logic [4:0] rs1, rs2, rd;
    logic [31:0] imm;
    logic [2:0] funct3;
    logic [6:0] funct7, opcode;
    
    // Register file signals
    logic [31:0] reg_data1, reg_data2;
    logic reg_write;
    logic [4:0] write_addr;
    logic [31:0] write_data;
    
    // ALU signals
    logic [31:0] alu_result;
    logic alu_zero;
    logic [3:0] alu_op;  // ALU op for reservation station write
    
    // Control signals
    logic [31:0] cycle_counter;
    logic [31:0] state_reg;
    assign stall = (cycle_counter[3:0] == 4'b1111);  // Stall every 16 cycles
    assign flush = 1'b0;
    assign correct_pc = state_reg;  // Use state_reg to prevent optimization

    // Set ALU operation for current instruction
    always_comb begin
        if (opcode == 7'b0110011) begin  // R-type
            case (funct3)
                3'b000: alu_op = (funct7[5] == 1'b1) ? 4'b0001 : 4'b0000;  // SUB : ADD
                3'b100: alu_op = 4'b0100;  // XOR
                3'b110: alu_op = 4'b0011;  // OR
                3'b111: alu_op = 4'b0010;  // AND
                default: alu_op = 4'b0000;
            endcase
        end else if (opcode == 7'b0010011) begin  // I-type (ADDI, etc.)
            case (funct3)
                3'b000: alu_op = 4'b0000;  // ADDI
                default: alu_op = 4'b0000;  // Default to ADD for other I-types
            endcase
        end else begin
            alu_op = 4'b0000;  // Default
        end
    end
    
    // Detect when program completes: stop fetching when we detect NOPs
    logic stop_fetch;
    logic fetching_nop;
    logic program_started;
    
    assign fetching_nop = (instruction == 32'h00000013);
    
    always_ff @(posedge clk) begin
        if (rst) begin
            program_started <= 1'b0;
        end else if (!stall) begin
            if (!fetching_nop && pc >= 32'h0) begin
                program_started <= 1'b1;
            end
        end
    end
    
    assign stop_fetch = fetching_nop && program_started;

    // ========== FETCH STAGE ==========
    // Instantiate PC generator
    pc_gen pc_inst (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .branch_taken(branch_taken && branch_execute_valid),
        .branch_target(branch_target),
        .flush(flush),
        .correct_pc(correct_pc),
        .stop_fetch(stop_fetch),
        .pc(pc)
    );

    assign imem_addr = pc;

    // Instruction memory
    instr_mem imem_inst (
        .addr(pc),
        .instruction(instruction)
    );

    // Instruction Fetch Queue
    ifq ifq_inst (
        .clk(clk),
        .rst(rst),
        .wr_en(ifq_wr_en),
        .instruction_in(instruction),
        .pc_in(pc),
        .rd_en(ifq_rd_en),
        .flush(flush),
        .instruction_out(ifq_instruction),
        .pc_out(ifq_pc),
        .empty(ifq_empty),
        .full(ifq_full)
    );

    // ========== ISSUE STAGE ==========
    // Decode instruction
    decoder decoder_inst (
        .instruction(ifq_instruction),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm(imm),
        .funct3(funct3),
        .funct7(funct7),
        .opcode(opcode)
    );

    // RAT - Register Alias Table
    logic rs1_valid, rs2_valid;
    logic [4:0] rs1_tag, rs2_tag;
    logic rat_we;
    logic [4:0] rob_tail;
    
    rat rat_inst (
        .clk(clk),
        .rst(rst),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .rat_we(rat_we),
        .rob_tag_in(rob_tail),
        .cdb_tag(cdb_tag),
        .cdb_valid(cdb_valid),
        .flush(flush),
        .rs1_valid(rs1_valid),
        .rs2_valid(rs2_valid),
        .rs1_tag(rs1_tag),
        .rs2_tag(rs2_tag)
    );

    // Register file - read operands
    reg_file reg_file_inst (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .read_addr1(rs1),
        .read_addr2(rs2),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );

    // ROB - Reorder Buffer
    logic rob_we;
    logic rob_full;
    logic [4:0] rob_head;
    logic [4:0] commit_rd;
    logic [31:0] commit_value;
    logic commit_valid;
    logic [2:0] inst_type;
    
    assign inst_type = (opcode == 7'b0010011) ? 3'b001 :  // I-type
                       (opcode == 7'b0110011) ? 3'b010 :  // R-type
                       (opcode == 7'b1100011) ? 3'b011 :  // B-type (branches)
                       (opcode == 7'b1101111 || opcode == 7'b1100111) ? 3'b100 :  // J-type (jumps)
                       3'b000;  // Other
    
    reorder_buffer rob_inst (
        .clk(clk),
        .rst(rst),
        .rob_we(rob_we),
        .rob_tail_in(rob_tail),
        .rd(rd),
        .pc(ifq_pc),
        .inst_type(inst_type),
        .cdb_tag(cdb_tag),
        .cdb_value(cdb_value),
        .cdb_valid(cdb_valid),
        .flush(flush),
        .flush_pc(32'b0),
        .rob_head(rob_head),
        .commit_rd(commit_rd),
        .commit_value(commit_value),
        .commit_valid(commit_valid),
        .full(rob_full)
    );
    
    // ROB tail pointer - track current tail for allocation
    // This should match the ROB's internal tail_ptr
    logic [4:0] rob_tail_ptr;
    always_ff @(posedge clk) begin
        if (rst) begin
            rob_tail_ptr <= 5'b0;
        end else if (!stall) begin
            // Increment when we allocate a ROB entry
            if (rob_we) begin
                rob_tail_ptr <= (rob_tail_ptr + 1) % 16;
            end
        end
    end
    assign rob_tail = rob_tail_ptr;

    // Reservation Station
    logic rs_we;
    logic [2:0] rs_slot;
    logic rs_full;
    logic rs_ready;
    logic [2:0] ready_slot;
    logic [4:0] cdb_tag;
    logic [31:0] cdb_value;
    logic cdb_valid;
    
    // Reservation station outputs for ready instruction
    logic [3:0] rs_ready_op;
    logic [6:0] rs_ready_opcode;
    logic [31:0] rs_ready_vj;
    logic [31:0] rs_ready_vk;
    logic [31:0] rs_ready_imm;
    logic [4:0] rs_ready_rob_tag;
    logic rs_execute_clear;
    logic [2:0] rs_free_slot;
    
    reservation_station rs_inst (
        .clk(clk),
        .rst(rst),
        .rs_we(rs_we),
        .rs_slot(rs_slot),
        .op(alu_op),
        .opcode(opcode),
        .vj(!rs1_valid ? reg_data1 : 32'b0),  // If not renamed (ready), use reg value
        .vk(!rs2_valid ? reg_data2 : 32'b0),  // If not renamed (ready), use reg value
        .imm(imm),
        .qj(rs1_valid ? rs1_tag : 5'b0),     // If renamed (waiting), use tag
        .qk(rs2_valid ? rs2_tag : 5'b0),     // If renamed (waiting), use tag
        .rob_tag(rob_tail),
        .cdb_tag(cdb_tag),
        .cdb_value(cdb_value),
        .cdb_valid(cdb_valid),
        .flush(flush),
        .execute_clear(rs_execute_clear),
        .execute_slot(ready_slot),
        .ready_slot(ready_slot),
        .ready(rs_ready),
        .full(rs_full),
        .ready_op(rs_ready_op),
        .ready_opcode(rs_ready_opcode),
        .ready_vj(rs_ready_vj),
        .ready_vk(rs_ready_vk),
        .ready_imm(rs_ready_imm),
        .ready_rob_tag(rs_ready_rob_tag),
        .free_slot(rs_free_slot)
    );
    
    // Use free slot from reservation station
    assign rs_slot = rs_free_slot;

    // Dispatch unit
    dispatch dispatch_inst (
        .clk(clk),
        .rst(rst),
        .instruction(ifq_instruction),
        .pc(ifq_pc),
        .rs1_valid(rs1_valid),
        .rs2_valid(rs2_valid),
        .rs1_tag(rs1_tag),
        .rs2_tag(rs2_tag),
        .rs1_val(reg_data1),
        .rs2_val(reg_data2),
        .rob_full(rob_full),
        .rs_full(rs_full),
        .rob_tail(rob_tail),
        .rs_slot(rs_slot),
        .ifq_empty(ifq_empty),
        .rob_we(rob_we),
        .rs_we(rs_we),
        .rat_we(rat_we),
        .ifq_rd_en(ifq_rd_en),
        .stall(issue_stall)
    );
    
    logic issue_stall;
    
    // Issue stage control
    assign ifq_wr_en = !ifq_full && !fetching_nop && !stop_fetch;

    // ========== EXECUTE STAGE ==========
    // Execute clear signals
    logic rs_execute_clear_alu;
    logic rs_execute_clear_branch;
    assign rs_execute_clear = rs_execute_clear_alu | rs_execute_clear_branch;

    // Issue stage pipeline - capture instruction when issued
    logic issue_valid;
    logic [31:0] issue_instruction;
    logic [4:0] issue_rd;
    logic [31:0] issue_imm;
    logic [2:0] issue_funct3;
    logic [6:0] issue_funct7, issue_opcode;
    logic [4:0] issue_rob_tag;
    logic [31:0] issue_vj, issue_vk;
    logic [3:0] issue_alu_op;
    
    // Capture issued instruction
    always_ff @(posedge clk) begin
        if (rst) begin
            issue_valid <= 1'b0;
            issue_instruction <= 32'h00000013;
            issue_rd <= 5'b0;
            issue_imm <= 32'b0;
            issue_funct3 <= 3'b0;
            issue_funct7 <= 7'b0;
            issue_opcode <= 7'b0;
            issue_rob_tag <= 5'b0;
            issue_vj <= 32'b0;
            issue_vk <= 32'b0;
            issue_alu_op <= 4'b0;
        end else if (!stall && !issue_stall && !ifq_empty && ifq_rd_en) begin
            // Issue instruction - only when dispatch allows
            issue_valid <= 1'b1;
            issue_instruction <= ifq_instruction;
            issue_rd <= rd;
            issue_imm <= imm;
            issue_funct3 <= funct3;
            issue_funct7 <= funct7;
            issue_opcode <= opcode;
            // Capture ROB tag BEFORE it gets incremented
            issue_rob_tag <= rob_tail;
            // Get operand values from register file
            // CDB forwarding will be handled by reservation station
            issue_vj <= reg_data1;
            issue_vk <= reg_data2;
            // Determine ALU operation
            if (opcode == 7'b0110011) begin  // R-type
                case (funct3)
                    3'b000: issue_alu_op = (funct7[5] == 1'b1) ? 4'b0001 : 4'b0000;  // SUB : ADD
                    3'b100: issue_alu_op = 4'b0100;  // XOR
                    3'b110: issue_alu_op = 4'b0011;  // OR
                    3'b111: issue_alu_op = 4'b0010;  // AND
                    default: issue_alu_op = 4'b0000;
                endcase
            end else if (opcode == 7'b0010011) begin  // I-type (ADDI, etc.)
                case (funct3)
                    3'b000: issue_alu_op = 4'b0000;  // ADDI
                    default: issue_alu_op = 4'b0000;  // Default to ADD for other I-types
                endcase
            end else begin
                issue_alu_op = 4'b0000;  // Default
            end
        end else begin
            issue_valid <= 1'b0;
        end
    end
    
    // Execute stage - execute from reservation station when ready
    logic execute_valid;
    logic [3:0] alu_op_execute;
    logic [31:0] alu_a_execute, alu_b_execute;
    logic [4:0] rob_tag_execute;

    always_ff @(posedge clk) begin
        if (rst) begin
            execute_valid <= 1'b0;
            alu_op_execute <= 4'b0;
            alu_a_execute <= 32'b0;
            alu_b_execute <= 32'b0;
            rob_tag_execute <= 5'b0;
            rs_execute_clear_alu <= 1'b0;
        end else if (!stall && rs_ready && (rs_ready_opcode != 7'b1100011 && rs_ready_opcode != 7'b1101111 && rs_ready_opcode != 7'b1100111)) begin
            // Execute ALU operations when RS is ready (skip branches/jumps)
            execute_valid <= 1'b1;
            alu_op_execute <= rs_ready_op;
            alu_a_execute <= rs_ready_vj;
            // Determine if immediate should be used based on instruction opcode
            if (rs_ready_opcode == 7'b0010011) begin // I-type (ADDI, etc.)
                alu_b_execute <= rs_ready_imm;
            end else if (rs_ready_opcode == 7'b0110011) begin // R-type (ADD, etc.)
                alu_b_execute <= rs_ready_vk;
            end else begin
                alu_b_execute <= rs_ready_imm;  // Default to immediate
            end
            rob_tag_execute <= rs_ready_rob_tag;
            rs_execute_clear_alu <= 1'b1;  // Clear busy bit
        end else begin
            execute_valid <= 1'b0;
            rs_execute_clear_alu <= 1'b0;
        end
    end
    
    // ALU execution
    alu alu_inst (
        .a(alu_a_execute),
        .b(alu_b_execute),
        .op(alu_op_execute),
        .result(alu_result),
        .zero(alu_zero)
    );

    // ========== BRANCH EXECUTE STAGE ==========
    // Branch execution - handle branch and jump instructions
    logic branch_execute_valid;
    logic [2:0] branch_funct3_execute;
    logic [31:0] branch_pc_execute, branch_imm_execute;
    logic [31:0] branch_rs1_val_execute, branch_rs2_val_execute;
    logic [4:0] branch_rob_tag_execute;

    logic branch_taken, branch_mispredict;
    logic [31:0] branch_target, branch_correct_pc;

    always_ff @(posedge clk) begin
        if (rst) begin
            branch_execute_valid <= 1'b0;
            branch_funct3_execute <= 3'b0;
            branch_pc_execute <= 32'b0;
            branch_imm_execute <= 32'b0;
            branch_rs1_val_execute <= 32'b0;
            branch_rs2_val_execute <= 32'b0;
            branch_rob_tag_execute <= 5'b0;
        end else if (!stall && rs_ready && (rs_ready_opcode == 7'b1100011 || rs_ready_opcode == 7'b1101111 || rs_ready_opcode == 7'b1100111)) begin
            // Execute branch/jump when RS is ready
            branch_execute_valid <= 1'b1;
            // For jumps (JAL/JALR), use special encoding, for branches use the actual funct3
            branch_funct3_execute <= (rs_ready_opcode == 7'b1101111 || rs_ready_opcode == 7'b1100111) ? 3'b111 : rs_ready_op[2:0];
            branch_pc_execute <= rs_ready_rob_tag * 4;  // Approximate PC from ROB tag (simplified)
            branch_imm_execute <= rs_ready_imm;
            branch_rs1_val_execute <= rs_ready_vj;
            branch_rs2_val_execute <= rs_ready_vk;
            branch_rob_tag_execute <= rs_ready_rob_tag;
            rs_execute_clear_branch <= 1'b1;  // Clear busy bit
        end else begin
            branch_execute_valid <= 1'b0;
            rs_execute_clear_branch <= 1'b0;
        end
    end

    // Branch unit
    branch_unit branch_unit_inst (
        .rs1_val(branch_rs1_val_execute),
        .rs2_val(branch_rs2_val_execute),
        .pc(branch_pc_execute),
        .imm(branch_imm_execute),
        .branch_type(branch_funct3_execute),
        .predicted_taken(1'b0),  // No prediction for now
        .predicted_target(32'b0),
        .taken(branch_taken),
        .target(branch_target),
        .mispredict(branch_mispredict),
        .correct_pc(branch_correct_pc)
    );

    // ========== WRITE BACK STAGE ==========
    // Write back pipeline registers - delay execute by one cycle
    logic wb_valid;
    logic [4:0] wb_tag;
    logic [31:0] wb_value;

    logic branch_wb_valid;
    logic [4:0] branch_wb_tag;
    logic [31:0] branch_wb_value;

    always_ff @(posedge clk) begin
        if (rst) begin
            wb_valid <= 1'b0;
            wb_tag <= 5'b0;
            wb_value <= 32'b0;
            branch_wb_valid <= 1'b0;
            branch_wb_tag <= 5'b0;
            branch_wb_value <= 32'b0;
        end else if (!stall) begin
            // Write back ALU result from execute stage
            wb_valid <= execute_valid;
            wb_tag <= rob_tag_execute;
            wb_value <= alu_result;

            // Write back branch result (PC+4 for link register, or branch target)
            branch_wb_valid <= branch_execute_valid;
            branch_wb_tag <= branch_rob_tag_execute;
            // For JAL/JALR, return address is PC+4, for branches it's the target
            branch_wb_value <= (branch_funct3_execute == 3'b111) ? (branch_pc_execute + 4) : branch_target;
        end
    end

    // CDB - Common Data Bus
    cdb cdb_inst (
        .alu_req(wb_valid),
        .alu_tag(wb_tag),
        .alu_value(wb_value),
        .branch_req(branch_wb_valid),
        .branch_tag(branch_wb_tag),
        .branch_value(branch_wb_value),
        .lsu_req(1'b0),
        .lsu_tag(5'b0),
        .lsu_value(32'b0),
        .cdb_valid(cdb_valid),
        .cdb_tag(cdb_tag),
        .cdb_value(cdb_value)
    );

    // ========== COMMIT STAGE ==========
    // Commit from ROB to register file
    always_ff @(posedge clk) begin
        if (rst) begin
            reg_write <= 1'b0;
            write_addr <= 5'b0;
            write_data <= 32'b0;
        end else if (!stall) begin
            // Commit instruction from ROB head when valid
            if (commit_valid && (commit_rd != 5'b0)) begin
                reg_write <= 1'b1;
                write_addr <= commit_rd;
                write_data <= commit_value;
            end else begin
                reg_write <= 1'b0;
            end
        end
    end

    // Cycle counter and state register
    always_ff @(posedge clk) begin
        if (rst) begin
            cycle_counter <= 32'b0;
            state_reg <= 32'b0;
        end else begin
            cycle_counter <= cycle_counter + 1;
            state_reg <= reg_data1 + reg_data2 + alu_result + pc;
        end
    end

    // Connect outputs to prevent optimization
    logic [31:0] pc_plus_4;
    assign pc_plus_4 = pc + 4;
    logic [31:0] combined_data;
    assign combined_data = reg_data1 + reg_data2 + alu_result + pc_plus_4 + cycle_counter;
    assign dmem_addr = alu_result;
    assign dmem_wdata = reg_data2;
    assign dmem_we = reg_write && (opcode == 7'b0100011);
    assign dmem_re = !ifq_empty && (opcode == 7'b0000011);

endmodule
