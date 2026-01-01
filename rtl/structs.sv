// structs.sv
// Common structs and parameters for the OoO RISC-V processor

// Parameters
parameter int ROB_SIZE = 16;
parameter int RS_SIZE = 8;
parameter int IFQ_DEPTH = 8;
parameter int NUM_REGS = 32;
parameter int DATA_WIDTH = 32;
parameter int ADDR_WIDTH = 32;
parameter int ROB_TAG_WIDTH = $clog2(ROB_SIZE);
parameter int RS_TAG_WIDTH = $clog2(RS_SIZE);
