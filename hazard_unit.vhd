library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit is
port (
    reset: in std_logic;
    id_ex_mem_read, id_ex_mem_write: in std_logic;
    ex_mem_mem_read, ex_mem_mem_write: in std_logic;
    call_signal,int_signal: in std_logic;
    rst_if_id, rst_id_ex, rst_ex1_ex2, rst_ex_mem, rst_mem_wb: out std_logic;
    branch1, branch2 : in std_logic; 
    enable_if_id, enable_id_ex, enable_ex1_ex2, enable_ex_mem, enable_mem_wb: out std_logic;
    pc_enable: out std_logic
);
end entity hazard_unit;

architecture hazard_unit_imp of hazard_unit is
begin
hazard_processs: process (reset, branch1, branch2, id_ex_mem_read, id_ex_mem_write,
                           ex_mem_mem_read, ex_mem_mem_write, call_signal, int_signal)
begin
    -- Defaults
    rst_if_id    <= '0'; rst_id_ex  <= '0'; rst_ex1_ex2 <= '0';
    rst_ex_mem   <= '0'; rst_mem_wb <= '0';
    enable_if_id <= '1'; enable_id_ex <= '1'; enable_ex1_ex2 <= '1';
    enable_ex_mem <= '1'; enable_mem_wb <= '1';
    pc_enable    <= '1';

    if reset = '1' then
        rst_if_id <= '1'; rst_id_ex <= '1'; rst_ex1_ex2 <= '1';
        rst_ex_mem <= '1'; rst_mem_wb <= '1';
        pc_enable <= '0';
    end if;

    if call_signal = '1' or int_signal = '1' then
        rst_if_id <= '1';
        pc_enable <= '0';
    end if;

    -- Structural hazard: hold fetch/decode when MEM stage is using memory.
    -- Resetting IF/ID here drops the instruction that was just fetched.
    if ex_mem_mem_read = '1' or ex_mem_mem_write = '1' then
        enable_if_id <= '0';
        pc_enable <= '0';
    end if;

    if reset = '0' and branch1 = '1' then
        rst_if_id <= '1'; rst_id_ex <= '1';
        pc_enable <= '1';
    end if;
end process;
end architecture hazard_unit_imp;
