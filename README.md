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

## Verified on real programs

This assembler has no label support — branch/jump immediates are raw
signed byte offsets, computed by hand from each instruction's index
(`instruction_index * 4`). The seven programs below were each hand-laid-out
this way, assembled, run through the full pipeline (hazard detection,
forwarding, and branch prediction all active), and their register/memory
state checked against the hand-computed expected result. All seven passed.

| # | Program | Exercises | Result |
|---|---|---|---|
| 1 | Bubble sort | nested loops, forward + backward branches, load/store pairs | `[5,3,4,1,2]` → `[1,2,3,4,5]` |
| 2 | Sum of an array | single loop, accumulation, load | `10+20+30+40+50 = 150` |
| 3 | Iterative factorial | loop, `mul` | `6! = 720` |
| 4 | Iterative Fibonacci | loop, running-pair update, array store | `[0,1,1,2,3,5,8,13]` |
| 5 | Linear search | loop with early-exit branch, forward jump | found `40` at index `2` |
| 6 | In-place array reversal | two-pointer loop (inc + dec) | `[1,2,3,4,5]` → `[5,4,3,2,1]` |
| 7 | GCD (Euclidean algorithm) | loop, `rem` | `gcd(48,18) = 6` |
| 8 | Mixed compressed (RVC) / 32-bit stream | mixed PC+2/PC+4 fetch, `c.lw`/`c.sw`, compressed backward branch (`c.bnez`) and forward jump (`c.j`) | see below |

<details>
<summary>1. Bubble sort — click to expand</summary>

```python
assembly = [
    # x1=base x2=n x3=i x4=j x5=addr-ptr x6/x7=arr[j]/arr[j+1] x9=n-1 x10=inner bound
    "addi x1, x0, 0",           # idx0:  base = 0

    "addi x6, x0, 5",  "sw x6, 0(x1)",   # idx1-2:  arr[0]=5
    "addi x6, x0, 3",  "sw x6, 4(x1)",   # idx3-4:  arr[1]=3
    "addi x6, x0, 4",  "sw x6, 8(x1)",   # idx5-6:  arr[2]=4
    "addi x6, x0, 1",  "sw x6, 12(x1)",  # idx7-8:  arr[3]=1
    "addi x6, x0, 2",  "sw x6, 16(x1)",  # idx9-10: arr[4]=2

    "addi x9, x0, 4",            # idx11: n-1 = 4
    "addi x3, x0, 0",            # idx12: i = 0

    # OUTER (idx13)
    "bge x3, x9, 60",            # idx13: if i>=n-1 goto END
    "sub x10, x9, x3",           # idx14: inner bound = (n-1) - i
    "addi x4, x0, 0",            # idx15: j = 0
    "addi x5, x1, 0",            # idx16: addr = base

    # INNER (idx17)
    "bge x4, x10, 36",           # idx17: if j>=bound goto INNER_END
    "lw x6, 0(x5)",              # idx18: x6 = arr[j]
    "lw x7, 4(x5)",              # idx19: x7 = arr[j+1]
    "bge x7, x6, 12",            # idx20: if arr[j+1]>=arr[j] goto NOSWAP
    "sw x7, 0(x5)",              # idx21: swap: arr[j] = old arr[j+1]
    "sw x6, 4(x5)",              # idx22: swap: arr[j+1] = old arr[j]

    # NOSWAP (idx23)
    "addi x4, x4, 1",            # idx23: j++
    "addi x5, x5, 4",            # idx24: addr += 4
    "jal x0, -32",               # idx25: goto INNER

    # INNER_END (idx26)
    "addi x3, x3, 1",            # idx26: i++
    "jal x0, -56",                # idx27: goto OUTER
    # END (idx28) falls into zeroed memory, harmless.
]
```
Verified: `datamem[0..4] = 1, 2, 3, 4, 5`.
</details>

<details>
<summary>2. Sum of an array — click to expand</summary>

```python
assembly = [
    "addi x1, x0, 0",
    "addi x6, x0, 10", "sw x6, 0(x1)",
    "addi x6, x0, 20", "sw x6, 4(x1)",
    "addi x6, x0, 30", "sw x6, 8(x1)",
    "addi x6, x0, 40", "sw x6, 12(x1)",
    "addi x6, x0, 50", "sw x6, 16(x1)",
    "addi x2, x0, 5",    # n
    "addi x3, x0, 0",    # i
    "addi x4, x0, 0",    # sum
    "addi x5, x1, 0",    # addr
    "bge x3, x2, 24",    # LOOP: if i>=n goto END
    "lw x6, 0(x5)",
    "add x4, x4, x6",    # sum += arr[i]
    "addi x3, x3, 1",    # i++
    "addi x5, x5, 4",    # addr += 4
    "jal x0, -20",       # goto LOOP
    "sw x4, 20(x1)",     # END: store sum
]
```
Verified: `x4 = 150`, `datamem[5] = 150`.
</details>

<details>
<summary>3. Iterative factorial — click to expand</summary>

```python
assembly = [
    "addi x1, x0, 6",     # n
    "addi x2, x0, 1",     # result
    "addi x3, x0, 1",     # counter
    "addi x5, x0, 0",     # store base
    "blt x1, x3, 16",     # LOOP: if n<counter goto END
    "mul x2, x2, x3",     # result *= counter
    "addi x3, x3, 1",     # counter++
    "jal x0, -12",        # goto LOOP
    "sw x2, 0(x5)",       # END
]
```
Verified: `x2 = 720`, `datamem[0] = 720`.
</details>

<details>
<summary>4. Iterative Fibonacci — click to expand</summary>

```python
assembly = [
    "addi x1, x0, 0",     # base
    "addi x2, x0, 0",     # fib[0] = 0
    "sw x2, 0(x1)",
    "addi x3, x0, 1",     # fib[1] = 1
    "sw x3, 4(x1)",
    "addi x5, x0, 2",     # i = 2
    "addi x7, x0, 8",     # n = 8
    "addi x6, x1, 8",     # addr -> fib[2] slot
    "bge x5, x7, 32",     # LOOP: if i>=n goto END
    "add x4, x2, x3",     # c = a + b
    "sw x4, 0(x6)",
    "add x2, x0, x3",     # a = b
    "add x3, x0, x4",     # b = c
    "addi x5, x5, 1",     # i++
    "addi x6, x6, 4",
    "jal x0, -28",        # goto LOOP
]
```
Verified: `datamem[0..7] = 0, 1, 1, 2, 3, 5, 8, 13`.
</details>

<details>
<summary>5. Linear search — click to expand</summary>

```python
assembly = [
    "addi x1, x0, 0",
    "addi x6, x0, 15", "sw x6, 0(x1)",
    "addi x6, x0, 27", "sw x6, 4(x1)",
    "addi x6, x0, 40", "sw x6, 8(x1)",
    "addi x6, x0, 8",  "sw x6, 12(x1)",
    "addi x6, x0, 99", "sw x6, 16(x1)",
    "addi x2, x0, 5",     # n
    "addi x3, x0, 40",    # target
    "addi x4, x0, 0",     # i
    "addi x5, x1, 0",     # addr
    "addi x7, x0, -1",    # found_index = -1 (not-found sentinel)
    "bge x4, x2, 32",     # LOOP: if i>=n goto END
    "lw x6, 0(x5)",
    "bne x6, x3, 12",     # if arr[i]!=target goto SKIP
    "add x7, x4, x0",     # found: index = i
    "jal x0, 16",         # goto END
    "addi x4, x4, 1",     # SKIP: i++
    "addi x5, x5, 4",
    "jal x0, -28",        # goto LOOP
    "sw x7, 20(x1)",      # END
]
```
Verified: `x7 = 2`, `datamem[5] = 2`.
</details>

<details>
<summary>6. In-place array reversal — click to expand</summary>

```python
assembly = [
    "addi x1, x0, 0",
    "addi x9, x0, 1", "sw x9, 0(x1)",
    "addi x9, x0, 2", "sw x9, 4(x1)",
    "addi x9, x0, 3", "sw x9, 8(x1)",
    "addi x9, x0, 4", "sw x9, 12(x1)",
    "addi x9, x0, 5", "sw x9, 16(x1)",
    "addi x5, x1, 0",     # left ptr
    "addi x6, x1, 16",    # right ptr
    "addi x7, x0, 2",     # swap_count = n/2
    "addi x8, x0, 0",     # counter
    "bge x8, x7, 36",     # LOOP: if counter>=swap_count goto END
    "lw x9, 0(x5)",
    "lw x10, 0(x6)",
    "sw x10, 0(x5)",
    "sw x9, 0(x6)",
    "addi x5, x5, 4",     # left++
    "addi x6, x6, -4",    # right--
    "addi x8, x8, 1",
    "jal x0, -32",        # goto LOOP
]
```
Verified: `datamem[0..4] = 5, 4, 3, 2, 1`.
</details>

<details>
<summary>7. GCD (Euclidean algorithm) — click to expand</summary>

```python
assembly = [
    "addi x1, x0, 48",    # a
    "addi x2, x0, 18",    # b
    "beq x2, x0, 20",     # LOOP: if b==0 goto END
    "rem x3, x1, x2",     # t = a % b
    "add x1, x2, x0",     # a = b
    "add x2, x3, x0",     # b = t
    "jal x0, -16",        # goto LOOP
    "addi x5, x0, 0",
    "sw x1, 0(x5)",       # END: store gcd
]
```
Verified: `x1 = 6`, `datamem[0] = 6`.
</details>

<details>
<summary>8. Mixed compressed (RVC) / 32-bit stream — click to expand</summary>

Unlike the other seven, instruction byte addresses here are **not**
`idx*4` — 2-byte and 4-byte instructions are interleaved, so offsets were
tracked by hand as real cumulative widths. `c.lw`/`c.sw` require both
registers in `x8`-`x15` (the RVC-compressible register set); `c.li`/
`c.addi`/`c.j`/`c.bnez` don't have that restriction.

```python
assembly = [
    "c.li x10, 7",         # addr0  (2B): x10 = 7
    "c.li x11, 3",         # addr2  (2B): x11 = 3
    "add x12, x10, x11",   # addr4  (4B): x12 = 10
    "c.addi x12, 5",       # addr8  (2B): x12 = 15
    "c.li x13, 0",         # addr10 (2B): x13 = 0 (base addr)
    "sw x12, 0(x13)",      # addr12 (4B): mem[0] = 15
    "c.lw x14, 0(x13)",    # addr16 (2B): x14 = mem[0] = 15
    "c.addi x14, 5",       # addr18 (2B): x14 = 20
    "c.sw x14, 4(x13)",    # addr20 (2B): mem[1] = 20
    "c.li x9, 3",          # addr22 (2B): x9 = 3 (loop counter)

    # LOOP at addr24
    "c.addi x9, -1",       # addr24 (2B): x9--
    "c.bnez x9, -2",       # addr26 (2B): if x9!=0 goto addr24

    "sw x9, 8(x13)",       # addr28 (4B): mem[2] = x9 (must be 0)
    "c.j 6",               # addr32 (2B): jump to addr38, skip next 4B instr
    "addi x20, x0, 999",   # addr34 (4B): MUST be squashed (never executes)
    "addi x21, x0, 111",   # addr38 (4B): landing target, executes -> x21=111
]
```
Verified: `x9=0 x10=7 x11=3 x12=15 x13=0 x14=20`, `x20=0` (dead code
correctly squashed by `c.j`), `x21=111` (jump landed correctly),
`mem[0..2] = 15, 20, 0`.
</details>

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

