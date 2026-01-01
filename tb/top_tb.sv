// Top-level testbench for the OoO RISC-V processor
module top_tb;
    `ifndef PROGRAM_FILE
    `define PROGRAM_FILE "program.hex"
    `endif
    `ifndef TEST_NAME
    `define TEST_NAME "test"
    `endif
    `ifndef SIMULATION_CYCLES
    `define SIMULATION_CYCLES 500
    `endif

    logic clk = 0;
    logic rst;

    // Clock
    always #5 clk = ~clk;

    // CPU
    top cpu_inst (
        .clk(clk),
        .rst(rst)
    );

    // VCD dump
    initial begin
        `ifdef DUMP_VCD
        $dumpfile("sim/waves.vcd");
        $dumpvars(0, top_tb);
        `endif
    end

    // Benchmark statistics
    `ifdef BENCHMARK_MODE
    integer cycle_count = 0;
    integer instruction_count = 0;
    logic prev_ifq_rd_en = 0;
    logic [31:0] prev_pc = 32'hFFFFFFFF;
    integer pc_stable_count = 0;
    integer ifq_empty_count = 0;
    logic stop_counting = 0;
    // Track unique PC values to count each instruction once
    logic [31:0] seen_pcs [0:127];
    integer seen_pc_count = 0;
    logic pc_is_stable = 0;
    `endif

    // Test
    initial begin
        $display("========================================");
        $display("RISC-V OoO CPU Simulation: %s", `TEST_NAME);
        $display("========================================");

        rst = 1;
        #20 rst = 0;

        `ifdef BENCHMARK_MODE
        cycle_count = 0;
        instruction_count = 0;
        prev_ifq_rd_en = 0;
        prev_pc = 32'hFFFFFFFF;
        pc_stable_count = 0;
        ifq_empty_count = 0;
        stop_counting = 0;
        seen_pc_count = 0;
        // Initialize seen PCs array
        begin
            integer j;
            for (j = 0; j < 128; j = j + 1) begin
                seen_pcs[j] = 32'hFFFFFFFF;
            end
        end
        `endif

        // Run simulation until program completes or timeout
        begin
            integer i;
            logic program_done = 0;
            for (i = 0; i < `SIMULATION_CYCLES && !program_done; i = i + 1) begin
                @(posedge clk);
                `ifdef BENCHMARK_MODE
                if (!rst) begin
                    cycle_count = cycle_count + 1;

                    // Track PC stability for completion detection
                    if (prev_pc != 32'hFFFFFFFF) begin
                        if (cpu_inst.imem_addr == prev_pc) begin
                            pc_stable_count = pc_stable_count + 1;
                            pc_is_stable = 1;
                        end else begin
                            pc_stable_count = 0;
                            pc_is_stable = 0;
                        end
                    end else begin
                        pc_is_stable = 0;
                    end

                    // Track IFQ empty state for completion detection
                    if (cpu_inst.ifq_empty) begin
                        ifq_empty_count = ifq_empty_count + 1;
                    end else begin
                        ifq_empty_count = 0;
                    end

                    // Stop counting immediately when PC stops advancing (program completed)
                    // This prevents counting the extra PC value that gets fetched after program ends
                    // Check this BEFORE counting to avoid counting the extra PC
                    if (pc_stable_count > 0 && ifq_empty_count > 0 && instruction_count > 0) begin
                        stop_counting = 1;
                    end

                    // Count instructions by tracking unique PC values
                    // This ensures each instruction is counted exactly once
                    // Only count before program completes and when PC is not stable
                    if (!stop_counting && !pc_is_stable && cpu_inst.imem_addr < 32'h200) begin
                        // Only count when PC actually advances (not stalled)
                        if (prev_pc != 32'hFFFFFFFF && cpu_inst.imem_addr != prev_pc) begin
                            // Check if we've seen this PC before
                            integer pc_seen;
                            pc_seen = 0;
                            begin
                                integer j;
                                for (j = 0; j < seen_pc_count && pc_seen == 0; j = j + 1) begin
                                    if (seen_pcs[j] == cpu_inst.imem_addr) begin
                                        pc_seen = 1;
                                    end
                                end
                            end

                            // If this is a new PC, count it as an instruction
                            if (pc_seen == 0 && seen_pc_count < 128) begin
                                seen_pcs[seen_pc_count] = cpu_inst.imem_addr;
                                seen_pc_count = seen_pc_count + 1;
                                instruction_count = instruction_count + 1;
                            end
                        end else if (prev_pc == 32'hFFFFFFFF && cpu_inst.imem_addr == 32'h0) begin
                            // First instruction at PC=0
                            seen_pcs[0] = 32'h0;
                            seen_pc_count = 1;
                            instruction_count = 1;
                        end
                    end

                    prev_ifq_rd_en = cpu_inst.ifq_rd_en;

                    // Set program_done flag
                    if (cpu_inst.imem_addr >= 32'h200) begin
                        program_done = 1;
                    end else if (pc_stable_count > 5 && ifq_empty_count > 5 && i > 10 && instruction_count > 0) begin
                        program_done = 1;
                    end

                    prev_pc = cpu_inst.imem_addr;
                end
                `endif
            end
        end

        $display("\n========================================");
        $display("Simulation Complete");
        $display("========================================");
        $display("Register File:");
        // Format output to match expected format: "x1=0000000a x2=00000014 x3=0000001e"
        $write("x1=%08h x2=%08h x3=%08h x4=%08h",
               cpu_inst.reg_file_inst.registers[1], cpu_inst.reg_file_inst.registers[2],
               cpu_inst.reg_file_inst.registers[3], cpu_inst.reg_file_inst.registers[4]);
        $write(" x5=%08h x6=%08h x7=%08h x8=%08h",
               cpu_inst.reg_file_inst.registers[5], cpu_inst.reg_file_inst.registers[6],
               cpu_inst.reg_file_inst.registers[7], cpu_inst.reg_file_inst.registers[8]);
        $display("");
        $display("========================================");

        `ifdef BENCHMARK_MODE
        $display("STATS: Cycles: %0d", cycle_count);
        $display("STATS: Instructions: %0d", instruction_count);
        if (cycle_count > 0) begin
            $display("STATS: IPC: %0.4f", real'(instruction_count) / real'(cycle_count));
        end else begin
            $display("STATS: IPC: 0.0000");
        end
        $display("========================================\n");
        `else
        $display("========================================\n");
        `endif

        $finish;
    end

    // Timeout
    initial begin
        #(`SIMULATION_CYCLES * 20);
        $display("ERROR: Timeout!");
        $finish;
    end
endmodule
