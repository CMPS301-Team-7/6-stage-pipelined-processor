# 6-Stage Pipelined Processor

## Overview

6-stage pipelined processor (Von Neumann) with RISC-like ISA. Implements Fetch, Decode, EX1, EX2, Memory, Write-Back stages. Handles data forwarding and static branch prediction. Supports interrupts. Written in VHDL.

## Pipeline Stages

| Stage | Function |
|-------|----------|
| Fetch | Read instruction from memory |
| Decode | Decode, read registers, generate control |
| EX1 | ALU operation / address calculation |
| EX2 | Branch resolution, memory address |
| Memory | Load/Store access |
| Write-Back | Write result to register file |

## ISA Summary

- 8 general registers (R0-R7), PC, SP, CCR (Z,N,C)
- 26 instructions: ADD, SUB, AND, MOV, SWAP, NOT, INC, IADD, LDM, LDD, STD, JZ, JN, JC, JMP, CALL, RET, PUSH, POP, IN, OUT, NOP, HLT, SETC, INT, RTI
- 6-bit opcode (bits 31-26)

## Tools

- VHDL (Modelsim / Questa for simulation)
- EasyEDA (for schematic)

