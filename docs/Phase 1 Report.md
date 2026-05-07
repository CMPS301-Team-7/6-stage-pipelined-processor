# 6-Stage Pipelined Processor

**Submitted to:** Dr. Mostafa Ghouneem, Eng. Omar Qabbani, Eng. Omar Said

**Prepared by:**  
Mohammad Amr Mohammad, 1230246  
Malek Medhat Nafei, 1230237  
Marwan Amr Ahmed, 1230324  
Mostafa Mohamed Mashaly, 1230260

---

## 1. Instruction Format and Opcode Encoding

The processor uses a fixed 6-bit opcode (bits 31–26). All instructions are 32 bits wide. The remaining bits are divided into:

| Bits 31–26 | Bits 25–23 | Bits 22–20 | Bits 19–17 | Bits 16–1 | Bit 0 |
|------------|------------|------------|------------|-----------|-------|
| Opcode     | Rdst       | Rsrc1      | Rsrc2      | Imm/Offset| unused|

Unused fields are set to 0.

The opcode is split into categories (most significant three bits) that define the instruction class.

### 1.1 Opcode Categories

| Category Bits | Class               | Instructions                                      |
|---------------|---------------------|---------------------------------------------------|
| 000           | ALU R-type (RRR)    | ADD, SUB, AND, MOV, SWAP, NOT, INC               |
| 001           | Immediate           | IADD, LDM                                        |
| 010           | Memory offset       | LDD, STD                                         |
| 011           | Branch              | JZ, JN, JC, JMP                                  |
| 100           | Stack & Call        | PUSH, POP, CALL, RET                             |
| 101           | Special             | IN, OUT, NOP, HLT, SETC, INT, RTI                |

### 1.2 Complete Opcode Table

| Instruction | Opcode (binary) | Opcode (hex) | Format (bits 25–0)                              |
|-------------|----------------|--------------|--------------------------------------------------|
| ADD         | 000000         | 0x00         | Rdst(3), Rsrc1(3), Rsrc2(3), unused(17)         |
| SUB         | 000001         | 0x01         | same as ADD                                      |
| AND         | 000010         | 0x02         | same as ADD                                      |
| MOV         | 000011         | 0x03         | same as ADD (Rsrc2 ignored)                      |
| SWAP        | 000100         | 0x04         | same as ADD                                      |
| NOT         | 000101         | 0x05         | same as ADD                                      |
| INC         | 000110         | 0x06         | same as ADD                                      |
| IADD        | 001000         | 0x08         | Rdst(3), Rsrc(3), imm16(16), unused(4)           |
| LDM         | 001001         | 0x09         | Rdst(3), unused(3), imm16(16), unused(4)         |
| LDD         | 010000         | 0x10         | Rdst(3), BaseRsrc(3), offset(16), unused(4)      |
| STD         | 010001         | 0x11         | Rsrc1(3), BaseRsrc(3), offset(16), unused(4)     |
| JZ          | 011000         | 0x18         | imm16(16) at bits 25–10, unused(10)              |
| JN          | 011001         | 0x19         | same                                             |
| JC          | 011010         | 0x1A         | same                                             |
| JMP         | 011011         | 0x1B         | same                                             |
| PUSH        | 100000         | 0x20         | Rsrc(3) + unused(23)                             |
| POP         | 100001         | 0x21         | Rdst(3) + unused(23)                             |
| CALL        | 100010         | 0x22         | imm16(16) + unused(10)                           |
| RET         | 100011         | 0x23         | all zeros                                        |
| IN          | 101000         | 0x28         | Rdst(3) + unused(23)                             |
| OUT         | 101001         | 0x29         | Rsrc(3) + unused(23)                             |
| NOP         | 101010         | 0x2A         | all zeros                                        |
| HLT         | 101011         | 0x2B         | all zeros                                        |
| SETC        | 101100         | 0x2C         | all zeros                                        |
| INT         | 101101         | 0x2D         | index(2) + unused(24)                            |
| RTI         | 101110         | 0x2E         | all zeros                                        |

> **Note:** The remaining instructions (if any) follow the same pattern. The full truth table is provided in the accompanying document "Control Unit Truth Table.pdf".

---

## 2. Schematic Diagram

The complete processor schematic was designed in EasyEDA. It includes all six pipeline stages, the control unit, data memory, register file, ALU, forwarding multiplexers, hazard detection, and pipeline registers.

<center>**Figure 1:** Top-level schematic of the 6-stage pipelined processor</center>

The schematic follows the dataflow described in the next section.

---

## 3. Dataflow Interconnections and Block Sizes

### 3.1 Main Blocks and Bus Widths

| Block                | Input bus widths                                      | Output bus widths                     | Description                                  |
|----------------------|-------------------------------------------------------|---------------------------------------|----------------------------------------------|
| PC Register          | 32 (PC_next)                                          | 32 (PC)                               | Program counter                              |
| Instruction Memory   | 32 (address)                                          | 32 (instruction)                      | 4KB, read-only                               |
| Register File        | 32 (WriteData), 3 (ReadAddr1,2), 3 (Rdst_WB)         | 32 (ReadData1,2), 32 (SP_out)         | 8 GPRs + SP (handled separately)             |

### 3.2 Dataflow Summary

- **Fetch:** PC → Instruction Memory → IF/ID register. PC+4 → MUX → PC (next).
- **Decode:** IF/ID outputs → Register File (reads), Sign Extender, Control Unit, Hazard Unit. Results → ID/EX1.
- **EX1:** ID/EX1 values → Forwarding MUXes → ALU (ALUSrcB selects immediate or register). ALU output (result, flags) → EX1/EX2.
- **EX2:** ALU result (for LDD/STD address) or branch target (Immediate) → EX2/MEM. Branch condition evaluated.
- **Memory:** EX2/MEM → Data Memory (read/write) or I/O ports. Mem2Reg MUX selects WB data → MEM/WB.
- **Write-Back:** MEM/WB → Register File write port, CCR update, SP update.

All control signals (RegWrite, MemRead, MemWrite, ALUSrc2, ALUOp, Mem2Reg, Branch, Jump, StackOp, FlagsWrite) are generated by the Control Unit and flow through pipeline registers.

---

## 4. Control Unit Detailed Design

The Control Unit is a combinational logic block that takes the 6-bit opcode and produces all control signals according to the truth table below. In implementation it can be a lookup table (ROM) or a VHDL case statement.

### 4.1 Control Signals

| Signal     | Width | Meaning                                                                       |
|------------|-------|-------------------------------------------------------------------------------|
| RegWrite   | 1     | Enable register file write                                                    |
| MemRead    | 1     | Enable data memory read                                                       |
| MemWrite   | 1     | Enable data memory write                                                      |
| ALUSrc2    | 1     | ALU B input: 0 = Rsrc2, 1 = Immediate                                         |
| ALUOp      | 3     | ALU function (000=ADD, 001=SUB, 010=AND, 011=NOT, 100=INC, 101=PASS)          |
| Mem2Reg    | 1     | WB data source: 0 = ALU, 1 = Memory                                           |
| Branch     | 1     | Conditional branch (JZ/JN/JC)                                                 |
| Jump       | 1     | Unconditional jump (JMP, CALL, RET, INT, RTI)                                |
| StackOp    | 2     | 00=none, 01=PUSH, 10=POP, 11=CALL/RET/INT/RTI                                 |
| FlagsWrite | 1     | Enable CCR update                                                             |

### 4.2 Truth Table (extract – full table in attached document)

| Instruction | Opcode | RegW | MemR | MemW | ALUSrc2 | ALUOp | Mem2Reg | Jump En | Jump | StackOp | FlagsW |
|-------------|--------|------|------|------|---------|-------|---------|---------|------|---------|--------|
| ADD         | 000000 | 1    | 0    | 0    | 0       | 000   | 0       | 0       | 0    | 00      | 1      |
| LDD         | 010000 | 1    | 1    | 0    | 1       | 101   | 1       | 0       | 0    | 00      | 0      |
| JZ          | 011000 | 0    | 0    | 0    | X       | ---   | X       | 1       | 0    | 00      | 0      |
| PUSH        | 100000 | 0    | 0    | 1    | 0       | 101   | X       | 0       | 0    | 01      | 0      |
| ...         | ...    | ...  | ...  | ...  | ...     | ...   | ...     | ...     | ...  | ...     | ...    |

> **Note:** The complete truth table is provided in the accompanying document *"Control Unit Truth Table.pdf"*.

The control signals are registered at the ID/EX1 pipeline register to be used in subsequent stages.

---

## 5. Pipeline Stages Design

The processor has six stages. Each stage performs a dedicated function.

| Stage | Name        | Operation                                                                                     |
|-------|-------------|-----------------------------------------------------------------------------------------------|
| F     | Fetch       | PC → Instruction Memory, PC+4, capture in IF/ID                                               |
| D     | Decode      | Decode instruction, read register file, sign extend immediate, generate control signals, hazard detection |
| EX1   | Execute-1   | ALU operation (arithmetic/logic, address calc), flag generation                               |
| EX2   | Execute-2   | Branch resolution, address finalisation, jump target selection                                |
| M     | Memory      | Data memory access (load/store), I/O, Mem2Reg mux                                              |
| WB    | Write-Back  | Write result to register file, update CCR, update SP                                          |

**Pipeline flow:** F → D → EX1 → EX2 → M → WB

All stages advance on the rising edge of the clock, except when stalled (by hazard unit).

---

## 6. Pipeline Registers Details

We use five pipeline registers between stages. Each register holds all data and control signals needed by the downstream stage.

| Register  | Inputs (from previous stage)                                                         | Outputs (to next stage)                                                                          | Size (bits) |
|-----------|--------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|-------------|
| IF/ID     | PC, PC+4, instruction                                                                | IF_ID_PC, IF_ID_PC_plus4, IF_ID_instr                                                            | 96          |
| ID/EX1    | ReadData1, ReadData2, PC_plus4, Imm32, control_signals, Rdst, Rsrc1, Rsrc2          | ID_EX1_ReadData1, ID_EX1_ReadData2, ID_EX1_PC, ID_EX1_Imm, ID_EX1_control, ID_EX1_Rdst, ID_EX1_Rsrc1, ID_EX1_Rsrc2 | 151         |
| EX1/EX2   | ALU_result, ReadData2 (for STD), PC_plus4, Rdst, Rsrc1, Rsrc2, control              | EX1_EX2_ALU, EX1_EX2_ReadData2, EX1_EX2_PC, EX1_EX2_Rdst, EX1_EX2_Rsrc1, EX1_EX2_Rsrc2, EX1_EX2_control | 119         |
| EX2/MEM   | Mem_addr (ALU result), EX1_EX2_ReadData2, Rdst, control, Branch_taken, Jump_target   | EX2_MEM_addr, EX2_MEM_WriteData, EX2_MEM_Rdst, EX2_MEM_control, EX2_MEM_BranchTaken, EX2_MEM_JumpTarget | 114         |
| MEM/WB    | WB_data, Rdst, control (RegWrite, Mem2Reg, FlagsWrite)                               | MEM_WB_WBData, MEM_WB_Rdst, MEM_WB_RegWrite, MEM_WB_Mem2Reg, MEM_WB_FlagsWrite                   | 38          |

Each pipeline register has:
- Clock (rising edge)
- Reset (asynchronous or synchronous – clears valid bits)
- Flush (for control hazards) – clears the register to insert a bubble
- Stall (for data hazards) – holds current value (enable low)

---

## 7. Pipeline Hazards and Solutions

### 7.1 Data Hazards

**Problem:** An instruction tries to read a register that a previous instruction has not yet written back.

**Solution:** Data Forwarding (Bypassing) plus stalling for load-use hazards.

- **Forwarding paths:** From EX1, EX2, MEM, and WB outputs back to the ALU inputs (Forward MUXes A and B). The Forwarding Unit selects the most recent result (based on destination registers and write enables).

- **Load-use hazard detection:** If an LDD (MemRead=1 in EX1) has a destination that matches the source of the next instruction in Decode, the Hazard Unit inserts a stall (freezes PC and IF/ID, flushes ID/EX1) for one cycle, then forwards the loaded data from MEM.

**Implementation:** The Hazard Unit monitors MemRead_EX1 and compares Rdst_EX1 with Rsrc1_D and Rsrc2_D.

### 7.2 Control Hazards (Branches)

**Problem:** Branch resolution occurs in EX2, so two instructions after the branch are already fetched (in EX1 and Decode). If the branch is taken, they must be discarded.

**Solution:** Static branch prediction – predict not-taken.

- Default: assume branch not taken, continue fetching sequentially.
- When branch is resolved in EX2 (condition evaluated), if taken, the pipeline flushes the IF/ID and ID/EX1 registers (set their contents to NOP). The PC is updated to the branch target.
- This incurs a penalty of two cycles for a taken branch.

**Flush signals:**
- `IF_ID_Flush` (from Hazard Unit) – clears IF/ID to NOP.
- `ID_EX1_Flush` – clears ID/EX1 to NOP.

### 7.3 Structural Hazards

**Problem:** In a Von Neumann architecture, instructions and data share the same physical memory. In a 6-stage pipeline, at any given clock cycle, multiple stages are active. For example, in cycle 5:
- Fetch stage (F) reads the next instruction from memory (using PC).
- Memory stage (M) reads or writes data memory (for LDD/STD/PUSH/POP/CALL/RET/INT).

Both require access to the same memory in the same clock cycle. This is a structural hazard because the memory cannot serve two requests simultaneously.

**Solution Options:**

1. **Dual-ported memory** – Use a memory with two independent ports (one for reads, one for reads/writes). This allows simultaneous access. This is the simplest solution but may not be allowed by the project specification (the spec says "one memory" but doesn't forbid dual ports).

2. **Stall the pipeline** – When a memory instruction (LDD, STD, PUSH, POP, CALL, RET, INT) reaches the Memory stage, stall the Fetch stage for one cycle. This prevents the fetch from accessing memory while the Memory stage uses it. This reduces performance but solves the hazard.

3. **Use separate instruction and data caches** – Though the main memory is shared, caches can provide simultaneous access. This is more complex and beyond the scope of Phase 1.

**Our chosen solution:**  
We will use a **dual-ported memory** (one read port for instruction fetch, one read/write port for data access). This allows both stages to access memory simultaneously without stalling. The memory is still a single physical RAM but with two independent interfaces. This is common in pipelined processors (e.g., ARM Cortex-M).

If dual-ported memory is not permitted in the target FPGA or simulation environment, we will fall back to stalling the Fetch stage whenever a memory operation is in the Memory stage. The Hazard Detection Unit will assert `PC_Stall` and `IF_ID_Stall` for one cycle when MemRead or MemWrite is active in the Memory stage.

**Implementation note:**  
In our VHDL design, we will implement a dual-ported memory with separate clocks or with a combinational read for instruction fetch and a synchronous write for data. This removes any structural hazard without performance loss.

---

## 8. Conclusion

This Phase 1 report fully documents the 6-stage pipelined processor design, including:

- Instruction format and complete 6-bit opcode table,
- Schematic diagram (attached as Figure 1 from EasyEDA),
- Block interconnections and bus sizes,
- Control unit truth table,
- Pipeline stage descriptions,
- Pipeline register details (size, inputs, outputs),
- Hazard solutions: data forwarding + load-use stall, static branch prediction (not-taken), and flush mechanism.

All design choices are consistent with the provided ISA documentation and the control unit truth table. The design is ready for VHDL implementation in Phase 2.