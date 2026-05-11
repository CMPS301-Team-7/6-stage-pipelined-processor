library ieee;
use ieee.std_logic_1164.all;
entity if_id_reg is 
    port(
        clk,rst, enable:in std_logic; 
        instruction_d: in std_logic_vector(31 downto 0);
        instruction_q: out std_logic_vector(31 downto 0);
        pc_d:in std_logic_vector(31 downto 0);
        pc_q:out std_logic_vector(31 downto 0);
        inputport_d:in std_logic_vector(31 downto 0);
        inputport_q:out std_logic_vector(31 downto 0);
        predicted_taken_d: in std_logic;
        predicted_taken_q: out std_logic;
        predicted_target_d: in std_logic_vector(31 downto 0);
        predicted_target_q: out std_logic_vector(31 downto 0);
        fetch_pc_d: in std_logic_vector(31 downto 0);
        fetch_pc_q: out std_logic_vector(31 downto 0)

        );
end if_id_reg;
architecture dff of if_id_reg is
begin 
process(clk,rst)
begin
    if(rst='1')then
        instruction_q<=(others=>'0');
        pc_q<=(others=>'0');
        inputport_q<=(others=>'0');
        predicted_taken_q<='0';
        predicted_target_q<=(others=>'0');
        fetch_pc_q<=(others=>'0');

    elsif clk'event and clk = '1' and enable = '1' then 
        instruction_q<=instruction_d;
        pc_q<=pc_d;
        inputport_q<=inputport_d;
        predicted_taken_q<=predicted_taken_d;
        predicted_target_q<=predicted_target_d;
        fetch_pc_q<=fetch_pc_d;
    end if;
end process;
end dff; 
