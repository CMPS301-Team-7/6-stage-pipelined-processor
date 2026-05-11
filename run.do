vcom *.vhd
vsim -gui work.processor

# ── Clock & Control ──────────────────────────────────────────
add wave -divider "Control"
add wave -label "CLK"       sim:/processor/clk
add wave -label "Reset"     sim:/processor/reset
add wave -label "Interrupt" sim:/processor/interrupt

# ── I/O Ports ────────────────────────────────────────────────
add wave -divider "I/O"
add wave -label "IN.PORT"   -radix hex sim:/processor/input_port
add wave -label "OUT.PORT"  -radix hex sim:/processor/output_port

# ── Special Registers ────────────────────────────────────────
add wave -divider "Special Registers"
add wave -label "PC"        -radix hex sim:/processor/FetchMem_comp/pc_component/q
add wave -label "SP"        -radix hex sim:/processor/ex1_comp/sp_inst/q

# ── Flags (CCR) ──────────────────────────────────────────────
add wave -divider "Flags"
add wave -label "Z (Zero)"     sim:/processor/ex1_comp/ccr_main/Z_reg
add wave -label "N (Negative)" sim:/processor/ex1_comp/ccr_main/N_reg
add wave -label "C (Carry)"    sim:/processor/ex1_comp/ccr_main/C_reg

# ── General Purpose Registers R0-R7 ──────────────────────────
add wave -divider "Registers"
add wave -label "R0" -radix hex sim:/processor/decode_comp/regfile/q_regs(0)
add wave -label "R1" -radix hex sim:/processor/decode_comp/regfile/q_regs(1)
add wave -label "R2" -radix hex sim:/processor/decode_comp/regfile/q_regs(2)
add wave -label "R3" -radix hex sim:/processor/decode_comp/regfile/q_regs(3)
add wave -label "R4" -radix hex sim:/processor/decode_comp/regfile/q_regs(4)
add wave -label "R5" -radix hex sim:/processor/decode_comp/regfile/q_regs(5)
add wave -label "R6" -radix hex sim:/processor/decode_comp/regfile/q_regs(6)
add wave -label "R7" -radix hex sim:/processor/decode_comp/regfile/q_regs(7)

# ── Simulation ───────────────────────────────────────────────
force -freeze sim:/processor/reset 1 0
force -freeze sim:/processor/clk_input 1 0, 0 {50 ps} -r 100
run

force -freeze sim:/processor/reset 0 0
force -freeze sim:/processor/input_port x"00000030" 0
run 5000
