# Control Unit Truth Table
Aligned with Instruction Set Documentation

---
# Document Structure
- Step 1: Control Signal Definitions
- Step 2: Control Unit Truth Table
  - Category 1 — ALU R-type (000xxx)
  - Category 2 — Immediate (001xxx)
  - Category 3 — Memory Offset (010xxx)
  - Category 4 — Branch (011xxx)
  - Category 5 — Stack & Call (100xxx)
  - Category 6 — Special (101xxx)
---
# Step 1: Control Signal Definitions

| Signal | Width | Description |
|---|---|---|
| RegWrite | 1 | Enable write to register file (Write-Back stage) |
| MemRead | 1 | Read from data memory (Memory stage) |
| MemWrite | 1 | Write to data memory (Memory stage) |
| ALUSrc2 | 1 | ALU input B select: `0=Rsrc2`, `1=Immediate`, `X=don't-care` |
| ALUOp | 3 | ALU function: `000=ADD`, `001=SUB`, `010=AND`, `011=NOT`, `100=INC`, `101=PASS` |
| Mem2Reg | 1 | WB data select: `0=ALU result`, `1=Memory data`, `X=don't-care` |
| Branch | 1 | Conditional branch (JZ/JN/JC) — evaluate flag in EX1, resolve PC in EX2 |
| Jump | 1 | Unconditional PC redirect (JMP, CALL, RET, RTI, INT) |
| Stack | 2 | Stack operation: `00=none`, `01=PUSH`, `10=POP`, `11=CALL/RET/INT/RTI` |
| FlagsW | 1 | Write to Condition Code Register (CCR). RTI/INT also restore CCR. |

---

# Step 2: Control Unit Truth Table

---

# Category 1 — ALU R-type (000xxx)

Common format:

- bits `31-26 = opcode`
- `25-23 = Rdst`
- `22-20 = Rsrc1`
- `19-17 = Rsrc2`
- `16-0 = unused`

Pipeline:

`F → D → EX1 → WB`

> `SWAP` requires two register writes (special datapath handling).

| Mnemonic | Opcode (bin) | Opcode (hex) | RegW | MemR | MemW | ALUSrc2 | ALUOp (3-bit) | Mem2Reg | Jump En | Jump | Stack | FlagsW | Pipeline Stages |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ADD | 000000 | 0x00 | 1 | 0 | 0 | 0 | 000 (ADD) | 0 | 0 | 00 | 00 | 1 | F,D,EX1,WB |
| SUB | 000001 | 0x01 | 1 | 0 | 0 | 0 | 001 (SUB) | 0 | 0 | 00 | 00 | 1 | F,D,EX1,WB |
| AND | 000010 | 0x02 | 1 | 0 | 0 | 0 | 010 (AND) | 0 | 0 | 00 | 00 | 1 | F,D,EX1,WB |
| MOV | 000011 | 0x03 | 1 | 0 | 0 | 0 | 101 (PASS) | 0 | 0 | 00 | 00 | 0 | F,D,EX1,WB |
| SWAP | 000100 | 0x04 | 1* | 0 | 0 | 0 | 101 (PASS) | 0 | 0 | 00 | 00 | 0 | F,D,EX1,WB |
| NOT | 000101 | 0x05 | 1 | 0 | 0 | 0 | 011 (NOT) | 0 | 0 | 00 | 00 | 1 | F,D,EX1,WB |
| INC | 000110 | 0x06 | 1 | 0 | 0 | 0 | 100 (INC) | 0 | 0 | 00 | 00 | 1 | F,D,EX1,WB |

---

# Category 2 — Immediate (001xxx)

Common format:

- bits `31-26 = opcode`
- `25-23 = Rdst`
- `22-20 = Rsrc (IADD only)`
- `19-4 = Imm16`
- `3-0 = unused`

Pipeline:

`F → D → EX1 → WB`

| Mnemonic | Opcode (bin) | Opcode (hex) | RegW | MemR | MemW | ALUSrc2 | ALUOp (3-bit) | Mem2Reg | Jump En | Jump | Stack | FlagsW | Pipeline Stages |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| IADD | 001000 | 0x08 | 1 | 0 | 0 | 1 | 000 (ADD) | 0 | 0 | 00 | 00 | 1 | F,D,EX1,WB |
| LDM | 001001 | 0x09 | 1 | 0 | 0 | 1 | 101 (PASS) | 0 | 0 | 00 | 00 | 0 | F,D,EX1,WB |

---

# Category 3 — Memory Offset (010xxx)

Format:

- `25-23 = Rdst/Rsrc1`
- `22-20 = BaseRsrc`
- `19-4 = offset16 (signed)`
- `3-0 = unused`

`STD` has no WB stage.

| Mnemonic | Opcode (bin) | Opcode (hex) | RegW | MemR | MemW | ALUSrc2 | ALUOp (3-bit) | Mem2Reg | Jump En | Jump | Stack | FlagsW | Pipeline Stages |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| LDD | 010000 | 0x10 | 1 | 1 | 0 | 1 | 000 (ADD) | 1 | 0 | 00 | 00 | 0 | F,D,EX1,EX2,MEM,WB |
| STD | 010001 | 0x11 | 0 | 0 | 1 | 1 | 000 (ADD) | X | 0 | 00 | 00 | 0 | F,D,EX1,EX2,MEM |

---

# Category 4 — Branch (011xxx)

Format:

- `25-10 = imm16 (target address)`
- `9-0 = unused`

Branch resolves in EX2; 2 instructions may be flushed if taken.

Recommended strategy: **predict-not-taken**

| Mnemonic | Opcode (bin) | Opcode (hex) | RegW | MemR | MemW | ALUSrc2 | ALUOp (3-bit) | Mem2Reg | Jump En | Jump | Stack | FlagsW | Pipeline Stages |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| JZ | 011000 | 0x18 | 0 | 0 | 0 | X | — (cond) | X | 1 | 00 | 00 | 0 | F,D,EX1,EX2 |
| JN | 011001 | 0x19 | 0 | 0 | 0 | X | — (cond) | X | 1 | 01 | 00 | 0 | F,D,EX1,EX2 |
| JC | 011010 | 0x1A | 0 | 0 | 0 | X | — (cond) | X | 1 | 10 | 00 | 0 | F,D,EX1,EX2 |
| JMP | 011011 | 0x1B | 0 | 0 | 0 | X | — | X | 1 | 11 | 00 | 0 | F,D,EX1,EX2 |

---

# Category 5 — Stack & Call (100xxx)

- `PUSH`: store at `M[SP]`, then `SP--`
- `POP`: `SP++` first, then read `M[SP]`
- `CALL`: pushes `PC+1` then jumps
- `RET`: pops `PC`
- `SP` update occurs in WB

| Mnemonic | Opcode (bin) | Opcode (hex) | RegW | MemR | MemW | ALUSrc2 | ALUOp (3-bit) | Mem2Reg | Jump En | Jump | Stack | FlagsW | Pipeline Stages |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| PUSH | 100000 | 0x20 | 0 | 0 | 1 | 0 | 101 (PASS) | X | 0 | 00 | 01 | 0 | F,D,EX1,EX2,MEM,WB |
| POP | 100001 | 0x21 | 1 | 1 | 0 | X | — | 1 | 0 | 00 | 10 | 0 | F,D,EX1,EX2,MEM,WB |
| CALL | 100010 | 0x22 | 0 | 0 | 1 | X | — | X | 1 | 00 | 11 | 0 | F,D,EX1,EX2,MEM,WB |
| RET | 100011 | 0x23 | 0 | 1 | 0 | X | — | X | 1 | 00 | 11 | 0 | F,D,EX1,EX2,MEM,WB |

---

# Category 6 — Special (101xxx)

- `IN/OUT` use I/O ports (no memory access)
- `HLT` freezes clock
- `SETC` sets carry only
- `INT` pushes `PC+1`, loads `PC` from vector table
- `RTI` pops `PC` and restores CCR

| Mnemonic | Opcode (bin) | Opcode (hex) | RegW | MemR | MemW | ALUSrc2 | ALUOp (3-bit) | Mem2Reg | Jump En | Jump | Stack | FlagsW | Pipeline Stages |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| IN | 101000 | 0x28 | 1 | 0 | 0 | 0 | 101 (PASS) | 0 | 0 | 00 | 00 | 0 | F,D,EX1,EX2,WB |
| OUT | 101001 | 0x29 | 0 | 0 | 0 | 0 | 101 (PASS) | X | 0 | 00 | 00 | 0 | F,D,EX1,EX2 |
| NOP | 101010 | 0x2A | 0 | 0 | 0 | X | — | X | 0 | 00 | 00 | 0 | F,D |
| HLT | 101011 | 0x2B | 0 | 0 | 0 | X | — | X | 0 | 00 | 00 | 0 | F,D (halt) |
| SETC | 101100 | 0x2C | 0 | 0 | 0 | X | — | X | 0 | 00 | 00 | 1 (C) | F,D,EX1,WB |
| INT | 101101 | 0x2D | 0 | 1 | 1 | X | — | X | 1 | 00 | 11 | 0 | F,D,EX1,EX2,MEM,WB |
| RTI | 101110 | 0x2E | 0 | 1 | 0 | X | — | X | 1 | 00 | 11 | 1 | F,D,EX1,EX2,MEM,WB |

---


