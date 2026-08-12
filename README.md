# RISC-V Pipeline (RV32IMC)

A 5-stage pipelined RISC-V CPU core written in Verilog, implementing the
**RV32I** base integer ISA, the **M** (integer multiply/divide) extension,
and the **C** (compressed instruction) extension — RV32IMC.

## Instruction set support

### RV32I base
- R-type: `add`, `sub`, `and`, `or`, `xor`, `sll`, `srl`, `sra`, `slt`, `sltu`
- I-type: `addi`, `andi`, `ori`, `xori`, `slti`, `sltiu`, `slli`, `srli`, `srai`
- Load / Store: `lw`, `sw`
- Branches: `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`
- Jumps: `jal`, `jalr`
- Upper immediate: `lui`

### RV32M (integer multiply / divide)
`mul`, `mulh`, `mulhsu`, `mulhu`, `div`, `divu`, `rem`, `remu`

All eight use the real RISC-V encoding: R-type, opcode `0110011`,
`funct7 = 0000001`, differentiated by `funct3` — the same major opcode as
the base R-type ALU instructions. Divide-by-zero and the `INT_MIN / -1`
overflow case are handled per spec (no traps, since there's no CSR/trap
mechanism in this core — see Limitations).

### RVC (compressed, 16-bit)
`c.addi4spn`, `c.lw`, `c.sw`, `c.addi`/`c.nop`, `c.li`, `c.lui`/`c.addi16sp`,
`c.j`, `c.beqz`, `c.bnez`, `c.slli`, `c.srli`, `c.srai`, `c.andi`, `c.sub`,
`c.xor`, `c.or`, `c.and`, `c.jr`, `c.jalr`, `c.mv`, `c.add`

Compressed instructions are expanded to their full 32-bit RV32I equivalent
in hardware before entering the pipeline, so the rest of the datapath never
has to know a compressed instruction occurred (only the PC-increment logic
and instruction-boundary tracking care).

## Architecture

Classic 5-stage pipeline: **IF → ID → EX → MEM → WB**, with:

- **Hazard detection** — stalls one cycle on load-use hazards (a load
  immediately followed by a dependent instruction).
- **Forwarding** — EX/MEM and MEM/WB forwarding into EX, so back-to-back
  ALU-dependent instructions (including `mul`/`div`/etc.) run without
  stalling.
- **Dynamic branch prediction** — 2-bit saturating counters (256-entry PHT)
  plus a branch target buffer (256-entry BTB), with pipeline flush and
  correct-PC recovery on misprediction.
- **Data memory lives inside the processor** — no cache, no bus.
  `Processor.v` instantiates `Data_memory.v` directly as `datamem`;
  loads/stores resolve in a single cycle.


## File layout

All paths below are relative to `RISCV-Pipeline/`.

| File | Role |
|---|---|
| `PC.v` | Program counter register |
| `Instruction_mem.v` | Instruction memory (reads `program.mem`) |
| `Compressed_Decoder_Unit.v` | Expands 16-bit RVC instructions to 32-bit RV32I |
| `IF_ID_Register.v` | IF/ID pipeline register |
| `Decode.v` | Instruction decode / control signal generation |
| `Immediate_generator.v` | Sign-extends/assembles immediates per instruction format |
| `Register_file.v` | 32×32-bit integer register file |
| `Hazard_Detection_Unit.v` | Load-use hazard stall/flush |
| `Control_Hazard_Unit.v` | Flush on taken `jal`/`jalr` |
| `Branch_Prediction_Unit.v` | 2-bit-counter branch predictor + BTB |
| `ID_EX_Register.v` | ID/EX pipeline register |
| `Forwarding_Unit.v` | EX/MEM and MEM/WB → EX forwarding |
| `ALU.v` | Arithmetic/logic unit, incl. RV32M multiply/divide |
| `EX_MEM_Register.v` | EX/MEM pipeline register |
| `Data_memory.v` | 1024-word data memory (instantiated inside `Processor.v` as `datamem`) |
| `MEM_WB_Register.v` | MEM/WB pipeline register |
| `Processor.v` | Top-level module wiring the whole pipeline together |
| `Processor_tb.v` | Testbench: drives clock/reset, dumps register/memory state |
| `assembler.py` | Python assembler: mnemonics → `program.mem` |

## Toolchain

All source lives in the `RISCV-Pipeline/` subdirectory — `cd` into it
before running any of the commands below.

```bash
cd RISCV-Pipeline
```

### 1. Write a program
Edit the `assembly` list near the bottom of `RISCV-Pipeline/assembler.py`.
Example:

```python
assembly = [
    "addi x1, x0, 100",
    "addi x2, x0, 128",
    "lw   x3, 0(x1)",
    "addi x1, x1, 4",
    "bne x2, x1, -8",
    "mul  x7, x5, x6",
    "div  x10, x8, x9",
]
```

### 2. Assemble
```bash
python assembler.py
```
Writes `program.mem` (hex, one 16-bit halfword per line) into
`RISCV-Pipeline/` next to the script — this is what `Instruction_mem.v`
loads via `$readmemh`.

### 3. Simulate
Requires [Icarus Verilog](http://iverilog.icarus.com/). Run from inside
`RISCV-Pipeline/`:

```bash
iverilog -g2012 -o sim.out PC.v Instruction_mem.v Compressed_Decoder_Unit.v \
    IF_ID_Register.v Hazard_Detection_Unit.v Control_Hazard_Unit.v \
    Branch_Prediction_Unit.v Decode.v Immediate_generator.v Register_file.v \
    ID_EX_Register.v Forwarding_Unit.v ALU.v EX_MEM_Register.v \
    MEM_WB_Register.v Data_memory.v Processor.v Processor_tb.v

vvp sim.out
```

`Processor_tb.v` runs for 1000ns, then dumps `x1`–`x16` and a few
`datamem` words via `$display`, and writes a full waveform to
`RISCV-Pipeline/output.vcd` (viewable in GTKWave).

## Limitations

- **No CSR / Zicsr, no traps or exceptions.** Divide-by-zero and similar
  conditions return the spec-defined result value rather than trapping,
  since there's no privileged/CSR machinery to trap into.
- **No F extension** (floating point) — deliberately out of scope; adding
  it would require a second register file and either a real multiplier
  (for `fmul.s`/`fdiv.s`/fused-multiply-add) or accepting the same
  informal-M-extension shortcut this core doesn't take.
- **No atomics (A), no privileged modes, no interrupts.**
- **Single-cycle, zero-wait-state memory** — no cache, no memory-mapped
  peripherals. `Data_memory.v` is a plain 1024-word array.

