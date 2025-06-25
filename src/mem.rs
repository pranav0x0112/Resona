pub struct Memory {
    pub data: Vec<u8>,
}

impl Memory {
    pub fn new(size: usize) -> Self {
        Memory { data: vec![0; size] }
    }

    pub fn load_binary(&mut self, path: &str) {
        let bytes = std::fs::read(path).expect("Failed to read binary");
        self.data[..bytes.len()].copy_from_slice(&bytes);
    }

    pub fn read_u32(&self, addr: usize) -> u32 {
        let b = &self.data[addr..addr + 4];
        u32::from_le_bytes([b[0], b[1], b[2], b[3]])
    }

    pub fn write_u32(&mut self, addr: usize, val: u32) {
        let bytes = val.to_le_bytes();
        self.data[addr..addr + 4].copy_from_slice(&bytes);
    }
}