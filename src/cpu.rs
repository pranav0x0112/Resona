use crate::isa::Instruction;

pub struct Cpu {
    pub regs: [u32; 32],
    pub pc: u32,
}

impl Cpu {
    pub fn new() -> Self {
        Cpu {
            regs: [0; 32],
            pc: 0,
        }
    }

    pub fn step(&mut self, instr: Instruction) {
        match instr {
            Instruction::Add { rd, rs1, rs2 } => {
                let result = self.regs[rs1] + self.regs[rs2]; 
                self.write(rd, result);
            }
            Instruction::Addi { rd, rs1, imm } => {
                let result = self.regs[rs1].wrapping_add(imm as u32);
                self.write(rd, result);
            }
            Instruction::Lui { rd, imm} => {
                self.write(rd, imm);
            }
            Instruction::Sub { rd, rs1, rs2} => {
                self.regs[rd] = self.regs[rs1].wrapping_sub(self.regs[rs2]);
            }
            Instruction::Or { rd, rs1, rs2 } => {
                self.regs[rd] = self.regs[rs1] | self.regs[rs2];
            }
            Instruction::And { rd, rs1, rs2 } => {
                self.regs[rd] = self.regs[rs1] & self.regs[rs2];
            }
            Instruction::Xori { rd, rs1, imm} => {
                self.regs[rd] = self.regs[rs1] ^ (imm as u32);
            }
            Instruction::Unknown(val) => {
                println!("Unknown instruction: 0x{:08x} @ pc=0x{:08x}", val, self.pc);
            }
        }
    }

    fn write(&mut self, reg: usize, value: u32) {
        if reg != 0 {
            self.regs[reg] = value;
        }
    }
}