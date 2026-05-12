library ieee;
use ieee.std_logic_1164.all;

entity tb_branch_call_interrupt_tb is
end entity;

architecture sim of tb_branch_call_interrupt_tb is
    constant CLK_PERIOD : time := 100 ps;

    signal input_port  : std_logic_vector(31 downto 0) := (others => '0');
    signal reset       : std_logic := '1';
    signal interrupt   : std_logic := '0';
    signal clk_input   : std_logic := '0';
    signal output_port : std_logic_vector(31 downto 0);
    signal clk_enable  : std_logic;
begin
    clk_input <= not clk_input after CLK_PERIOD / 2;

    dut: entity work.processor
        port map (
            input_port  => input_port,
            reset       => reset,
            interrupt   => interrupt,
            clk_input   => clk_input,
            output_port => output_port,
            clk_enable  => clk_enable
        );

    stim: process
    begin
        reset <= '1';
        wait for 2 * CLK_PERIOD;
        reset <= '0';

        input_port <= x"00000030"; -- IN R1
        wait for CLK_PERIOD;
        input_port <= x"00000050"; -- IN R2
        wait for CLK_PERIOD;
        input_port <= x"00000100"; -- IN R3
        wait for CLK_PERIOD;
        input_port <= x"00000300"; -- IN R4

        wait for 22 * CLK_PERIOD;
        input_port <= x"00000060"; -- IN R1

        wait for 6 * CLK_PERIOD;
        input_port <= x"00000070"; -- IN R1

        wait for 12 * CLK_PERIOD;
        input_port <= x"00000700"; -- IN R6

        wait for 20 * CLK_PERIOD;
        interrupt <= '1';
        input_port <= x"00000005"; -- interrupt handler IN R7
        wait for CLK_PERIOD;
        interrupt <= '0';

        wait for 220 * CLK_PERIOD;
        assert false report "tb_branch_call_interrupt_tb finished" severity note;
        wait;
    end process;
end architecture;
