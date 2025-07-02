#!/bin/bash

set -e 

echo "Assembling all kernel .s files in test/kernels..."

export PATH=/opt/riscv/bin:$PATH

mkdir -p test/bins

for sfile in test/kernels/*.s; do
    name=$(basename "$sfile" .s)
    echo "  -> Assembling $name"
    riscv64-elf-as -march=rv32imp -o test/bins/$name.o "$sfile"
    riscv64-elf-objcopy -O binary test/bins/$name.o test/bins/$name.bin
done

echo "Done assembling."