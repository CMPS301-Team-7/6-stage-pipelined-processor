# Cairo University
## Faculty of Engineering
### Computer Engineering Department

**Course:** CMPS 301  
**Semester:** Spring 2026  

---

# Architecture Project

## Objective

To design and implement a simple 6-stage pipelined processor, Von Neumann architecture (One memory for program and data).

## Processor Stages

1. **Fetch Stage:** Fetches the next instruction from the memory.
2. **Decode Stage:** Decodes instruction and releases control signals.
3. **Execute-1 Stage:** ALU operations.
4. **Execute-2 Stage:** Branch decision resolution, memory LDD/STD address calculation.
5. **Memory Stage:** For accessing memory in memory operations.
6. **Write-Back Stage:** For updating the register file.

The design should conform to the ISA specification described in the following sections.

## Introduction

The processor in this project has a RISC-like instruction set architecture. There are eight 4-byte general purpose registers: **R0** through **R7**. Another two special purpose registers:
- **Program Counter (PC)**
- **Stack Pointer (SP)**; points to the top of the stack.

The initial value of SP is \( (2^{12} - 1) \).  
The memory address space is **4 KB** of 32-bit width. The data bus is **32 bits**.

When an interrupt occurs, the processor finishes the currently fetched instructions (instructions that have already entered the pipeline), then the address of the next instruction (in PC) is saved on top of the stack, and PC is loaded from **address 1** of the memory. To return from an interrupt, an **RTI** instruction loads the PC from the top of stack, and the flow of the program resumes from the instruction after the interrupted instruction. Take care of corner cases like Branching.

## ISA Specifications

### Registers

- `R[0:7]<31:0>` : Eight 32-bit general purpose registers
- `PC<31:0>` : 32-bit program counter
- `SP<31:0>` : 32-bit stack pointer
- `CCR<3:0>` : condition code register
  - `Z<0> : CCR<0>` : zero flag, changes after arithmetic, logical, or shift operations
  - `N<0> : CCR<1>` : negative flag, changes after arithmetic, logical, or shift operations
  - `C<0> : CCR<2>` : carry flag, changes after arithmetic or shift operations

### Input/Output

- `IN.PORT<31:0>` : 32-bit data input port
- `OUT.PORT<31:0>` : 32-bit data output port
- `INTR.IN<0>` : a single, non-maskable interrupt
- `RESET.IN<0>` : reset signal

---

## Instruction Set

**Notation:**  
1st operand: register  
2nd operand: register  
3rd: Result register field  
4th: Address offset (16 bit)  
5th: Immediate Value (16 bit)

> **Take Care:** Some instructions will occupy more than one memory location.

| Instruction | Mnemonic | Function |
|-------------|----------|----------|
| NOP | `NOP` | PC ← PC + 1 |
| HLT | `HLT` | Freezes CPU (No Clock Input) until a reset |
| SETC | `SETC` | C ← 1 |
| NOT | `NOT Rdst` | NOT value stored in register Rdst<br/>`R[Rdst] ← 1's Complement(R[Rdst]);`<br/>If (1's Complement(R[Rdst]) = 0): Z ← 1; else: Z ← 0;<br/>If (1's Complement(R[Rdst]) < 0): N ← 1; else: N ← 0 |
| INC | `INC Rdst` | Increment value stored in Rdst<br/>`R[Rdst] ← R[Rdst] + 1;`<br/>If ((R[Rdst] + 1) = 0): Z ← 1; else: Z ← 0;<br/>If ((R[Rdst] + 1) < 0): N ← 1; else: N ← 0<br/>Updates carry |
| OUT | `OUT Rsrc` | `OUT.PORT ← R[Rdst]` |
| IN | `IN Rdst` | `R[Rdst] ← IN.PORT` |
| MOV | `MOV Rdst, Rsrc` | Move value from register Rsrc to register Rdst |
| SWAP | `SWAP Rdst, Rsrc` | Exchange the values between 2 registers |
| ADD | `ADD Rdst, Rsrc1, Rsrc2` | Add values in Rsrc1, Rsrc2, store in Rdst, updates carry<br/>If result = 0 then Z ← 1 else Z ← 0<br/>If result < 0 then N ← 1 else N ← 0 |
| SUB | `SUB Rdst, Rsrc1, Rsrc2` | Subtract values in Rsrc1, Rsrc2, store in Rdst, updates carry<br/>If result = 0 then Z ← 1 else Z ← 0<br/>If result < 0 then N ← 1 else N ← 0 |
| AND | `AND Rdst, Rsrc1, Rsrc2` | AND values in Rsrc1, Rsrc2, store in Rdst<br/>If result = 0 then Z ← 1 else Z ← 0<br/>If result < 0 then N ← 1 else N ← 0 |
| IADD | `IADD Rdst, Rsrc, Imm` | Add Rsrc to Immediate value, store in Rdst, updates carry<br/>If result = 0 then Z ← 1 else Z ← 0<br/>If result < 0 then N ← 1 else N ← 0 |
| PUSH | `PUSH Rsrc` | `X[SP] ← R[Rdst]; SP ← SP - 1` |
| POP | `POP Rdst` | `SP ← SP + 1; R[Rdst] ← X[SP];` |
| LDM | `LDM Rdst, Imm` | Load immediate value (16 bit) to register Rdst<br/>`R[Rdst] ← Imm<15:0>` |
| LDD | `LDD Rdst, offset(Rsrc)` | Load from memory address Rsrc + offset to Rdst<br/>`R[Rdst] ← M[R[Rsrc] + offset];` |
| STD | `STD Rsrc1, offset(Rsrc2)` | Store value in Rsrc1 to memory location Rsrc2 + offset<br/>`M[R[Rsrc2] + offset] ← R[Rsrc1];` |
| JZ | `JZ Imm` | Jump if zero<br/>If (Z = 1): PC ← Imm; else (Z = 0): continue |
| JN | `JN Imm` | Jump if negative<br/>If (N = 1): PC ← Imm; else (N = 0): continue |
| JC | `JC Imm` | Jump if carry<br/>If (C = 1): PC ← Imm; else (C = 0): continue |
| JMP | `JMP Imm` | Unconditional jump<br/>`PC ← Imm` |
| CALL | `CALL Imm` | `X[SP] ← PC + 1; SP ← SP - 1; PC ← Imm` |
| RET | `RET` | `SP ← SP + 1; PC ← X[SP];` |
| INT | `INT index` | `X[SP] ← PC + 1; SP ← SP - 1; Flags reserved;`<br/>`PC ← M[index + 2]`<br/>index is either 0 or 1. |
| RTI | `RTI` | `SP ← SP + 1; PC ← X[SP]; Flags restored;` |

### Input Signals

| Signal | Operation |
|--------|-----------|
| Reset | `PC ← M[0]` (memory location of zero) |
| Interrupt | `X[SP] ← PC; SP ← SP - 1; PC ← M[1]; Flags preserved` |

---

## Phase 1 Requirement

- Instruction format of your design
- Opcode of each instruction — instruction bits details
- Schematic diagram of the processor with data flow details (using a digital tool, not hand written):
  - ALU/Registers/Memory Blocks
  - Dataflow Interconnections between Blocks & its sizes
  - Control Unit detailed design
- Pipeline stages design
- Pipeline registers details (Size, Input, Connection, ...)
- Pipeline hazards and your solution including:
  - i. Data Forwarding
  - ii. Static Branch Prediction

## Phase 2 Requirement

Implement and integrate your architecture:

- VHDL Implementation of each component of the processor
- VHDL file that integrates the different components in a single module
- Simulation Test code that reads a program file and executes it on the processor
- Setup the simulation wave: Load Memory File & Run the test program
- Assembler code that converts assembly program (Text File) into machine code according to your design (Memory File)
- Report that contains any design changes after phase1
- Report that contains pipeline hazards considered and how your design solves it

## Project Testing

You will be given different test programs. You are required to compile and load it onto the RAM and reset your processor to start executing from the memory location written in address `0000h` (PC = M[0]). Each program would test some instructions (you should notify the TA if you haven't implemented or have logical errors concerning some of the instruction set).

You **MUST** prepare a waveform using do files with the main signals showing that your processor is working correctly:
- R0–R7, PC, SP, Flags, CLK, Reset, Interrupt, IN.PORT, OUT.PORT

Show main signals only — keep wave clean. Make sure that your program can generate the programming file. **[2 marks]**

## Evaluation Criteria

- Each project will be evaluated according to the number of instructions that are implemented, and pipelining hazards handled in the design. Table below shows the evaluation criteria in detail.
- Failing to implement a working processor will nullify your project grade. No credits will be given to individual modules or a non-working processor.
- Unnecessary latching or very poor understanding of underlying hardware will be penalized.
- Individual members of the same team can have different grades; you can get a zero grade if you didn't work while the rest of the team can get full mark. Make sure you balance your work distribution.

### Table 2: Evaluation Criteria

| Marks Distribution | |
|--------------------|-------------------------|
| Instructions | 17 marks |
| Data Hazards | 1 mark |
| Structural Hazards | 1 mark |
| Control Hazards | 1 mark |
| **Bonus** | 2-bit dynamic branch prediction with address calculation in fetch — **2 marks bonus** |

## Team Members

Each team shall consist of a maximum of **four members**.

## Phase 1 Due Date

Delivery a softcopy on Google Classroom. **Week 12**. The discussion will be during the regular lab session.

## Project Due Date

Delivery a softcopy on Google Classroom. **Week 14**. The demo will be during the regular lab session.

## General Advice

1. Compile your design on regular basis (after each modification) so that you can figure out new errors early. Accumulated errors are harder to track.
2. Start by finishing a working processor that does all one-operand instructions only. Integrating early will help you find a lot of errors. You can then add each type of instructions and integrate them into the working processor.
3. Use engineering sense to backtrace the error source.
4. As much as you can, don't ignore warnings.
5. Read the transcript window messages in ModelSim carefully.
6. After each major step, and if you have a working processor, save the design before you modify it (use a versioning tool like git or svn).
7. Always save the RAM files to easily export and import them.
8. Start early and give yourself enough time for testing.
9. Integrate your components incrementally (e.g., integrate the RAM with the Registers, then integrate with them the ALU...).
10. Use coding conventions to know each signal's functionality easily.
11. Try to simulate your control signals sequence for an instruction (e.g., ADD) to know if your timing design is correct.
12. There is no problem in changing the design after phase1, but justify your changes.
13. Always reset all components at the start of the simulation.
14. Don't leave any input signal floating ("U"), set it with 0 or 1.
15. Remember that your VHDL code is a HW system (logic gates, flip-flops and wires).
16. Use DO files instead of re-forcing all inputs each time.