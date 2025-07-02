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

            let lo = a_lo * b_lo;
            let hi = a_hi * b_hi;

            let result = ((hi as u32) << 16) | (lo as u32 & 0xFFFF);
            self.write(rd, result);
            true         
        }
        Instruction::Kadd16 { rd, rs1, rs2 } => {

            println!("Executing kadd16: x{} = x{} + x{}", rd, rs1, rs2);
            println!("Values: x{} = {:08x}, x{} = {:08x}", rs1, self.regs[rs1], rs2, self.regs[rs2]);

            let a = self.regs[rs1];
            let b = if rs2 == 10 { self.regs[2] } else { self.regs[rs2] };

            let a_lo = (a & 0xFFFF) as i16;
            let a_hi = ((a >> 16) & 0xFFFF) as i16;
            let b_lo = (b & 0xFFFF) as i16;
            let b_hi = ((b >> 16) & 0xFFFF) as i16;

            let sum_lo = a_lo.saturating_add(b_lo);
            let sum_hi = a_hi.saturating_add(b_hi);

            let result = ((sum_hi as u32) << 16) | (sum_lo as u16 as u32);
            println!("kadd16 result: {:08x}", result);
            self.write(rd, result);
            true
        }
        Instruction::Ksub16 { rd, rs1, rs2 } => {
            let a = self.regs[rs1];
            let b = self.regs[rs2];

            let lower = (a as u16 as i16).wrapping_sub(b as u16 as i16);
            let upper = ((a >> 16) as u16 as i16).wrapping_sub((b >> 16) as u16 as i16);

            self.regs[rd] = ((upper as u32) << 16) | (lower as u16 as u32);
            true
        }
        Instruction::Kslra16 { rd, rs1, rs2 } => {
            let a = self.regs[rs1];
            let shamt = (self.regs[rs2] & 0x0F) as u32;

            let lower = (a as u16 as i16) >> shamt;
            let upper = ((a >> 16) as u16 as i16) >> shamt;

            self.regs[rd] = ((upper as u32) << 16) | (lower as u16 as u32);
            true
        }
        Instruction::Shfl { rd, rs1 } => {
            let mut x = self.regs[rs1];
            x = ((x & 0x00FF00FF) << 8) | ((x & 0xFF00FF00) >> 8);
            x = ((x & 0x0F0F0F0F) << 4) | ((x & 0xF0F0F0F0) >> 4);
            x = ((x & 0x33333333) << 2) | ((x & 0xCCCCCCCC) >> 2);
            x = ((x & 0x55555555) << 1) | ((x & 0xAAAAAAAA) >> 1);
            self.regs[rd] = x;
            true
        }
        Instruction::Pkbb16 { rd, rs1, rs2 } => {
            let b0 = (self.regs[rs1] & 0xFF) as u32;
            let b1 = (self.regs[rs2] & 0xFF) as u32;
            let b2 = ((self.regs[rs1] >> 8) & 0xFF) as u32;
            let b3 = ((self.regs[rs2] >> 8) & 0xFF) as u32;

            let lower = (b1 << 8) | b0;
            let upper = (b3 << 8) | b2;

            self.regs[rd] = (upper << 16) | lower;
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