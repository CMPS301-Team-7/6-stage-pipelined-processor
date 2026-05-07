# Instruction Set Documentation

Below is the instruction set documentation organized by category. Each entry includes:

- Instruction name
- Opcode (binary and hex)
- Instruction format (bit fields with positions)
- Pipeline stages (F = Fetch, D = Decode, EX1 = Execute-1, EX2 = Execute-2, MEM = Memory, WB = Write-Back)
- Special notes (if any)

<!-- Page 1 -->

## Category 1: ALU R-type (opcode `000xxx`)

**Category bits:** `000`

**Common format:**  
bits 31-26: opcode  
bits 25-23: Rdst  
bits 22-20: Rsrc1  
bits 19-17: Rsrc2  
bits 16-0: unused (must be 0)

**Common pipeline stages:**  
F → D → EX1 → WB  
(EX1 performs the ALU operation; no EX2, MEM needed)

| Instruction | Opcode (binary) | Opcode (hex) | Format (bits 25-0) | Stages | Notes |
|-------------|----------------|--------------|--------------------|--------|-------|
| ADD         | 000000         | 0x00         | Rdst (3), Rsrc1 (3), Rsrc2 (3), unused (17) | F, D, EX1, WB | Updates Z, N, C |
| SUB         | 000001         | 0x01         | same as ADD | F, D, EX1, WB | Updates Z, N, C |
| AND         | 000010         | 0x02         | same as ADD | F, D, EX1, WB | Updates Z, N only (no C) |
| MOV         | 000011         | 0x03         | same as ADD (Rsrc2 ignored) | F, D, EX1, WB | Moves Rsrc1 → Rdst; flags unchanged |
| SWAP        | 000100         | 0x04         | same as ADD | F, D, EX1, WB | Exchanges Rdst and Rsrc1 (Rsrc2 ignored) |

<!-- Page 2 -->

| Instruction | Opcode (binary) | Opcode (hex) | Format (bits 25-0) | Stages | Notes |
|-------------|----------------|--------------|--------------------|--------|-------|
| NOT         | 000101         | 0x05         | same as ADD (Rsrc1 is source, Rsrc2 ignored) | F, D, EX1, WB | 1's complement; updates Z, N |
| INC         | 000110         | 0x06         | same as ADD (Rsrc1 is source, Rsrc2 ignored) | F, D, EX1, WB | Increment; updates Z, N, C |

## Category 2: Immediate (opcode `001xxx`)

**Category bits:** `001`

**Common format:**  
bits 31-26: opcode  
bits 25-23: Rdst  
bits 22-20: Rsrc (for IADD; for LDM this field is ignored, set to 0)  
bits 19-16: Unused (set to 0)  
bits 15-0: Immediate (16 bits)

**Common pipeline stages:**  
- IADD: F → D → EX1 → WB (EX1 performs addition with immediate)  
- LDM: F → D → EX1 → WB (EX1 just passes immediate, no ALU op)

| Instruction | Opcode (binary) | Opcode (hex) | Format (bits 25-0) | Stages | Notes |
|-------------|----------------|--------------|--------------------|--------|-------|
| IADD        | 001000         | 0x08         | Rdst (3), Rsrc (3), imm16 (16), unused (4) | F, D, EX1, WB | Updates Z, N, C |
| LDM         | 001001         | 0x09         | Rdst (3), unused (3), imm16 (16), unused (4) | F, D, EX1, WB | Loads 16-bit immediate (zero-extended to 32 bits) into Rdst |

<!-- Page 3 -->

## Category 3: Memory Offset (opcode `010xxx`)

**Category bits:** `010`

**Common format:**  
bits 31-26: opcode  
bits 25-23: Rdst (LDD) or Rsrc1 (STD)  
bits 22-20: BaseRsrc  
bits 19-16: Unused (Set to 0)  
bits 15-0: Offset (16 bits)

**Pipeline stages:**  
- LDD: F → D → EX2 (address calculation done, passes to MEM) → MEM (memory read) → WB (write to Rdst)  
- STD: F → D → EX2 (address ready) → MEM (memory write) → WB (none)

| Instruction | Opcode (binary) | Opcode (hex) | Format (bits 25-0) | Stages | Notes |
|-------------|----------------|--------------|--------------------|--------|-------|
| LDD         | 010000         | 0x10         | Rdst (3), BaseRsrc (3), offset (16), unused (4) | F, D, EX2, MEM, WB | Offset sign-extended to 32 bits |
| STD         | 010001         | 0x11         | Rsrc1 (3), BaseRsrc (3), offset (16), unused (4) | F, D, EX2, MEM | Stores Rsrc1 to memory |

## Category 4: Branch (opcode `011xxx`)

**Category bits:** `011`

**Common format:**  
bits 31-26: opcode  
bits 25-16: Unused (Set to 0)  
bits 15-0: Immediate (16 bits, target address)

**Pipeline stages:**  
F → D → EX1 (evaluate condition, e.g., check Z flag) → EX2 (resolve branch: update PC if taken)

<!-- Page 4 -->

**Control hazard:** Branch resolution in EX2 means two instructions already fetched (in EX1 and D) may need to be flushed if branch taken. Static branch prediction required. Predict not-taken for simplicity, flush if taken.

| Instruction | Opcode (binary) | Opcode (hex) | Format (bits 25-0) | Stages | Notes |
|-------------|----------------|--------------|--------------------|--------|-------|
| JZ          | 011000         | 0x18         | imm16 (16) at bits 25-10, unused (10) | F, D, EX1, EX2 | Jump if Z=1 |
| JN          | 011001         | 0x19         | same | F, D, EX1, EX2 | Jump if N=1 |
| JC          | 011010         | 0x1A         | same | F, D, EX1, EX2 | Jump if C=1 |
| JMP         | 011011         | 0x1B         | same | F, D, EX1, EX2 | Unconditional jump |

## Category 5: Stack & Call (opcode `100xxx`)

**Category bits:** `100`

### PUSH
- **Opcode:** `100000` (0x20)
- **Format:** bits 31-26: opcode, bits 25-23: Rsrc, bits 22-0: unused (23 bits)
- **Pipeline stages:** F → D → EX1 (X[SP] ← R[Rsrc]; SP ← SP-1) → EX2 (address = SP) → MEM (write) → WB (update SP)
- **Note:** SP update happens in WB stage. Address calculation uses current SP. Store at current SP then decrement.

### POP
- **Opcode:** `100001` (0x21)
- **Format:** bits 31-26: opcode, bits 25-23: Rdst, bits 22-0: unused
- **Pipeline stages:** F → D → EX1 (SP ← SP+1; Rdst ← M[SP]) → EX2 (address = new SP) → MEM (read) → WB (write Rdst and update SP)
- **Note:** SP update happens before memory read. Ensure correct ordering.

### CALL
- **Opcode:** `100010` (0x22)
- **Format:** same as Branch: imm16 (16) at bits 25-10, unused (10)
- **Pipeline stages:** F → D → EX1 (calculate return address = PC+1; X[SP] ← PC+1; SP ← SP-1; PC ← Imm) → EX2 (push return address, update SP) → MEM (memory write for push) → WB (SP update)
- **Note:** PC update happens in EX2 after push. This is a branch plus a memory write. Might need extra handling.

### RET
- **Opcode:** `100011` (0x23)
- **Format:** all zeros (26 bits)
- **Pipeline stages:** F → D → EX1 (SP ← SP+1; PC ← M[SP]) → EX2 (read memory address) → MEM (memory read) → WB (update PC and SP)
- **Note:** PC is updated from stack, then fetch stage restarts from new PC.

<!-- Page 5 -->

| Instruction | Opcode (binary) | Opcode (hex) | Format | Stages | Notes |
|-------------|----------------|--------------|--------|--------|-------|
| PUSH        | 100000         | 0x20         | Rsrc(3) + unused(23) | F, D, EX1, EX2, MEM, WB | SP post-decrement |
| POP         | 100001         | 0x21         | Rdst(3) + unused(23) | F, D, EX1, EX2, MEM, WB | SP pre-increment |
| CALL        | 100010         | 0x22         | imm16(16) + unused(10) | F, D, EX1, EX2, MEM, WB | Pushes return address |
| RET         | 100011         | 0x23         | all zeros | F, D, EX1, EX2, MEM, WB | Pops PC |

<!-- Page 6 is blank or contains only page number "10," - omitted -->

<!-- Page 7 -->

## Additional Instructions

| Instruction | Opcode (binary) | Opcode (hex) | Format | Stages | Notes |
|-------------|----------------|--------------|--------|--------|-------|
| IN          | 101000         | 0x28         | Rdst(3) + unused(23) | F, D, EX1, EX2, WB | Reads input port |
| OUT         | 101001         | 0x29         | Rsrc(3) + unused(23) | F, D, EX1, EX2 | Writes output port |
| NOP         | 101010         | 0x2A         | all zeros | F, D | No effect |
| HLT         | 101011         | 0x2B         | all zeros | F, D | Freezes CPU |
| SETC        | 101100         | 0x2C         | all zeros | F, D, EX1, WB | Sets carry flag |
| INT         | 101101         | 0x2D         | index(2) + unused(24) | F, D, EX1, EX2, MEM, WB | Software interrupt; pushes PC+1 onto stack, loads PC from M[index+2]; flags preserved |
| RTI         | 101110         | 0x2E         | all zeros | F, D, EX1, EX2, MEM, WB | Return from interrupt; restores flags (CCR) and PC from stack |
