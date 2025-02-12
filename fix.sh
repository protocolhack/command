#!/bin/bash

LOG_FILE="debug_tinkerboard.log"
TOOLCHAIN_PATH="/home/debian/tk2/rockchip-linux-manifest/prebuilts/gcc/linux-x86/aarch64/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin"
GCC_BIN="$TOOLCHAIN_PATH/aarch64-none-linux-gnu-gcc"
AS_BIN="$TOOLCHAIN_PATH/aarch64-none-linux-gnu-as"

echo "===== Debugging Tinkerboard Build =====" | tee $LOG_FILE

# Check if toolchain exists
if [ ! -f "$GCC_BIN" ]; then
    echo "❌ GCC toolchain not found at $GCC_BIN" | tee -a $LOG_FILE
    echo "Installing missing toolchain..."
    sudo apt update && sudo apt install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
else
    echo "✅ GCC toolchain found: $GCC_BIN" | tee -a $LOG_FILE
    $GCC_BIN --version | tee -a $LOG_FILE
fi

# Check if assembler is working
if [ ! -f "$AS_BIN" ]; then
    echo "❌ Assembler (as) not found in toolchain. Checking system installation..." | tee -a $LOG_FILE
    if ! command -v aarch64-linux-gnu-as &> /dev/null; then
        echo "❌ Assembler not found. Installing binutils..." | tee -a $LOG_FILE
        sudo apt update && sudo apt install -y binutils-aarch64-linux-gnu
    else
        echo "✅ System assembler found: $(which aarch64-linux-gnu-as)" | tee -a $LOG_FILE
    fi
else
    echo "✅ Assembler found: $AS_BIN" | tee -a $LOG_FILE
    $AS_BIN --version | tee -a $LOG_FILE
fi

# Check if gcc-wrapper.py is causing issues
if grep -q "gcc-wrapper.py" "$TOOLCHAIN_PATH/../../kernel/scripts/gcc-wrapper.py"; then
    echo "⚠️ Detected gcc-wrapper.py - It might be interfering" | tee -a $LOG_FILE
    echo "Disabling gcc-wrapper.py..." | tee -a $LOG_FILE
    mv "$TOOLCHAIN_PATH/../../kernel/scripts/gcc-wrapper.py" "$TOOLCHAIN_PATH/../../kernel/scripts/gcc-wrapper.py.bak"
fi

# Set environment variables
export PATH="$TOOLCHAIN_PATH:$PATH"
export CROSS_COMPILE="$TOOLCHAIN_PATH/aarch64-none-linux-gnu-"
export ARCH=arm64

# Clean and retry build
echo "🛠️ Cleaning and rebuilding..." | tee -a $LOG_FILE
make ARCH=arm64 clean
make ARCH=arm64 mrproper
make ARCH=arm64 tinker_board_2_defconfig
make ARCH=arm64 2>&1 | tee -a $LOG_FILE

echo "✅ Debugging completed. Check $LOG_FILE for details."
