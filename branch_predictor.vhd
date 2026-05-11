library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity branch_predictor is
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;
        fetch_is_branch  : in  std_logic;
        fetch_target     : in  std_logic_vector(31 downto 0);
        update_en        : in  std_logic;
        actual_taken     : in  std_logic;
        predicted_taken  : out std_logic;
        predicted_target : out std_logic_vector(31 downto 0)
    );
end entity branch_predictor;

architecture rtl of branch_predictor is
    signal counter : unsigned(1 downto 0) := "01";
begin
    predicted_taken <= '1' when fetch_is_branch = '1' and counter(1) = '1'
                       else '0';

    predicted_target <= fetch_target;

    process(clk, reset)
    begin
        if reset = '1' then
            counter <= "01";
        elsif rising_edge(clk) then
            if update_en = '1' then
                if actual_taken = '1' then
                    if counter /= "11" then
                        counter <= counter + 1;
                    end if;
                else
                    if counter /= "00" then
                        counter <= counter - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
