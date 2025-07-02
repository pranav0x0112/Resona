use crate::{cpu::Cpu, isa, mem::Memory};

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

            let advance = self.cpu.step(instr, &mut self.mem);
            if advance {
                self.cpu.pc += 4;
            } else {
                println!("Unknown instruction encountered, halting execution.");
                break;
            }

            // Print key register output
            let x10 = self.cpu.regs[10] as u32;
            let lo = (x10 & 0xFFFF) as i16;
            let hi = ((x10 >> 16) & 0xFFFF) as i16;

            println!(
                "x10 = 0x{:08x}  (hi = {}, lo = {})",
                x10, hi, lo
            );

            for i in 11..=17 {
                let reg = self.cpu.regs[i];
                if reg != 0 {
                    println!("x{:02} = {}", i, reg);
                }
            }

            println!();
            if self.cpu.pc as usize >= self.mem.data.len() {
                break;
            }
        }

        // Final state
        println!("\n--- Final Register Dump ---");
        for (i, reg) in self.cpu.regs.iter().enumerate() {
            println!("x{:02} = {}", i, reg);
        }
    }
}