#!/bin/bash

SRC=${1:-main}
ARCH=rv32i

SRC_PATH="test/$SRC.s"
OBJ_PATH="test/$SRC.o"
ELF_PATH="test/$SRC.elf"
BIN_PATH="test/$SRC.bin"

if [ ! -f "$SRC_PATH" ]; then
  echo "File '$SRC_PATH' not found."
  exit 1
fi

echo "Assembling: $SRC_PATH -> $OBJ_PATH"
riscv32-unknown-elf-as -march=$ARCH -o $OBJ_PATH $SRC_PATH || exit 1

echo "Linking: $OBJ_PATH -> $ELF_PATH"
riscv32-unknown-elf-ld -Ttext=0x0 -o $ELF_PATH $OBJ_PATH || exit 1

echo "Converting: $ELF_PATH -> $BIN_PATH"
riscv32-unknown-elf-objcopy -O binary $ELF_PATH $BIN_PATH || exit 1

echo "Build complete: $BIN_PATH"