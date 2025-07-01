use crate::isa::Instruction;
use crate::mem::Memory;

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

    pub fn step(&mut self, instr: Instruction, mem: &mut Memory) -> bool {
    match instr {
        Instruction::Add { rd, rs1, rs2 } => {
            let result = self.regs[rs1] + self.regs[rs2]; 
            self.write(rd, result);
            true
        }
        Instruction::Addi { rd, rs1, imm } => {
            let result = self.regs[rs1].wrapping_add(imm as u32);
            self.write(rd, result);
            true
        }
        Instruction::Lui { rd, imm } => {
            self.write(rd, imm);
            true
        }
        Instruction::Sub { rd, rs1, rs2 } => {
            self.regs[rd] = self.regs[rs1].wrapping_sub(self.regs[rs2]);
            true
        }
        Instruction::Or { rd, rs1, rs2 } => {
            self.regs[rd] = self.regs[rs1] | self.regs[rs2];
            true
        }
        Instruction::And { rd, rs1, rs2 } => {
            self.regs[rd] = self.regs[rs1] & self.regs[rs2];
            true
        }
        Instruction::Xori { rd, rs1, imm } => {
            self.regs[rd] = self.regs[rs1] ^ (imm as u32);
            true
        }
        Instruction::Lw { rd, rs1, imm } => {
            let addr = self.regs[rs1].wrapping_add(imm as u32) as usize;
            let val = mem.read_u32(addr);
            self.write(rd, val);
            true
        }
        Instruction::Sw { rs1, rs2, imm } => {
            let addr = self.regs[rs1].wrapping_add(imm as u32) as usize;
            let val = self.regs[rs2];
            mem.write_u32(addr, val);
            true
        }
        Instruction::Beq { rs1, rs2, imm } => {
            if self.regs[rs1] == self.regs[rs2] {
                self.pc = self.pc.wrapping_add(imm as u32);
                false
            } else {
                true
            }
        }
        Instruction::Bne { rs1, rs2, imm } => {
            if self.regs[rs1] != self.regs[rs2] {
                self.pc = self.pc.wrapping_add(imm as u32);
                false
            } else {
                true
            }
        }
        Instruction::Jal { rd, imm } => {
            self.write(rd, self.pc + 4);
            self.pc = self.pc.wrapping_add(imm as u32);
            return false;
        }
        Instruction::Smaqa { rd, rs1, rs2 } => {
            let a = self.regs[rs1];
            let b = self.regs[rs2];

            let mut sum = 0i32;
            for i in 0..4 {
                let a_byte = ((a >> (i * 8)) & 0xFF) as i8;
                let b_byte = ((b >> (i * 8)) & 0xFF) as i8;
                sum += a_byte as i32 * b_byte as i32;
            }
            let acc = self.regs[rd];
            self.write(rd, acc.wrapping_add(sum as u32));
            true
        }
        Instruction::Smul16 { rd, rs1, rs2 } => {
            let a = self.regs[rs1];
            let b = self.regs[rs2];

            let a_lo = (a & 0xFFFF) as i16 as i32;
            let a_hi = (a >> 16) as i16 as i32;
            let b_lo = (b & 0xFFFF) as i16 as i32;
            let b_hi = (b >> 16) as i16 as i32;

            let lo = ((a_lo as i32 * b_lo as i32) & 0xFFFF) as u32;
            let hi = ((a_hi as i32 * b_hi as i32) & 0xFFFF) as u32;

            let result = (hi << 16) | lo;
            self.write(rd, result);
            true         
        }
        Instruction::Unknown(val) => {
            println!("Unknown instruction: 0x{:08x} @ pc=0x{:08x}", val, self.pc);
            true
        }
    } 
}


    fn write(&mut self, reg: usize, value: u32) {
        if reg != 0 {
            self.regs[reg] = value;
        }
    }
}