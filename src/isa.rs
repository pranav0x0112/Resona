#[derive(Debug)]

pub enum Instruction {
    Add { rd: usize, rs1: usize, rs2: usize },
    Addi { rd: usize, rs1: usize, imm: i32 },
    Unknown(u32),
}

pub fn decode(inst: u32) -> Instruction {
    let opcode = inst & 0x7f;

    match opcode{
        0x33 => decode_r_type(inst),
        0x13 => decode_i_type(inst),
        _ => Instruction::Unknown(inst),
    }
}

// R type instructions

fn decode_r_type(inst: u32) -> Instruction {
    let funct3 = (inst >> 12) & 0x7;
    let funct7 = (inst >> 25) & 0x7F;
    let rd = ((inst >> 7) & 0x1F) as usize;
    let rs1 = ((inst >> 15) & 0x1F) as usize;
    let rs2 = ((inst >> 20) & 0x1F) as usize;

    match (funct3, funct7) {
        (0x0, 0x00) => Instruction::Add { rd, rs1, rs2 },
        _ => Instruction::Unknown(inst),
    }
}

// I type instructions

fn decode_i_type(inst: u32) -> Instruction {
    let funct3 = (inst >> 12) & 0x7;
    let rd = ((inst >> 7) & 0x1f) as usize;
    let rs1 = ((inst >> 15) & 0x1f) as usize;
    let imm = ((inst as i32) >> 20) as i32;

    match funct3 {
        0x0 => Instruction::Addi { rd, rs1, imm },
        _ => Instruction::Unknown(inst),
    }
}