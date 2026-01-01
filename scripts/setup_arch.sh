#!/bin/bash
# Complete setup script for Arch Linux
# Installs all dependencies and tools needed for the RISC-V CPU project
# REQUIRES: Must be run with sudo

if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run with sudo"
    echo "Usage: sudo ./scripts/setup_arch.sh"
    exit 1
fi

# Get the original user (who ran sudo)
ORIGINAL_USER="${SUDO_USER:-$USER}"
ORIGINAL_HOME=$(eval echo ~$ORIGINAL_USER)

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PDK_ROOT="$ORIGINAL_HOME/pdk"

echo "RISC-V CPU Project - Complete Setup for Arch Linux"
echo "=================================================="
echo ""
echo "Running as: $ORIGINAL_USER"
echo "This will take 15-30 minutes"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled"
    exit 0
fi

# Function to check if command exists (portable - checks multiple locations)
check_command() {
    local cmd=$1
    local user=$2
    local home=$3
    
    # Check in PATH
    if sudo -u $user command -v $cmd &> /dev/null; then
        return 0
    fi
    
    # Check common locations
    local paths=(
        "$home/.local/bin/$cmd"
        "/usr/local/bin/$cmd"
        "/usr/bin/$cmd"
        "/bin/$cmd"
    )
    
    for path in "${paths[@]}"; do
        if [ -f "$path" ] && [ -x "$path" ]; then
            return 0
        fi
    done
    
    return 1
}

# Function to get command path (portable)
get_command_path() {
    local cmd=$1
    local user=$2
    local home=$3
    
    # Check in PATH first
    local path=$(sudo -u $user command -v $cmd 2>/dev/null)
    if [ -n "$path" ]; then
        echo "$path"
        return 0
    fi
    
    # Check common locations
    local paths=(
        "$home/.local/bin/$cmd"
        "/usr/local/bin/$cmd"
        "/usr/bin/$cmd"
        "/bin/$cmd"
    )
    
    for path in "${paths[@]}"; do
        if [ -f "$path" ] && [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

echo ""
echo "=========================================="
echo "PHASE 1: Checking what's installed"
echo "=========================================="
echo ""

# Track what needs to be installed
NEED_PACKAGES=0
NEED_DOCKER_SETUP=0
NEED_PIPX=0
NEED_VOLARE=0
NEED_PDK=0
NEED_OPENLANE=0

# Check system packages
echo "Checking system packages..."
if ! check_command iverilog "$ORIGINAL_USER" "$ORIGINAL_HOME"; then
    echo "  MISSING: iverilog"
    NEED_PACKAGES=1
else
    echo "  OK: iverilog"
fi

if ! check_command yosys "$ORIGINAL_USER" "$ORIGINAL_HOME"; then
    echo "  MISSING: yosys"
    NEED_PACKAGES=1
else
    echo "  OK: yosys"
fi

if ! check_command gtkwave "$ORIGINAL_USER" "$ORIGINAL_HOME"; then
    echo "  MISSING: gtkwave"
    NEED_PACKAGES=1
else
    echo "  OK: gtkwave"
fi

if ! check_command verilator "$ORIGINAL_USER" "$ORIGINAL_HOME"; then
    echo "  MISSING: verilator"
    NEED_PACKAGES=1
else
    echo "  OK: verilator"
fi

if ! check_command docker "$ORIGINAL_USER" "$ORIGINAL_HOME"; then
    echo "  MISSING: docker"
    NEED_PACKAGES=1
else
    echo "  OK: docker"
fi

if ! check_command klayout "$ORIGINAL_USER" "$ORIGINAL_HOME"; then
    echo "  MISSING: klayout"
    NEED_PACKAGES=1
else
    echo "  OK: klayout"
fi

# Check Docker setup
echo ""
echo "Checking Docker configuration..."
if ! groups $ORIGINAL_USER | grep -q docker; then
    echo "  MISSING: User not in docker group"
    NEED_DOCKER_SETUP=1
else
    echo "  OK: User in docker group"
fi

if [ ! -f /etc/docker/daemon.json ] || ! grep -q "/home/docker" /etc/docker/daemon.json 2>/dev/null; then
    echo "  MISSING: Docker not configured for home directory"
    NEED_DOCKER_SETUP=1
else
    echo "  OK: Docker configured"
fi

# Check Python tools
echo ""
echo "Checking Python tools..."
if ! check_command pipx "$ORIGINAL_USER" "$ORIGINAL_HOME"; then
    echo "  MISSING: pipx"
    NEED_PIPX=1
else
    echo "  OK: pipx"
fi

if ! check_command volare "$ORIGINAL_USER" "$ORIGINAL_HOME"; then
    echo "  MISSING: volare"
    NEED_VOLARE=1
else
    echo "  OK: volare"
fi

# Check PDK
echo ""
echo "Checking Sky130 PDK..."
if [ ! -d "$PDK_ROOT/sky130A" ] || [ ! -d "$PDK_ROOT/sky130A/libs.ref" ]; then
    echo "  MISSING: PDK not installed or incomplete"
    NEED_PDK=1
else
    echo "  OK: PDK installed"
fi

# Check OpenLane
echo ""
echo "Checking OpenLane Docker image..."
if ! docker images 2>/dev/null | grep -q "efabless/openlane.*2023.11.03"; then
    echo "  MISSING: OpenLane Docker image"
    NEED_OPENLANE=1
else
    echo "  OK: OpenLane Docker image"
fi

echo ""
echo "=========================================="
echo "PHASE 2: Installing missing components"
echo "=========================================="
echo ""

# Install system packages
if [ $NEED_PACKAGES -eq 1 ]; then
    echo "Installing system packages..."
    pacman -S --needed base-devel git make \
        icarus-verilog gtkwave \
        verilator yosys \
        python python-pip python-pipx \
        docker docker-compose \
        klayout
else
    echo "All system packages already installed"
fi

# Setup Docker
if [ $NEED_DOCKER_SETUP -eq 1 ]; then
    echo ""
    echo "Configuring Docker..."
    
    if ! groups $ORIGINAL_USER | grep -q docker; then
        echo "Adding user to docker group..."
        usermod -aG docker $ORIGINAL_USER
        DOCKER_GROUP_ADDED=1
    fi
    
    if [ ! -f /etc/docker/daemon.json ] || ! grep -q "/home/docker" /etc/docker/daemon.json 2>/dev/null; then
        echo "Configuring Docker to use home directory..."
        mkdir -p /etc/docker
        bash -c 'cat > /etc/docker/daemon.json << EOF
{
  "data-root": "/home/docker",
  "storage-driver": "overlay2"
}
EOF'
        mkdir -p /home/docker
        chmod 775 /home/docker
        DOCKER_RESTART_NEEDED=1
    fi
    
    if ! systemctl is-enabled docker &> /dev/null; then
        systemctl enable docker
    fi
    
    if ! systemctl is-active docker &> /dev/null; then
        systemctl start docker
    fi
else
    echo "Docker already configured"
    DOCKER_GROUP_ADDED=0
    DOCKER_RESTART_NEEDED=0
fi

# Install pipx
if [ $NEED_PIPX -eq 1 ]; then
    echo ""
    echo "Installing pipx..."
    sudo -u $ORIGINAL_USER pipx ensurepath || true
    # Source the shell config to update PATH for this session
    if [ -f "$ORIGINAL_HOME/.bashrc" ]; then
        sudo -u $ORIGINAL_USER bash -c "source $ORIGINAL_HOME/.bashrc 2>/dev/null || true"
    fi
else
    echo "pipx already installed"
fi

# Install volare
if [ $NEED_VOLARE -eq 1 ]; then
    echo ""
    echo "Installing volare..."
    sudo -u $ORIGINAL_USER pipx install volare
else
    echo "volare already installed"
fi

# Install PDK
if [ $NEED_PDK -eq 1 ]; then
    echo ""
    echo "Installing Sky130 PDK (this takes 10-20 minutes)..."
    
    # Remove incomplete installation if exists
    if [ -d "$PDK_ROOT/sky130A" ] && [ ! -d "$PDK_ROOT/sky130A/libs.ref" ]; then
        echo "Removing incomplete PDK installation..."
        rm -rf "$PDK_ROOT/sky130A"
    fi
    
    mkdir -p "$PDK_ROOT"
    cd "$PDK_ROOT"
    
    # Find volare
    VOLARE_CMD=$(get_command_path volare "$ORIGINAL_USER" "$ORIGINAL_HOME")
    if [ -z "$VOLARE_CMD" ]; then
        echo "Error: volare not found after installation"
        exit 1
    fi
    
    export PDK_ROOT="$PDK_ROOT"
    sudo -u $ORIGINAL_USER bash -c "export PDK_ROOT='$PDK_ROOT' && $VOLARE_CMD enable --pdk sky130 --pdk-root '$PDK_ROOT' bdc9412b3e468c102d01b7cf6337be06ec6e9c9a"
    
    if [ ! -d "$PDK_ROOT/sky130A" ]; then
        echo "Error: PDK installation failed"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
else
    echo "PDK already installed"
fi

# Download OpenLane
if [ $NEED_OPENLANE -eq 1 ]; then
    echo ""
    echo "Downloading OpenLane Docker image (this may take 5-15 minutes)..."
    docker pull efabless/openlane:2023.11.03
else
    echo "OpenLane Docker image already downloaded"
fi

echo ""
echo "=========================================="
echo "PHASE 3: Final verification"
echo "=========================================="
echo ""

ERRORS=0

# Verify system packages
echo "Verifying system packages..."
for cmd in iverilog vvp yosys gtkwave; do
    if check_command $cmd "$ORIGINAL_USER" "$ORIGINAL_HOME"; then
        echo "  OK: $cmd"
    else
        echo "  ERROR: $cmd not found"
        ERRORS=$((ERRORS + 1))
    fi
done

# Verify Docker
echo ""
echo "Verifying Docker..."
if check_command docker "$ORIGINAL_USER" "$ORIGINAL_HOME"; then
    echo "  OK: docker installed"
    if docker info &> /dev/null; then
        echo "  OK: docker daemon running"
    else
        if [ $DOCKER_GROUP_ADDED -eq 1 ]; then
            echo "  WARNING: docker daemon not running - need to logout/login or run: newgrp docker"
        else
            echo "  WARNING: docker daemon not running"
        fi
    fi
else
    echo "  ERROR: docker not found"
    ERRORS=$((ERRORS + 1))
fi

# Verify Python tools
echo ""
echo "Verifying Python tools..."
if check_command pipx "$ORIGINAL_USER" "$ORIGINAL_HOME"; then
    PIPX_PATH=$(get_command_path pipx "$ORIGINAL_USER" "$ORIGINAL_HOME")
    echo "  OK: pipx installed at $PIPX_PATH"
else
    echo "  ERROR: pipx not found"
    ERRORS=$((ERRORS + 1))
fi

if check_command volare "$ORIGINAL_USER" "$ORIGINAL_HOME"; then
    VOLARE_PATH=$(get_command_path volare "$ORIGINAL_USER" "$ORIGINAL_HOME")
    echo "  OK: volare installed at $VOLARE_PATH"
else
    echo "  ERROR: volare not found"
    ERRORS=$((ERRORS + 1))
fi

# Verify PDK
echo ""
echo "Verifying Sky130 PDK..."
if [ -d "$PDK_ROOT/sky130A" ] && [ -d "$PDK_ROOT/sky130A/libs.ref" ]; then
    echo "  OK: PDK installed at $PDK_ROOT/sky130A"
else
    echo "  ERROR: PDK not found or incomplete"
    ERRORS=$((ERRORS + 1))
fi

# Verify OpenLane
echo ""
echo "Verifying OpenLane Docker image..."
if docker images 2>/dev/null | grep -q "efabless/openlane.*2023.11.03"; then
    echo "  OK: OpenLane Docker image found"
else
    echo "  ERROR: OpenLane Docker image not found"
    ERRORS=$((ERRORS + 1))
fi

# Verify project files
echo ""
echo "Verifying project files..."
cd "$PROJECT_DIR"
if [ -d "rtl" ] && [ -n "$(ls -A rtl/*.sv 2>/dev/null)" ]; then
    echo "  OK: RTL files found"
else
    echo "  ERROR: RTL files not found"
    ERRORS=$((ERRORS + 1))
fi

if [ -d "test/unit" ] && [ -n "$(ls -A test/unit/*.sv 2>/dev/null)" ]; then
    echo "  OK: Test files found"
else
    echo "  ERROR: Test files not found"
    ERRORS=$((ERRORS + 1))
fi

if [ -d "scripts" ] && [ -f "scripts/test_all.sh" ]; then
    echo "  OK: Scripts found"
else
    echo "  ERROR: Scripts not found"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "=================================================="
if [ $ERRORS -eq 0 ]; then
    echo "Setup complete! All checks passed."
    echo "=================================================="
    echo ""
    if [ $DOCKER_GROUP_ADDED -eq 1 ] || [ $DOCKER_RESTART_NEEDED -eq 1 ]; then
        echo "IMPORTANT: You need to logout and login again for Docker"
        echo "group changes to take effect. Alternatively, run:"
        echo "  newgrp docker"
        echo ""
    fi
    echo "You can now run:"
    echo "  ./scripts/test_all.sh        # Run all tests"
    echo "  ./scripts/simulate.sh        # Run simulation"
    echo "  ./scripts/run_openlane.sh    # Generate GDSII"
    echo ""
else
    echo "Setup completed with $ERRORS error(s)."
    echo "=================================================="
    echo ""
    echo "Please review the errors above and fix them."
    echo "You may need to:"
    echo "  - Run the script again"
    echo "  - Logout and login for Docker group changes"
    echo "  - Check your internet connection for downloads"
    echo ""
    exit 1
fi
