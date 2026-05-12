# ============================================================
# ModelSim Do File — tb_alu_forwarding
# Tests: IN, MOV, ADD, SUB, AND, IADD, SWAP, forwarding paths
# ============================================================

# --- Compile ---
vcom -2008 *.vhd


# --- Simulate ---
vsim -t ps work.tb_two_operand

# ============================================================
# Wave Setup
# ============================================================
view wave

# --- Clock & Control ---
add wave -divider "=== CONTROL ==="
add wave -label "CLK"       /tb_two_operand/processor/clk_input
add wave -label "Reset"     /tb_two_operand/reset
add wave -label "Interrupt" /tb_two_operand/interrupt

# --- I/O Ports ---
add wave -divider "=== I/O ==="
add wave -label "IN.port"  -hex /tb_two_operand/input_port
add wave -label "OUT.port" -hex /tb_two_operand/output_port

# ── Special Registers ────────────────────────────────────────
add wave -divider "Special Registers"
add wave -label "PC"        -radix hex sim:tb_two_operand/processor/FetchMem_comp/pc_component/q
add wave -label "SP"        -radix hex sim:tb_two_operand/processor/ex1_comp/sp_inst/q

# ── Flags (CCR) ──────────────────────────────────────────────
add wave -divider "Flags"
add wave -label "Z (Zero)"     sim:tb_two_operand/processor/ex1_comp/ccr_main/Z_reg
add wave -label "N (Negative)" sim:tb_two_operand/processor/ex1_comp/ccr_main/N_reg
add wave -label "C (Carry)"    sim:tb_two_operand/processor/ex1_comp/ccr_main/C_reg

# ── General Purpose Registers R0-R7 ──────────────────────────
add wave -divider "Registers"
add wave -label "R0" -radix hex sim:tb_two_operand/processor/decode_comp/regfile/q_regs(0)
add wave -label "R1" -radix hex sim:tb_two_operand/processor/decode_comp/regfile/q_regs(1)
add wave -label "R2" -radix hex sim:tb_two_operand/processor/decode_comp/regfile/q_regs(2)
add wave -label "R3" -radix hex sim:tb_two_operand/processor/decode_comp/regfile/q_regs(3)
add wave -label "R4" -radix hex sim:tb_two_operand/processor/decode_comp/regfile/q_regs(4)
add wave -label "R5" -radix hex sim:tb_two_operand/processor/decode_comp/regfile/q_regs(5)
add wave -label "R6" -radix hex sim:tb_two_operand/processor/decode_comp/regfile/q_regs(6)
add wave -label "R7" -radix hex sim:tb_two_operand/processor/decode_comp/regfile/q_regs(7)

# --- Forwarding Signals (useful for verifying hazard resolution) ---
add wave -divider "=== FORWARDING ==="
add wave -label "ForwardA" /tb_two_operand/processor/ex1_comp/forwardA
add wave -label "ForwardB" /tb_two_operand/processor/ex1_comp/forwardB

# ============================================================
# Run
# ============================================================
wave zoom full
configure wave -namecolwidth  160
configure wave -valuecolwidth 100
configure wave -justifyvalue  left
configure wave -signalnamewidth 1

run 3000 ps
wave zoom full
