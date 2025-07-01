mod cpu;
mod mem;
mod isa;
mod sim;

use std::env;
use sim::Simulator;

fn main() {
    let args: Vec<String> = env::args().collect();

    match args.get(1).map(|s| s.as_str()) {
        Some("--test-smaqa") => {
            run_smaqa_test();
        }
        Some("--help") | Some("-h") => {
            print_help();
        }
        Some(path) => {
            let mut sim = Simulator::new();
            sim.load_binary(path);
            sim.run();
        }
        None => {
            eprintln!("Error: no input file provided.\n");
            print_help();
        }
    }
}

fn print_help() {
    println!("Resona - RISC-V DSP Simulator");
    println!("\nUsage:");
    println!("  cargo run -- <bin file>       Run a compiled binary file");
    println!("  cargo run -- --test-smaqa     Run a standalone test of the SMAQA instruction");
    println!("  cargo run -- --help           Show this help message");
}

fn run_smaqa_test() {
    use crate::cpu::Cpu;
    use crate::mem::Memory;
    use crate::isa::Instruction;

    let mut cpu = Cpu::new();
    let mut mem = Memory::new(4096);

    cpu.regs[1] = 0x01020304; // rs1
    cpu.regs[2] = 0x04030201; // rs2

    let instr = Instruction::Smaqa { rd: 3, rs1: 1, rs2: 2 };
    cpu.step(instr, &mut mem);

    println!("\n=== SMAQA Test ===");
    println!("x1 = 0x{:08x}", cpu.regs[1]);
    println!("x2 = 0x{:08x}", cpu.regs[2]);
    println!("x3 = {}", cpu.regs[3]);
    println!("===================\n");
}