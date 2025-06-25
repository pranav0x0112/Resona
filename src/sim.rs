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
            self.cpu.step(instr);

            self.cpu.pc += 4;

            if self.cpu.pc > self.mem.data.len() as u32 {
                break;
            }
        }
    }
}