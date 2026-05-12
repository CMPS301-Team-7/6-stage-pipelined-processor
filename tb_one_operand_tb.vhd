library ieee;
use ieee.std_logic_1164.all;

entity tb_one_operand_tb is
end entity;

architecture sim of tb_one_operand_tb is
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

        wait for 3 * CLK_PERIOD;
        input_port <= x"00000005"; -- IN R1
        wait for CLK_PERIOD;
        input_port <= x"00000010"; -- IN R2

        wait for 80 * CLK_PERIOD;
        assert false report "tb_one_operand_tb finished" severity note;
        wait;
    end process;
end architecture;
