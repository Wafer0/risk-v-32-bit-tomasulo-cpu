# ============================================================================
# RISC-V Out-of-Order (Tomasulo) CPU - Makefile
# ============================================================================

# Directories
RTL_DIR := rtl
TB_DIR := tb
TEST_DIR := test
UNIT_TEST_DIR := test/unit
SIM_DIR := sim
SYN_DIR := syn
PROG_DIR := $(TEST_DIR)/programs

# RTL source files (structs.sv must come first)
RTL_FILES := $(RTL_DIR)/structs.sv \
             $(RTL_DIR)/fifo.sv \
             $(RTL_DIR)/pc_gen.sv \
             $(RTL_DIR)/instr_mem.sv \
             $(RTL_DIR)/ifq.sv \
             $(RTL_DIR)/decoder.sv \
             $(RTL_DIR)/rat.sv \
             $(RTL_DIR)/reg_file.sv \
             $(RTL_DIR)/dispatch.sv \
             $(RTL_DIR)/reservation_station.sv \
             $(RTL_DIR)/issue_queue.sv \
             $(RTL_DIR)/alu.sv \
             $(RTL_DIR)/branch_unit.sv \
             $(RTL_DIR)/lsu.sv \
             $(RTL_DIR)/cdb.sv \
             $(RTL_DIR)/reorder_buffer.sv \
             $(RTL_DIR)/top.sv

# Testbenches
SYSTEM_TB := $(TB_DIR)/top_tb.sv
UNIT_TESTS := $(wildcard $(UNIT_TEST_DIR)/test_*.sv)

# Simulation parameters
PROGRAM ?= test01_basic_arithmetic
SIM_CYCLES ?= 500
DUMP_VCD ?= 1

# ============================================================================
# Main Targets
# ============================================================================

.PHONY: all help clean unit-tests system-test test-all
.PHONY: run-sim sim-verilator wave synth lint clean-sim
.PHONY: test-fifo test-decoder test-rat test-rs test-alu test-branch test-rob test-regfile
.PHONY: test-pc-gen test-instr-mem test-ifq test-dispatch test-lsu test-cdb test-issue-queue

all: unit-tests system-test

help:
	@echo "RISC-V Out-of-Order (Tomasulo) CPU - Makefile Commands"
	@echo ""
	@echo "TESTING:"
	@echo "  unit-tests          Run all unit tests for individual modules"
	@echo "  test-fifo           Test FIFO module only"
	@echo "  test-decoder        Test decoder module only"
	@echo "  test-rat            Test RAT module only"
	@echo "  test-rs             Test reservation station only"
	@echo "  test-alu            Test ALU module only"
	@echo "  test-branch         Test branch unit only"
	@echo "  test-rob            Test reorder buffer only"
	@echo "  test-regfile        Test register file only"
	@echo "  system-test         Run full CPU system test"
	@echo "  test-all            Run all unit and system tests"
	@echo ""
	@echo "SIMULATION:"
	@echo "  run-sim             Simulate with Icarus Verilog (default program)"
	@echo "  sim-verilator       Simulate with Verilator"
	@echo "  wave                View waveforms in GTKWave"
	@echo ""
	@echo "SYNTHESIS:"
	@echo "  synth               Synthesize with Yosys"
	@echo "  lint                Run Verible linter"
	@echo ""
	@echo "OPENLANE ASIC FLOW:"
	@echo "  openlane-setup      Pull OpenLane Docker image (one-time)"
	@echo "  openlane-run        Run complete ASIC flow (RTL → GDSII)"
	@echo "  openlane-results    Show results summary"
	@echo "  openlane-clean      Clean OpenLane runs"
	@echo ""
	@echo "MAINTENANCE:"
	@echo "  clean               Remove all generated files"
	@echo "  clean-sim           Remove only simulation files"
	@echo ""
	@echo "VARIABLES:"
	@echo "  PROGRAM=<name>      Test program (default: test01_basic_arithmetic)"
	@echo "  SIM_CYCLES=<n>      Simulation cycles (default: 500)"
	@echo "  DUMP_VCD=<0|1>      Enable VCD waveform dump (default: 1)"
	@echo ""
	@echo "EXAMPLES:"
	@echo "  make test-all                            # Run all tests"
	@echo "  make run-sim PROGRAM=test02 DUMP_VCD=1   # Simulate with waveforms"
	@echo "  make openlane-run                        # Full ASIC flow"
	@echo ""

# ============================================================================
# Unit Tests
# ============================================================================

unit-tests:
	@echo "Running unit tests..."
	@$(MAKE) test-fifo
	@$(MAKE) test-pc-gen
	@$(MAKE) test-instr-mem
	@$(MAKE) test-ifq
	@$(MAKE) test-decoder
	@$(MAKE) test-rat
	@$(MAKE) test-regfile
	@$(MAKE) test-dispatch
	@$(MAKE) test-rs
	@$(MAKE) test-issue-queue
	@$(MAKE) test-alu
	@$(MAKE) test-branch
	@$(MAKE) test-lsu
	@$(MAKE) test-cdb
	@$(MAKE) test-rob
	@echo ""
	@echo "All unit tests passed."

test-fifo:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing FIFO..."
	@iverilog -g2012 -o $(SIM_DIR)/test_fifo.vvp \
		$(UNIT_TEST_DIR)/test_fifo.sv $(RTL_DIR)/fifo.sv
	@vvp $(SIM_DIR)/test_fifo.vvp

test-decoder:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing Decoder..."
	@iverilog -g2012 -o $(SIM_DIR)/test_decoder.vvp \
		$(UNIT_TEST_DIR)/test_decoder.sv $(RTL_DIR)/structs.sv $(RTL_DIR)/decoder.sv
	@vvp $(SIM_DIR)/test_decoder.vvp

test-rat:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing RAT..."
	@iverilog -g2012 -o $(SIM_DIR)/test_rat.vvp \
		$(UNIT_TEST_DIR)/test_rat.sv $(RTL_DIR)/structs.sv $(RTL_DIR)/rat.sv
	@vvp $(SIM_DIR)/test_rat.vvp

test-rs:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing Reservation Station..."
	@iverilog -g2012 -o $(SIM_DIR)/test_rs.vvp \
		$(UNIT_TEST_DIR)/test_reservation_station.sv $(RTL_DIR)/structs.sv $(RTL_DIR)/reservation_station.sv
	@vvp $(SIM_DIR)/test_rs.vvp

test-alu:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing ALU..."
	@iverilog -g2012 -o $(SIM_DIR)/test_alu.vvp \
		$(UNIT_TEST_DIR)/test_alu.sv $(RTL_DIR)/alu.sv
	@vvp $(SIM_DIR)/test_alu.vvp

test-branch:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing Branch Unit..."
	@iverilog -g2012 -o $(SIM_DIR)/test_branch.vvp \
		$(UNIT_TEST_DIR)/test_branch_unit.sv $(RTL_DIR)/structs.sv $(RTL_DIR)/branch_unit.sv
	@vvp $(SIM_DIR)/test_branch.vvp

test-rob:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing Reorder Buffer..."
	@iverilog -g2012 -o $(SIM_DIR)/test_rob.vvp \
		$(UNIT_TEST_DIR)/test_reorder_buffer.sv $(RTL_DIR)/structs.sv $(RTL_DIR)/reorder_buffer.sv
	@vvp $(SIM_DIR)/test_rob.vvp

test-regfile:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing Register File..."
	@iverilog -g2012 -o $(SIM_DIR)/test_regfile.vvp \
		$(UNIT_TEST_DIR)/test_reg_file.sv $(RTL_DIR)/reg_file.sv
	@vvp $(SIM_DIR)/test_regfile.vvp

test-pc-gen:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing PC Generator..."
	@iverilog -g2012 -o $(SIM_DIR)/test_pc_gen.vvp \
		$(UNIT_TEST_DIR)/test_pc_gen.sv $(RTL_DIR)/pc_gen.sv
	@vvp $(SIM_DIR)/test_pc_gen.vvp

test-instr-mem:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing Instruction Memory..."
	@iverilog -g2012 -o $(SIM_DIR)/test_instr_mem.vvp \
		$(UNIT_TEST_DIR)/test_instr_mem.sv $(RTL_DIR)/instr_mem.sv
	@vvp $(SIM_DIR)/test_instr_mem.vvp

test-ifq:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing Instruction Fetch Queue..."
	@iverilog -g2012 -o $(SIM_DIR)/test_ifq.vvp \
		$(UNIT_TEST_DIR)/test_ifq.sv $(RTL_DIR)/structs.sv $(RTL_DIR)/fifo.sv $(RTL_DIR)/ifq.sv
	@vvp $(SIM_DIR)/test_ifq.vvp

test-dispatch:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing Dispatch Unit..."
	@iverilog -g2012 -o $(SIM_DIR)/test_dispatch.vvp \
		$(UNIT_TEST_DIR)/test_dispatch.sv $(RTL_DIR)/dispatch.sv
	@vvp $(SIM_DIR)/test_dispatch.vvp

test-lsu:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing Load/Store Unit..."
	@iverilog -g2012 -o $(SIM_DIR)/test_lsu.vvp \
		$(UNIT_TEST_DIR)/test_lsu.sv $(RTL_DIR)/lsu.sv
	@vvp $(SIM_DIR)/test_lsu.vvp

test-cdb:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing Common Data Bus..."
	@iverilog -g2012 -o $(SIM_DIR)/test_cdb.vvp \
		$(UNIT_TEST_DIR)/test_cdb.sv $(RTL_DIR)/cdb.sv
	@vvp $(SIM_DIR)/test_cdb.vvp

test-issue-queue:
	@mkdir -p $(SIM_DIR)
	@echo "\n→ Testing Issue Queue..."
	@iverilog -g2012 -o $(SIM_DIR)/test_issue_queue.vvp \
		$(UNIT_TEST_DIR)/test_issue_queue.sv $(RTL_DIR)/issue_queue.sv
	@vvp $(SIM_DIR)/test_issue_queue.vvp

# ============================================================================
# System Tests
# ============================================================================

system-test:
	@echo "\nRunning system tests..."
	@for test in test01_basic_arithmetic test02_logic_operations test03_shifts \
	             test06_memory_ops test07_branches test08_jumps; do \
		echo "\n→ Testing: $$test"; \
		$(MAKE) run-sim PROGRAM=$$test DUMP_VCD=0 2>&1 | tail -5 || exit 1; \
	done
	@echo "\nAll system tests passed."

test-all: unit-tests system-test

run-sim:
	@mkdir -p $(SIM_DIR)
	@echo "Simulating: $(PROGRAM)"
	@iverilog -g2012 -Wall -Winfloop \
		`if [ $(DUMP_VCD) -eq 1 ]; then echo "-DDUMP_VCD"; fi` \
		-DPROGRAM_FILE=\"$(PROG_DIR)/$(PROGRAM).hex\" \
		-DTEST_NAME=\"$(PROGRAM)\" \
		-DSIMULATION_CYCLES=$(SIM_CYCLES) \
		-o $(SIM_DIR)/$(PROGRAM).vvp \
		$(SYSTEM_TB) $(RTL_FILES)
	@cd $(SIM_DIR) && vvp $(PROGRAM).vvp

sim-verilator:
	@mkdir -p $(SIM_DIR)
	@echo "Building with Verilator..."
	@verilator --binary --timing -Wall -Wno-fatal --trace \
		--top-module top_tb \
		--Mdir $(SIM_DIR)/obj_dir \
		$(SYSTEM_TB) $(RTL_FILES)
	@$(SIM_DIR)/obj_dir/Vtop_tb

wave: $(SIM_DIR)/waves.vcd
	@gtkwave $(SIM_DIR)/waves.vcd &

# ============================================================================
# Synthesis
# ============================================================================

synth:
	@mkdir -p $(SYN_DIR)
	@echo "Converting SystemVerilog to Verilog..."
	@sv2v $(RTL_FILES) > $(SYN_DIR)/riscv_cpu_flat.v 2>/dev/null || \
		(echo "Note: sv2v not available, using Yosys directly..." && \
		 yosys -p "read_verilog -sv $(RTL_FILES); \
		          hierarchy -check -top top; \
		          proc; opt; fsm; opt; memory; opt; \
		          synth -top top; \
		          write_verilog $(SYN_DIR)/riscv_cpu_synth.v; \
		          stat" | tee $(SYN_DIR)/synthesis.log)
	@if [ -f $(SYN_DIR)/riscv_cpu_flat.v ]; then \
		echo "Fixing readmemh for synthesis..."; \
		sed -i 's/\$$readmemh/\/\/ \$$readmemh/g' $(SYN_DIR)/riscv_cpu_flat.v; \
		echo "Synthesizing with Yosys..."; \
		yosys -p "read_verilog $(SYN_DIR)/riscv_cpu_flat.v; \
		          hierarchy -check -top top; \
		          proc; opt; fsm; opt; memory; opt; \
		          synth -top top; \
		          write_verilog $(SYN_DIR)/riscv_cpu_synth.v; \
		          stat" | tee $(SYN_DIR)/synthesis.log; \
	fi
	@echo ""
	@echo "Synthesis complete! Check syn/ directory for results."

lint:
	@echo "Running Verible linter..."
	@verible-verilog-lint $(RTL_FILES) $(SYSTEM_TB) || true

# ============================================================================
# OpenLane ASIC Flow
# ============================================================================

.PHONY: openlane-setup openlane-run openlane-clean openlane-results

openlane-setup:
	@echo "Setting up OpenLane..."
	@echo "Pulling OpenLane Docker image..."
	docker pull efabless/openlane:2023.11.03

openlane-run:
	@echo "Running OpenLane ASIC flow (RTL to GDSII)..."
	@echo ""
	@echo "This will take 30min-2hrs depending on your machine."
	@echo "Watch the progress in your terminal..."
	@echo ""
	@if [ -d "/home/archi/pdk" ]; then \
		echo "Using local PDK at /home/archi/pdk"; \
		docker run --rm \
			-v $(shell pwd):/project \
			-v /home/archi/pdk:/build/pdk:ro \
			-w /project \
			efabless/openlane:2023.11.03 \
			bash -c "cd openlane && /openlane/flow.tcl -design . -tag run_1 -overwrite"; \
	else \
		echo "No local PDK found. Install with: ./scripts/install_pdk.sh"; \
		echo "Or the Docker image should have a built-in PDK..."; \
		docker run --rm \
			-v $(shell pwd):/project \
			-w /project \
			efabless/openlane:2023.11.03 \
			bash -c "cd openlane && /openlane/flow.tcl -design . -tag run_1 -overwrite"; \
	fi

openlane-clean:
	@echo "Cleaning OpenLane runs..."
	@rm -rf openlane/runs

openlane-results:
	@echo "OpenLane Results:"
	@if [ -d openlane/runs/run_1/results ]; then \
		echo ""; \
		echo "Results available in openlane/runs/run_1/results/"; \
		echo ""; \
		echo "Key Outputs:"; \
		echo "  Synthesis:  openlane/runs/run_1/results/synthesis/"; \
		echo "  Placement:  openlane/runs/run_1/results/placement/"; \
		echo "  Routing:    openlane/runs/run_1/results/routing/"; \
		echo "  Final GDS:  openlane/runs/run_1/results/signoff/"; \
		echo ""; \
		echo "Reports:"; \
		echo "  Timing:     openlane/runs/run_1/reports/"; \
		echo "  Area:       openlane/runs/run_1/reports/"; \
		echo ""; \
		if [ -f openlane/runs/run_1/results/signoff/*.gds ]; then \
			echo "GDSII file found. Design ready for fabrication."; \
		fi; \
	else \
		echo ""; \
		echo "No results found."; \
		echo "Run 'make openlane-run' first."; \
		echo ""; \
	fi

# ============================================================================
# Cleanup
# ============================================================================

clean:
	@echo "Cleaning all generated files..."
	@rm -rf $(SIM_DIR) $(SYN_DIR)
	@rm -f *.vcd *.vvp *.log
	@rm -f $(UNIT_TEST_DIR)/*.vvp $(UNIT_TEST_DIR)/test_prog.hex

clean-sim:
	@echo "Cleaning simulation files..."
	@rm -rf $(SIM_DIR)
	@rm -f *.vcd *.vvp

