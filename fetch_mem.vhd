library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch_mem is 
port (
--fetch section
-- input to processor
input_port : in std_logic_vector(31 downto 0);
clk, reset, interrupt: in std_logic;
-- input from excute section
pc_plus_immediate : in std_logic_vector(31 downto 0);
do_branch: in std_logic;
predictor_update: in std_logic;
predictor_actual_taken: in std_logic;
-- input from hazard detection
pc_enable: in std_logic;
-- output to if/id reg
instruction_d: out std_logic_vector(31 downto 0);
pc_d: out std_logic_vector(31 downto 0);
inputport_d_if_id: out std_logic_vector(31 downto 0);
predicted_taken_d: out std_logic;

--memory section
-- input from ex/mem reg
sp_q: in std_logic_vector(31 downto 0);
pc1_q: in std_logic_vector(31 downto 0);
alu_q: in std_logic_vector(31 downto 0);
inputport_q:in std_logic_vector(31 downto 0);
readdata1_q:in std_logic_vector(31 downto 0);
readdata2_q:in std_logic_vector(31 downto 0);
writeaddress1_q:in std_logic_vector(2 downto 0);
writeaddress2_q:in std_logic_vector(2 downto 0);
memtoreg_q: in std_logic;
outputenable_q: in std_logic;
regwrite1_q: in std_logic;
regwrite2_q: in std_logic;
inputenable_q:in std_logic;
memwrite_q:in std_logic;
memread_q:in std_logic;
mem_add_src_q: in std_logic;
mem_data_src_q: in std_logic;
mem_addr_in : in std_logic_vector(31 downto 0);
sp_dec_q: in std_logic;
pc_src_q: in std_logic;

-- input from assembler 
offset: in std_logic_vector(31 downto 0);

--output to mem/wb reg
memory_d: out std_logic_vector(31 downto 0);
alu_d:out std_logic_vector(31 downto 0);
inputport_d:out std_logic_vector(31 downto 0);
readdata1_d:out std_logic_vector(31 downto 0);
readdata2_d:out std_logic_vector(31 downto 0);
writeaddress1_d: out std_logic_vector(2 downto 0);
writeaddress2_d: out std_logic_vector(2 downto 0);
memtoreg_d:out std_logic;
outputenable_d:out std_logic;
regwrite1_d:out std_logic;
regwrite2_d:out std_logic;
inputenable_d:out std_logic;
-- input from decode
call_signal: in std_logic;
immediate_input: in std_logic_vector(31 downto 0);
-- output sp and dec_sp for excute section
ex_mem_sp: out std_logic_vector(31 downto 0);
ex_mem_sp_dec: out std_logic;
interrupt_signal_ex_mem: in std_logic;
int_signal: in std_logic;
index:in std_logic
);

end entity;

architecture imp of fetch_mem is
component reg_file_memory is
    port(
        clk, rst : in std_logic;
        address, instruction_address  : in std_logic_vector(31 downto 0);
        mem_write, mem_read : in std_logic;
        writedata : in std_logic_vector(31 downto 0);
        mem_output : out std_logic_vector(31 downto 0);
        mem1 : out std_logic_vector(31 downto 0);
        mem2:out std_logic_vector(31 downto 0);
        mem3:out std_logic_vector(31 downto 0);
        mem4:out std_logic_vector(31 downto 0)
    );
end component;
component pc is
    port(
        Rst,Clk: in std_logic;
        enable: in std_logic;
        pc_src: in std_logic;
        d:in std_logic_vector(31 downto 0);
        mem1: in std_logic_vector(31 downto 0);
        q:out std_logic_vector(31 downto 0)
    );
end component;
component branch_predictor is
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        fetch_is_branch : in  std_logic;
        update_en       : in  std_logic;
        actual_taken    : in  std_logic;
        predicted_taken : out std_logic
    );
end component;
signal regular_pc, pc_plus_one: std_logic_vector(31 downto 0);
signal pc_component_d, pc_component_q: std_logic_vector(31 downto 0);
signal mem_address, writedata, readdata: std_logic_vector(31 downto 0);
signal mem1,mem2,mem3,mem4: std_logic_vector(31 downto 0);
signal fetch_opcode: std_logic_vector(4 downto 0);
signal fetch_is_cond_branch, fetch_is_jump: std_logic;
signal fetch_target: std_logic_vector(31 downto 0);
signal predictor_predicted_taken, predicted_taken: std_logic;


constant RESET_INSTR : std_logic_vector(31 downto 0) := "10000" & X"000000" & "000";
constant INTERRUPT_INSTR : std_logic_vector(31 downto 0) := "10011" & X"000000" & "100";

begin
    -- mem
    memory: reg_file_memory port map (clk, reset, mem_address, pc_component_q, memwrite_q, memread_q, writedata, readdata, mem1,mem2,mem3,mem4);

    fetch_opcode <= readdata(31 downto 27);
    fetch_is_cond_branch <= '1' when fetch_opcode = "11000" or
                                     fetch_opcode = "11010" or
                                     fetch_opcode = "11011"
                            else '0';
    fetch_is_jump <= '1' when fetch_opcode = "11001"
                     else '0';
    fetch_target <= (31 downto 16 => readdata(17)) & readdata(17 downto 2);

    predictor: branch_predictor
    port map (
        clk             => clk,
        reset           => reset,
        fetch_is_branch => fetch_is_cond_branch,
        update_en       => predictor_update,
        actual_taken    => predictor_actual_taken,
        predicted_taken => predictor_predicted_taken
    );

    predicted_taken <= '1' when fetch_is_jump = '1'
                       else predictor_predicted_taken;

    -- fetch section 
    -- handling pc 
    regular_pc <= pc_plus_immediate when do_branch='1'
    else fetch_target when predicted_taken = '1'
    else pc_plus_one;

    pc_component_d <=  readdata when pc_src_q = '1' 
    else immediate_input when call_signal='1'
    else mem2 when interrupt='1'
    else mem3 when int_signal='1' and index='0'
    else mem4 when int_signal='1' and index='1'
    else regular_pc;

    pc_component: pc port map (reset, clk, pc_enable, pc_src_q, pc_component_d, mem1, pc_component_q);

    pc_plus_one <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_component_q)), 32));

    -- passing the pc to if/id reg 
    pc_d <= pc_plus_one;
    predicted_taken_d <= predicted_taken;

    -- passing the input port to if/id reg
    inputport_d_if_id <= input_port;

    -- handling the instruction
    instruction_d <= RESET_INSTR when reset = '1'
    else INTERRUPT_INSTR when interrupt = '1'
    else readdata;

    -- mem section
    -- output sp to excute section
    ex_mem_sp <= sp_q;
    ex_mem_sp_dec <= sp_dec_q;

    -- setting write data
    writedata <= pc1_q when mem_data_src_q = '1'
    else std_logic_vector(unsigned(pc1_q)-1) when interrupt_signal_ex_mem = '1'
    else readdata2_q;

    -- setting mem_address
    mem_address <= std_logic_vector(resize(unsigned(mem_addr_in(11 downto 0)), 32));
    -- setting the output to mem/wb reg
    memory_d <= readdata;
    alu_d <= alu_q;
    inputport_d <= inputport_q;
    readdata1_d <= readdata1_q;
    readdata2_d <= readdata2_q;
    writeaddress1_d <= writeaddress1_q;
    writeaddress2_d <= writeaddress2_q;
    memtoreg_d <= memtoreg_q;
    outputenable_d <= outputenable_q;
    regwrite1_d <= regwrite1_q;
    regwrite2_d <= regwrite2_q;
    inputenable_d <= inputenable_q;
end architecture imp;
