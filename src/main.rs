mod cpu;
mod mem;
mod isa;
mod sim;

use std::env;
use sim::Simulator;

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() > 1 && args[1] == "--test-smaqa" {
        run_smaqa_test();
        return;
    }

    let bin_path = args.get(1).expect("Usage: resona <bin file>");
    let mut sim = Simulator::new();
    sim.load_binary(bin_path);
    sim.run();
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
    println!("x3 = {}", cpu.regs[3]); // Expect: 20
    println!("===================\n");
}