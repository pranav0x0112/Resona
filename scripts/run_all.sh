#!/bin/bash
echo "[+] Running all compiled kernels with Resona..."

for binfile in test/bins/*.bin; do
    echo
    echo "====== Running $(basename "$binfile") ======"
    cargo run -- "$binfile"
done