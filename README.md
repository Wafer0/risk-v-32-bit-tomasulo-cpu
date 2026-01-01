# RISC-V 32-bit Out-of-Order (Tomasulo) CPU

A complete, synthesizable RISC-V CPU implementation using Tomasulo's Algorithm with full ASIC design flow from RTL to GDSII.

**Author:** Andreas Tzitzikas

---

## Overview

This project implements a complete RISC-V RV32I CPU using an out-of-order execution architecture based on Tomasulo's Algorithm. The design includes register renaming, reservation stations, a reorder buffer, and a common data bus for dynamic instruction scheduling and execution.

**Key Features:**
- **Tomasulo's Algorithm** for dynamic scheduling
- **Reorder Buffer (ROB)** for in-order commit
- **Register Alias Table (RAT)** for register renaming
- **Reservation Stations** for operand capture and CDB snooping
- **Speculative execution** with misprediction recovery
- **Full ASIC flow** from RTL to GDSII

---

## Architecture

### Out-of-Order Execution Pipeline

```
Fetch → Decode → Dispatch → Issue → Execute → Complete → Commit
         ↓         ↓          ↓        ↓         ↓
        IFQ      RAT        RS      ALU/BR/LSU  CDB    ROB → RF
```

1. **Fetch**: PC → Instruction Memory → Instruction Fetch Queue (IFQ)
2. **Decode**: IFQ → Decoder → Dispatch
3. **Dispatch**: Allocates ROB and RS entries, performs register renaming via RAT
4. **Issue**: Reservation Stations issue ready instructions to execution units
5. **Execute**: ALU, Branch Unit, or Load/Store Unit executes instructions
6. **Complete**: Results broadcast on Common Data Bus (CDB)
7. **Commit**: Reorder Buffer commits instructions in-order to register file

### Key Components

| Module | Purpose |
|--------|---------|
| `top.sv` | Top-level module integrating all components |
| `structs.sv` | Common structs and parameters |
| `fifo.sv` | Generic FIFO for instruction fetch queue |
| `pc_gen.sv` | Program counter generation with branch prediction |
| `instr_mem.sv` | Instruction memory (ROM) |
| `ifq.sv` | Instruction Fetch Queue |
| `decoder.sv` | Instruction decoder |
| `rat.sv` | Register Alias Table for register renaming |
| `reg_file.sv` | Architectural register file |
| `dispatch.sv` | Dispatch unit (ROB/RS allocation) |
| `reservation_station.sv` | Reservation stations with CDB snooping |
| `issue_queue.sv` | Issue queue (optional) |
| `alu.sv` | Arithmetic Logic Unit |
| `branch_unit.sv` | Branch evaluation and target calculation |
| `lsu.sv` | Load/Store Unit |
| `cdb.sv` | Common Data Bus arbiter |
| `reorder_buffer.sv` | Reorder Buffer for in-order commit |

---

## Features

**RV32I ISA Support**
- Integer instructions: add, sub, and, or, xor, sll, srl, sra, slt, sltu
- Load/store: lb, lh, lw, lbu, lhu, sb, sh, sw
- Branches: beq, bne, blt, bge, bltu, bgeu
- Jumps: jal, jalr
- Upper immediates: lui, auipc

**Out-of-Order Execution**
- Register renaming eliminates WAR and WAW hazards
- CDB snooping resolves RAW hazards dynamically
- Reservation stations enable instruction-level parallelism
- Reorder buffer ensures in-order commit and precise exceptions

**Verification**
- Unit tests for all modules
- System tests with programs
- All tests passing

**ASIC Implementation**
- Synthesizable SystemVerilog
- Compatible with OpenLane ASIC flow
- Sky130 130nm process ready

---

## Project Structure

```
.
├── rtl/                    # RTL source files (17 modules)
│   ├── top.sv             # Top-level CPU
│   ├── structs.sv         # Common definitions
│   ├── fifo.sv            # Generic FIFO
│   ├── pc_gen.sv          # PC generation
│   ├── instr_mem.sv       # Instruction memory
│   ├── ifq.sv             # Instruction fetch queue
│   ├── decoder.sv         # Instruction decoder
│   ├── rat.sv             # Register alias table
│   ├── reg_file.sv        # Register file
│   ├── dispatch.sv        # Dispatch unit
│   ├── reservation_station.sv  # Reservation stations
│   ├── issue_queue.sv     # Issue queue
│   ├── alu.sv             # ALU
│   ├── branch_unit.sv     # Branch unit
│   ├── lsu.sv             # Load/store unit
│   ├── cdb.sv             # Common data bus
│   └── reorder_buffer.sv  # Reorder buffer
├── tb/                     # Testbench
│   └── top_tb.sv          # Top-level testbench
├── test/                   # All tests
│   ├── unit/              # Unit tests (15 test files)
│   │   └── test_*.sv
│   └── programs/          # Test programs (.hex)
│       ├── test01_basic_arithmetic.hex
│       ├── test02_logic_operations.hex
│       ├── test03_shifts.hex
│       ├── test06_memory_ops.hex
│       ├── test07_branches.hex
│       └── test08_jumps.hex
├── scripts/                # Build scripts
│   ├── setup_arch.sh        # Complete setup for Arch Linux
│   ├── simulate.sh          # Run simulation
│   ├── synthesize.sh        # Synthesize design
│   ├── lint.sh              # Run linter
│   └── run_openlane.sh      # Full ASIC flow
├── openlane/               # OpenLane configuration
│   ├── config.json         # OpenLane settings
│   └── runs/               # Run results (generated)
│       └── run_1/
│           └── results/
│               └── final/
│                   └── gds/
│                       └── top.gds  # Final GDSII output
├── Makefile                # Build automation
└── README.md               # This file
```

---

## Quick Start

### Basic Setup (Simulation Only)

For simulation and testing:

```bash
# Install required packages
sudo pacman -S base-devel git icarus-verilog gtkwave make

# Clone the repository
git clone <repository-url>
cd risk-v-32-bit-tomasulo-cpu

# Run all tests
make test-all

# Run a single simulation
make run-sim PROGRAM=test01_basic_arithmetic
```

### Complete Setup (Full ASIC Flow)

For the full ASIC design flow including GDSII generation, use the automated setup script:

```bash
# Run the complete setup script (requires sudo)
sudo ./scripts/setup_arch.sh
```

This script installs everything automatically. Alternatively, you can install manually:

#### Step 1: Install System Packages

**Arch Linux:**
```bash
sudo pacman -S base-devel git make \
    icarus-verilog gtkwave \
    verilator yosys \
    python python-pip python-pipx \
    docker docker-compose \
    klayout
```

**Ubuntu/Debian:**
```bash
sudo apt install build-essential git make \
    iverilog gtkwave \
    verilator yosys \
    python3 python3-pip pipx \
    docker.io docker-compose \
    klayout
```

#### Step 2: Configure Docker

Configure Docker to run without sudo:

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Configure Docker data directory
sudo mkdir -p /etc/docker
sudo bash -c 'cat > /etc/docker/daemon.json << EOF
{
  "data-root": "/home/docker",
  "storage-driver": "overlay2"
}
EOF'

# Create data directory
sudo mkdir -p /home/docker
sudo chmod 775 /home/docker

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Note: Logout and login required for group changes to take effect
# Alternatively, run: newgrp docker
```

#### Step 3: Install Sky130 PDK

The Process Design Kit requires approximately 2-3 GB of storage:

```bash
./scripts/install_pdk.sh
```

This installs the Sky130 PDK to `/home/archi/pdk/sky130A/`.

#### Step 4: Download OpenLane Docker Image

```bash
docker pull efabless/openlane:2023.11.03
```

Download size: approximately 3-5 GB.

---

## Usage

### Running Tests

```bash
# Run all test programs with correctness verification
./scripts/simulate all

# Run a single test program
./scripts/simulate test01_basic_arithmetic

# Run unit tests only
make unit-tests

# View waveforms (after running a simulation)
make wave
```

### Running Synthesis

```bash
make synth
```

Output: `syn/riscv_cpu_synth.v`

### Running ASIC Flow

Complete place and route with GDSII generation:

```bash
make openlane-run
```

Or use the script:

```bash
./scripts/run_openlane.sh
```

Estimated runtime: 30 minutes to 2 hours.

Output: `openlane/runs/run_1/results/final/gds/top.gds`

View layout:
```bash
klayout openlane/runs/run_1/results/final/gds/top.gds
```

### Makefile Commands

Alternative command interface:

```bash
# Testing
make unit-tests          # Run all unit tests

# Individual unit tests
make test-fifo          # Test FIFO module
make test-decoder       # Test decoder module
make test-rat           # Test RAT module
make test-rs            # Test reservation station
make test-alu           # Test ALU
make test-branch        # Test branch unit
make test-rob           # Test reorder buffer
make test-regfile       # Test register file

# Simulation
./scripts/simulate all              # Run all tests with verification
./scripts/simulate test01_basic_arithmetic  # Run single test

# Synthesis
make synth

# Linting
make lint

# ASIC flow
make openlane-run

# Cleanup
make clean              # Clean all generated files
make clean-sim          # Clean only simulation files
```

---

## Test Programs

The following test programs verify CPU functionality:

| Test | Description |
|------|-------------|
| `benchmark` | 100-instruction benchmark for IPC measurement |
| `test01_basic_arithmetic` | ADD, SUB, ADDI |
| `test02_logic_operations` | AND, OR, XOR, ANDI, ORI, XORI |
| `test03_shifts` | SLL, SRL, SRA, SLLI, SRLI, SRAI |
| `test06_memory_ops` | LW, SW |
| `test07_branches` | BEQ, BNE, BLT, BGE |
| `test08_jumps` | JAL, JALR |

---

## Benchmark Suite

The `benchmark` test program measures IPC performance. Run it with:

```bash
./scripts/simulate benchmark benchmark
```

This runs the benchmark in benchmark mode and captures performance statistics.

---

## Design Decisions

### Out-of-Order Execution

The design implements Tomasulo's Algorithm with a Reorder Buffer:
- **Register Renaming**: Eliminates false dependencies (WAR, WAW hazards)
- **CDB Snooping**: Dynamically resolves RAW dependencies
- **In-Order Commit**: Ensures precise exceptions and correct program order
- **Speculative Execution**: Branches execute speculatively with recovery

### Hazard Resolution

Unlike in-order pipelines, this design handles hazards through:
- **Data hazards**: Resolved by register renaming and CDB snooping
- **Control hazards**: Handled by branch prediction and misprediction recovery
- **Structural hazards**: Managed by resource allocation (ROB, RS)

### Reset Strategy

Synchronous reset is used throughout the design:
- Eliminates multi-edge sensitivity issues in ASIC synthesis
- Follows current industry practices for digital design
- Simplifies static timing analysis
- Improves timing closure

### Clock Frequency Target

The 50 MHz clock frequency (20 ns period) was selected based on:
- Conservative timing target ensuring first-pass success
- Compatibility with Sky130 process characteristics
- Sufficient performance for embedded applications
- Headroom for design iteration and optimization

---

## Development Methodology

The design was developed using the following flow:

1. **RTL Design** - SystemVerilog implementation of all modules
2. **Unit Testing** - Individual module verification
3. **System Integration** - Full CPU verification with test programs
4. **Code Quality** - Linting with Verible
5. **Logic Synthesis** - Gate-level synthesis with Yosys
6. **Physical Design** - Place and route with OpenLane
7. **Signoff** - Final verification and GDSII generation

---

## Tools Used

- **Icarus Verilog** - Simulation
- **GTKWave** - Waveform viewing
- **Verible** - Linting
- **Yosys** - Synthesis
- **OpenLane** - ASIC flow (place & route)
- **Docker** - Containerized toolchain
- **Sky130 PDK** - 130nm process design kit
- **KLayout** - GDSII viewer
- **Make** - Build automation

---

## Troubleshooting

### Docker Permission Issues

If Docker commands fail with permission errors:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Insufficient Disk Space

Verify Docker is using the home directory:
```bash
docker info | grep "Docker Root Dir"
```

Expected output: `/home/docker`

### PDK Not Found

Install the PDK:
```bash
./scripts/install_pdk.sh
```

### Simulation Failures

Verify test programs exist:
```bash
ls tests/programs/*.hex
```

### Alternative Platforms

**Ubuntu/Debian**: Replace `pacman` commands with `apt`  
**macOS**: Most tools compatible, OpenLane requires Docker Desktop  
**Windows**: Use WSL2 with Ubuntu

---

## Resource Usage

- **Simulation**: ~100 MB RAM, ~50 MB storage, < 1 minute
- **Synthesis**: ~500 MB RAM, ~100 MB storage, 1-2 minutes
- **ASIC Flow**: 2-4 GB RAM peak, ~5 GB storage, 30 minutes - 2 hours

---

## Acknowledgments

- RISC-V International for the ISA specification
- Efabless Corporation for the open-source Sky130 PDK and OpenLane tools
- Google and SkyWater Technology for sponsoring the Sky130 process
- The open-source EDA community for development tools

---

## OpenLane Results

Some large binary files in the OpenLane results directory have been compressed with gzip to keep the repository size manageable:

- `openlane/runs/run_1/results/routing/top.odb.gz`
- `openlane/runs/run_1/tmp/routing/25-fill.odb.gz`
- `openlane/runs/run_1/tmp/signoff/magic_spice_ext/top.ext.gz`

To restore the complete OpenLane results, decompress these files:
```bash
cd openlane/runs/run_1
gunzip results/routing/top.odb.gz
gunzip tmp/routing/25-fill.odb.gz
gunzip tmp/signoff/magic_spice_ext/top.ext.gz
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
