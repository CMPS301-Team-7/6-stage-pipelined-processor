# ============================================================
# ModelSim Do File — tb_one_operand
# Tests: NOP, NOT, INC, IN, OUT, SETC, HLT
# ============================================================

# --- Compile ---
vcom -2008 *.vhd

vsim -t ps work.tb_one_operand
view wave

# --- CONTROL ---
add wave -label "--- CONTROL ---"   
add wave -label "CLK"                             /tb_one_operand/clk_input
add wave -label "Reset"                           /tb_one_operand/reset
add wave -label "Interrupt"                       /tb_one_operand/interrupt

# --- I/O ---
add wave -label "--- I/O ---"       
add wave -label "IN.port"        -hex             /tb_one_operand/input_port
add wave -label "OUT.port"       -hex             /tb_one_operand/output_port

# --- PC & SP ---
add wave -label "--- PC & SP ---"   
add wave -label "PC"             -hex             sim:tb_one_operand/processor/FetchMem_comp/pc_component/q
add wave -label "SP"             -hex             sim:tb_one_operand/processor/ex1_comp/sp_inst/q

# --- FLAGS ---
add wave -label "--- FLAGS ---"     
add wave -label "Z (Zero)"                        sim:tb_one_operand/processor/ex1_comp/ccr_main/Z_reg
add wave -label "N (Negative)"                    sim:tb_one_operand/processor/ex1_comp/ccr_main/N_reg
add wave -label "C (Carry)"                       sim:tb_one_operand/processor/ex1_comp/ccr_main/C_reg

# --- REGISTERS ---
add wave -label "--- REGISTERS ---" 
add wave -label "R0"             -hex             sim:tb_one_operand/processor/decode_comp/regfile/q_regs(0)
add wave -label "R1"             -hex             sim:tb_one_operand/processor/decode_comp/regfile/q_regs(1)
add wave -label "R2"             -hex             sim:tb_one_operand/processor/decode_comp/regfile/q_regs(2)
add wave -label "R3"             -hex             sim:tb_one_operand/processor/decode_comp/regfile/q_regs(3)
add wave -label "R4"             -hex             sim:tb_one_operand/processor/decode_comp/regfile/q_regs(4)
add wave -label "R5"             -hex             sim:tb_one_operand/processor/decode_comp/regfile/q_regs(5)
add wave -label "R6"             -hex             sim:tb_one_operand/processor/decode_comp/regfile/q_regs(6)
add wave -label "R7"             -hex             sim:tb_one_operand/processor/decode_comp/regfile/q_regs(7)

# ============================================================
# Run
# ============================================================
wave zoom full
configure wave -namecolwidth  160
configure wave -valuecolwidth 100
configure wave -justifyvalue  left
configure wave -signalnamewidth 1

run 2000 ps
wave zoom full
