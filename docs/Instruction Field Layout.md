# Instruction Field Layout

This file is the single source of truth for bit slicing during decode.

## Global Rule

- All instructions are 32 bits wide.
- `opcode = instruction(31 downto 26)`.

## Common Register Slices

- `Rdst  = instruction(25 downto 23)`
- `Rsrc1 = instruction(22 downto 20)`
- `Rsrc2 = instruction(19 downto 17)`

These names are reused by instruction class even when one field is ignored.

## Format A: ALU R-type

Used by:
- `ADD`
- `SUB`
- `AND`
- `MOV`
- `SWAP`
- `NOT`
- `INC`

Layout:
- `31 downto 26`: opcode
- `25 downto 23`: `Rdst`
- `22 downto 20`: `Rsrc1`
- `19 downto 17`: `Rsrc2`
- `16 downto 0`: unused, must be zero

## Format B: Immediate

Used by:
- `IADD`
- `LDM`

Layout:
- `31 downto 26`: opcode
- `25 downto 23`: `Rdst`
- `22 downto 20`: `Rsrc1` for `IADD`, unused for `LDM`
- `19 downto 16`: unused
- `15 downto 0`: `Imm16`

Immediate handling:
- `IADD`: sign-extend `Imm16`
- `LDM`: zero-extend `Imm16`

## Format C: Memory Offset

Used by:
- `LDD`
- `STD`

Layout:
- `31 downto 26`: opcode
- `25 downto 23`: `Rdst` for `LDD`, `Rsrc1` for `STD`
- `22 downto 20`: `BaseRsrc`
- `19 downto 16`: unused
- `15 downto 0`: `Offset16`

Offset handling:
- sign-extend `Offset16` to 32 bits

## Format D: Branch / Jump Immediate

Used by:
- `JZ`
- `JN`
- `JC`
- `JMP`
- `CALL`

Layout:
- `31 downto 26`: opcode
- `25 downto 16`: unused
- `15 downto 0`: `Target16`

Target handling:
- branch target is a word address
- decode logic should expose a 32-bit target value derived from `Target16`

## Format E: Single Register

Used by:
- `PUSH`
- `POP`
- `IN`
- `OUT`

Layout:
- `31 downto 26`: opcode
- `25 downto 23`: register field
- `22 downto 0`: unused

Interpretation:
- `PUSH`, `OUT`: register field is a source register
- `POP`, `IN`: register field is a destination register

## Format F: No-Operand

Used by:
- `RET`
- `RTI`
- `NOP`
- `HLT`
- `SETC`

Layout:
- `31 downto 26`: opcode
- `25 downto 0`: unused

## Format G: Interrupt Index

Used by:
- `INT`

Layout:
- `31 downto 26`: opcode
- `25 downto 24`: `index`
- `23 downto 0`: unused

Allowed values:
- `00`
- `01`

Vector mapping:
- `INT 0 -> PC <- M[2]`
- `INT 1 -> PC <- M[3]`

## Decode Policy

- Unused fields must be ignored by hardware functionality.
- Unused fields should be written as zero by the assembler.
- All stage logic should use these slices, even if documentation elsewhere phrases the same format differently.
