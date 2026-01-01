#!/bin/bash
# Run the complete OpenLane ASIC flow

echo "Running OpenLane ASIC flow (RTL to GDSII)..."
echo ""
echo "This will take 30 minutes to 2 hours"
echo ""

# Check if PDK exists
if [ ! -d "/home/archi/pdk/sky130A" ]; then
    echo "PDK not found at /home/archi/pdk"
    echo ""
    echo "Run the setup script to install everything:"
    echo "  ./scripts/setup_arch.sh"
    exit 1
fi

# Run OpenLane
docker run --rm \
    -v $(pwd):/project \
    -v /home/archi/pdk:/build/pdk:ro \
    -w /project \
    efabless/openlane:2023.11.03 \
    bash -c "cd openlane && /openlane/flow.tcl -design . -tag run_1 -overwrite"

if [ $? -eq 0 ]; then
    echo ""
    echo "Flow complete!"
    echo ""
    echo "GDSII file location:"
    echo "  openlane/runs/run_1/results/final/gds/top.gds"
    echo ""
    echo "View with:"
    echo "  klayout openlane/runs/run_1/results/final/gds/top.gds"
else
    echo ""
    echo "Flow failed - check logs in openlane/runs/run_1/logs/"
    exit 1
fi

