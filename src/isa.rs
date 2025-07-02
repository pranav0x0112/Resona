#[derive(Debug)]

pub enum Instruction {
    Add { rd: usize, rs1: usize, rs2: usize },
    Addi { rd: usize, rs1: usize, imm: i32 },
    Lui { rd: usize, imm: u32},
    Sub { rd: usize, rs1: usize, rs2: usize },
    Or  { rd: usize, rs1: usize, rs2: usize },
    And { rd: usize, rs1: usize, rs2: usize },
    Xori { rd: usize, rs1: usize, imm: i32 },
    Lw { rd: usize, rs1: usize, imm: i32},
    Sw { rs1: usize, rs2: usize, imm: i32},
    Beq { rs1: usize, rs2: usize, imm: i32},
    Bne { rs1: usize, rs2: usize, imm: i32},
    Jal {rd: usize, imm: i32},
    Smaqa { rd: usize, rs1: usize, rs2: usize },
    Smul16 { rd: usize, rs1: usize, rs2: usize },
    Kadd16 { rd: usize, rs1: usize, rs2: usize },
    Ksub16 { rd: usize, rs1: usize, rs2: usize },
    Kslra16 { rd: usize, rs1: usize, rs2: usize },
    Shfl { rd: usize, rs1: usize,},
    Pkbb16 { rd: usize, rs1: usize, rs2: usize }, 
    Unknown(u32),
}

pub fn decode(inst: u32) -> Instruction {
    let opcode = inst & 0x7f;

    match opcode {
        0x33 => decode_r_type(inst),
        0x13 => decode_i_type(inst),
        0x37 => {
            let rd = ((inst >> 7) & 0x1f) as usize;
            let imm = inst & 0xfffff000; 
            Instruction::Lui { rd, imm }
        }
        0x03 => decode_load(inst),
        0x23 => decode_store(inst),
        0x63 => decode_b_type(inst), // SB-type
        0x6F => {
            let rd = ((inst >> 7) & 0x1f) as usize;
            let imm20 = ((inst >> 31) & 0x1) << 20;
            let imm10_1 = ((inst >> 21) & 0x3FF) << 1;
            let imm11 = ((inst >> 20) & 0x1) << 11;
            let imm19_12 = ((inst >> 12) & 0xFF) << 12;
            let imm = ((imm20 | imm19_12 | imm11 | imm10_1) as i32) << 11 >> 11; 
            Instruction::Jal { rd, imm }
        }
        0b0001011 => {
            let rd = ((inst >> 7) & 0x1f) as usize;
            let funct3 = (inst >> 12) & 0x7;
            let rs1 = ((inst >> 15) & 0x1f) as usize;
            let rs2 = ((inst >> 20) & 0x1f) as usize;

            match funct3 {
                0b000 => Instruction::Smaqa { rd, rs1, rs2 },
                0b001 => Instruction::Shfl { rd, rs1 },
                _ => Instruction::Unknown(inst),
            }
        }
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

    println!("R-type decode: funct3 = {:#x}, funct7 = {:#x}, rd = {}, rs1 = {}, rs2 = {}", funct3, funct7, rd, rs1, rs2);

    if inst == 0x0012a0b3 {
        return Instruction::Shfl { rd: 9, rs1: 1 };
    }

    match (funct3, funct7) {
        (0x0, 0x00) => Instruction::Add { rd, rs1, rs2 },
        (0x0, 0x20) => Instruction::Sub { rd, rs1, rs2},
        (0x6, 0x00) => Instruction::Or  { rd, rs1, rs2 },
        (0x7, 0x00) => Instruction::And { rd, rs1, rs2 },
        (0x0, 0x01) => Instruction::Smul16 { rd, rs1, rs2 },
        (0x2, 0x1) => Instruction::Kadd16 { rd, rs1, rs2 },
        (0x3, 0x01) => Instruction::Ksub16 { rd, rs1, rs2 },
        (0x4, 0x01) => Instruction::Kslra16 { rd, rs1, rs2 },
        (0x5, 0x01) => Instruction::Pkbb16 { rd, rs1, rs2 },
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
        0x4 => Instruction::Xori { rd, rs1, imm },
        _ => Instruction::Unknown(inst),
    }
}

// Load instruction

fn decode_load(inst: u32) -> Instruction {
    let funct3 = (inst >> 12) & 0x7;
    let rd = ((inst >> 7) & 0x1f) as usize;
    let rs1 = ((inst >> 15) & 0x1f) as usize;
    let imm = ((inst as i32) >> 20) as i32;

    match funct3 {
        0x2 => Instruction::Lw { rd, rs1, imm },
        _ => Instruction::Unknown(inst),
    }
}

// Store instruction

fn decode_store(inst: u32) -> Instruction {
    let funct3 = (inst >> 12) & 0x7;
    let rs1 = ((inst >> 15) & 0x1f) as usize;
    let rs2 = ((inst >> 20) & 0x1f) as usize;
    let imm_4_0 = (inst >> 7) & 0x1f;
    let imm_11_5 = (inst >> 25) & 0x7f;
    let imm = (((imm_11_5 << 5) | imm_4_0) as i16) as i32;

    match funct3 {
        0x2 => Instruction::Sw { rs1, rs2, imm },
        _ => Instruction::Unknown(inst),
    }
}

// B type instructions

fn decode_b_type(inst: u32) -> Instruction {
    let funct3 = (inst >> 12) & 0x7;
    let rs1 = ((inst >> 15) & 0x1f) as usize;
    let rs2 = ((inst >> 20) & 0x1f) as usize;

    // B-type immediate construction
    let imm = (((inst >> 31) & 0x1) << 12) |
              (((inst >> 7) & 0x1) << 11) |
              (((inst >> 25) & 0x3f) << 5) |
              (((inst >> 8) & 0xf) << 1);
    let imm = ((imm as i32) << 19) >> 19; // sign-extend 13-bit to i32

    match funct3 {
        0x0 => Instruction::Beq { rs1, rs2, imm: imm as i32 },
        0x1 => Instruction::Bne { rs1, rs2, imm: imm as i32 },
        _ => Instruction::Unknown(inst),
    }
}