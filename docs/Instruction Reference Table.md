# Instruction Reference Table

This table merges the architecture, instruction-set, and control-unit markdown files into one implementation-facing reference.

| Mnemonic | Opcode | Type | Reads | Writes | Imm/Offset | Flags | Mem | Control Flow | Stack |
|---|---|---|---|---|---|---|---|---|---|
| `ADD` | `0x00` | ALU R-type | `Rsrc1`, `Rsrc2` | `Rdst` | none | `Z,N,C` write | none | sequential | none |
| `SUB` | `0x01` | ALU R-type | `Rsrc1`, `Rsrc2` | `Rdst` | none | `Z,N,C` write | none | sequential | none |
| `AND` | `0x02` | ALU R-type | `Rsrc1`, `Rsrc2` | `Rdst` | none | `Z,N` write | none | sequential | none |
| `MOV` | `0x03` | ALU R-type | `Rsrc1` | `Rdst` | none | unchanged | none | sequential | none |
| `SWAP` | `0x04` | ALU R-type | `Rdst`, `Rsrc1` | `Rdst`, `Rsrc1` | none | unchanged | none | sequential | none |
| `NOT` | `0x05` | ALU R-type | `Rsrc1` | `Rdst` | none | `Z,N` write | none | sequential | none |
| `INC` | `0x06` | ALU R-type | `Rsrc1` | `Rdst` | none | `Z,N,C` write | none | sequential | none |
| `IADD` | `0x08` | Immediate | `Rsrc` | `Rdst` | `imm16` sign-extended | `Z,N,C` write | none | sequential | none |
| `LDM` | `0x09` | Immediate | none | `Rdst` | `imm16` zero-extended | unchanged | none | sequential | none |
| `LDD` | `0x10` | Memory | `BaseRsrc` | `Rdst` | `offset16` sign-extended | unchanged | read | sequential | none |
| `STD` | `0x11` | Memory | `Rsrc1`, `BaseRsrc` | none | `offset16` sign-extended | unchanged | write | sequential | none |
| `JZ` | `0x18` | Branch | `CCR.Z` | `PC` if taken | `imm16` target | unchanged | none | conditional jump | none |
| `JN` | `0x19` | Branch | `CCR.N` | `PC` if taken | `imm16` target | unchanged | none | conditional jump | none |
| `JC` | `0x1A` | Branch | `CCR.C` | `PC` if taken | `imm16` target | unchanged | none | conditional jump | none |
| `JMP` | `0x1B` | Branch | none | `PC` | `imm16` target | unchanged | none | unconditional jump | none |
| `PUSH` | `0x20` | Stack | `Rsrc`, `SP` | `SP` | none | unchanged | write `M[SP]` | sequential | push |
| `POP` | `0x21` | Stack | `SP` | `Rdst`, `SP` | none | unchanged | read `M[SP+1]` | sequential | pop |
| `CALL` | `0x22` | Stack/Jump | `PC`, `SP` | `PC`, `SP` | `imm16` target | unchanged | write return address | unconditional jump | push |
| `RET` | `0x23` | Stack/Jump | `SP` | `PC`, `SP` | none | unchanged | read return address | unconditional jump | pop |
| `IN` | `0x28` | Special I/O | `IN.PORT` | `Rdst` | none | unchanged | no RAM access | sequential | none |
| `OUT` | `0x29` | Special I/O | `Rsrc` | `OUT.PORT` | none | unchanged | no RAM access | sequential | none |
| `NOP` | `0x2A` | Special | none | none | none | unchanged | none | sequential | none |
| `HLT` | `0x2B` | Special | none | halt state | none | unchanged | none | stop until reset | none |
| `SETC` | `0x2C` | Special | none | `CCR.C` | none | carry set only | none | sequential | none |
| `INT` | `0x2D` | Special/Interrupt | `PC`, `SP` | `PC`, `SP` | `index` | preserve/restore policy pending | vector read + stack write | software interrupt | push |
| `RTI` | `0x2E` | Special/Interrupt | `SP` | `PC`, `SP`, `CCR` | none | restore | stack read | interrupt return | pop |

## Notes

- `SWAP` is implemented through a dual-output ALU/datapath path so it can produce both register write values in the same instruction flow.
- `LDD`, `STD`, `PUSH`, `POP`, `CALL`, `RET`, `INT`, and `RTI` all cross the memory path and therefore matter for structural hazard handling.
- Conditional branches are resolved late enough to require flush support.
- Because the design uses one shared memory interface, any cycle that performs a data-memory access blocks instruction fetch for that cycle.
