# ============================================================
# ModelSim Do File — tb_branch_call_interrupt
# Tests: JZ, JN, JC, JMP, CALL, RET, INT, RTI, hardware interrupt
# ============================================================

# --- Compile ---
if {![file exists work]} {
    vlib work
}
vmap work work

file copy -force tb_branch.mem test.mem

vcom -2008 *.vhd


# --- Simulate ---
vsim -t ps work.tb_branch

# ============================================================
# Wave Setup
# ============================================================
view wave

# --- Clock & Control ---
add wave -divider "=== CONTROL ==="
add wave -label "CLK"       /tb_branch/processor/clk_input
add wave -label "Reset"     /tb_branch/reset
add wave -label "Interrupt" /tb_branch/interrupt

# --- I/O Ports ---
add wave -divider "=== I/O ==="
add wave -label "IN.port"  -hex /tb_branch/input_port
add wave -label "OUT.port" -hex /tb_branch/output_port

# ── Special Registers ────────────────────────────────────────
add wave -divider "Special Registers"
add wave -label "PC"        -radix hex sim:tb_branch/processor/FetchMem_comp/pc_component/q
add wave -label "SP"        -radix hex sim:tb_branch/processor/ex1_comp/sp_inst/q

# ── Flags (CCR) ──────────────────────────────────────────────
add wave -divider "Flags"
add wave -label "Z (Zero)"     sim:tb_branch/processor/ex1_comp/ccr_main/Z_reg
add wave -label "N (Negative)" sim:tb_branch/processor/ex1_comp/ccr_main/N_reg
add wave -label "C (Carry)"    sim:tb_branch/processor/ex1_comp/ccr_main/C_reg

# ── General Purpose Registers R0-R7 ──────────────────────────
add wave -divider "Registers"
add wave -label "R0" -radix hex sim:tb_branch/processor/decode_comp/regfile/q_regs(0)
add wave -label "R1" -radix hex sim:tb_branch/processor/decode_comp/regfile/q_regs(1)
add wave -label "R2" -radix hex sim:tb_branch/processor/decode_comp/regfile/q_regs(2)
add wave -label "R3" -radix hex sim:tb_branch/processor/decode_comp/regfile/q_regs(3)
add wave -label "R4" -radix hex sim:tb_branch/processor/decode_comp/regfile/q_regs(4)
add wave -label "R5" -radix hex sim:tb_branch/processor/decode_comp/regfile/q_regs(5)
add wave -label "R6" -radix hex sim:tb_branch/processor/decode_comp/regfile/q_regs(6)
add wave -label "R7" -radix hex sim:tb_branch/processor/decode_comp/regfile/q_regs(7)

# --- Branch & Call signals (useful for tracing control flow) ---
add wave -divider "=== CONTROL FLOW ==="
add wave -label "do_branch"   /tb_branch/processor/do_branch
add wave -label "call_signal" /tb_branch/processor/call_signal_id_ex_out
add wave -label "int_signal"  /tb_branch/processor/int_signal_id_ex_out
add wave -label "PC target"   -hex /tb_branch/processor/pc_plus_immediate

# ============================================================
# Run — long enough to cover hardware interrupt at ~63 cycles
# ============================================================
wave zoom full
configure wave -namecolwidth  160
configure wave -valuecolwidth 100
configure wave -justifyvalue  left
configure wave -signalnamewidth 1

run 30000 ps
wave zoom full
