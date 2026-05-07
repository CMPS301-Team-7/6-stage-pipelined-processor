# Implementation Decisions

This file freezes the baseline rules we will code against in Phase 2.

## 1. PC and Addressing

- `PC` is treated as a word address, not a byte address.
- Sequential execution uses `PC <- PC + 1`.
- Reset loads `PC <- M[0]`.
- External interrupt loads `PC <- M[1]`.
- Software interrupt `INT index` loads `PC <- M[index + 2]`.

Reason:
- `Architecture_Project_SP26.md` uses `PC <- PC + 1`.
- Memory is described as a 32-bit-wide memory with instruction words stored directly in memory locations.
- Project testing also starts from `M[0]`.

## 2. Memory Model

- Main memory is a single 32-bit-word memory.
- The architectural address space is 4 KB.
- We will model it as a unified Von Neumann memory for both instructions and data.
- For implementation, we will use a single shared memory interface.
- Instruction fetch must not happen in the same cycle as a data-memory access.
- When the memory stage is using memory, fetch is stalled for that cycle.

Reason:
- The architecture requires one memory for program and data.
- We are intentionally not using a dual-ported RAM.
- Structural conflicts between instruction fetch and data access are resolved by fetch-cycle stalling.

## 3. Register Set

- General-purpose registers: `R0` through `R7`, each 32 bits.
- Special registers: `PC`, `SP`, and `CCR`.
- `SP` initial value is `2^12 - 1 = 4095`.
- `CCR` active flags are:
  - `Z` at bit 0
  - `N` at bit 1
  - `C` at bit 2

## 4. Pipeline Definition

- Pipeline stages are:
  - `F`
  - `D`
  - `EX1`
  - `EX2`
  - `MEM`
  - `WB`
- Core pipeline flow is `F -> D -> EX1 -> EX2 -> MEM -> WB`.

## 5. Hazard Policy

- Conditional branches use static predict-not-taken.
- Taken branches flush younger instructions already in the pipeline.
- Data hazards use forwarding where possible.
- Load-use hazards use a one-cycle stall.
- Structural hazards are handled by stalling `PC` and `IF/ID` whenever the shared memory is busy with a data-memory operation.

## 6. Immediate and Offset Rules

- Arithmetic immediates (`IADD`) are sign-extended to 32 bits.
- Memory offsets (`LDD`, `STD`) are sign-extended to 32 bits.
- `LDM` loads the 16-bit immediate as zero-extended data into the destination register.
- Branch and jump immediates are treated as word-address targets.

## 7. Open Issues To Revisit

- `INT` and `RTI` mention flag preservation/restoration, but the docs do not fully define the exact stack layout for `CCR`.
- Some markdown tables use slightly inconsistent wording around immediate bit placement; the project will follow the unified field layout in `Instruction Field Layout.md`.

## 8. SWAP Datapath Decision

- `SWAP` will be implemented with an ALU/datapath block that exposes two result outputs instead of one.
- The first output carries the value to be written to `Rdst`.
- The second output carries the value to be written to `Rsrc1`.
- `SWAP` therefore uses a dedicated dual-write datapath path instead of pretending to be a normal single-result ALU instruction.

Reason:
- `SWAP` logically produces two architectural register updates in one instruction.
- Making that explicit in the datapath is cleaner than hiding it behind special late-stage muxing.
