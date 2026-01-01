#!/bin/bash
# Synthesize with Yosys

echo "Running synthesis..."
echo ""

mkdir -p syn

yosys -p "
    read_verilog -sv -DSYNTHESIS rtl/*.sv;
    hierarchy -check -top top;
    proc; opt; fsm; opt; memory; opt;
    techmap; opt;
    write_verilog syn/riscv_cpu_synth.v;
    stat
" | tee syn/synthesis.log

if [ $? -eq 0 ]; then
    echo ""
    echo "Synthesis complete"
    echo "Output: syn/riscv_cpu_synth.v"
    echo "Log: syn/synthesis.log"
else
    echo ""
    echo "Synthesis failed - check syn/synthesis.log"
    exit 1
fi

