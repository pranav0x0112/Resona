use crate::{cpu::Cpu, isa, mem::Memory};
use std::{thread, time::Duration};

pub struct Simulator {
    pub cpu: Cpu,
    pub mem: Memory,
}

impl Simulator {
    pub fn new() -> Self {
        Simulator {
            cpu: Cpu::new(),
            mem: Memory::new(1024 * 1024), // 1 MB RAM
        }
    }

    pub fn load_binary(&mut self, path: &str) {
        self.mem.load_binary(path);
    }

    pub fn run(&mut self) {
        loop {
            let pc = self.cpu.pc as usize;
            let raw = self.mem.read_u32(pc);
            let instr = isa::decode(raw);
            println!("pc = {:08x} | instr = {:?}", self.cpu.pc, instr);

            self.cpu.step(instr);
            thread::sleep(Duration::from_millis(300));

            println!(
                "x1 = {:3}, x2 = {:3}, x3 = {:3}\n",
                self.cpu.regs[1], self.cpu.regs[2], self.cpu.regs[3]
            );

            self.cpu.pc += 4;

            if self.cpu.pc > self.mem.data.len() as u32 {
                break;
            }
        }

        println!("\n--- Final Register Dump ---");
        for (i, reg) in self.cpu.regs.iter().enumerate() {
            println!("x{:02} = {}", i, reg);
        }
    }
}