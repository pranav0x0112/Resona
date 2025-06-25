mod cpu;
mod mem;
mod isa;
mod sim;

use std::env;
use sim::Simulator;

fn main() {
    let args: Vec<String> = env::args().collect();
    let bin_path = args.get(1).expect("Usage: resona <bin file>");

    let mut sim = Simulator::new();
    sim.load_binary(bin_path);
    sim.run();
}