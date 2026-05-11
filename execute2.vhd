library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ============================================================
-- EX2 Stage: Branch decision resolution &
--            LDD/STD effective address calculation
-- Corresponds to "Execute-2 Stage" in the 6-stage pipeline spec
-- ============================================================
entity execute2 is
    port(
        -- inputs from EX1/EX2 register
        sp_q            : in std_logic_vector(31 downto 0);
        pc1_q           : in std_logic_vector(31 downto 0);
        alu_q           : in std_logic_vector(31 downto 0);  -- base for mem addr / result
        inputport_q     : in std_logic_vector(31 downto 0);
        readdata1_q     : in std_logic_vector(31 downto 0);
        readdata2_q     : in std_logic_vector(31 downto 0);
        immediate_q     : in std_logic_vector(31 downto 0);  -- sign-extended offset
        writeaddress1_q : in std_logic_vector(2 downto 0);
        writeaddress2_q : in std_logic_vector(2 downto 0);
        memtoreg_q      : in std_logic;
        outputenable_q  : in std_logic;
        regwrite1_q     : in std_logic;
        regwrite2_q     : in std_logic;
        inputenable_q   : in std_logic;
        memwrite_q      : in std_logic;
        memread_q       : in std_logic;
        mem_add_src_q   : in std_logic;
        mem_data_src_q  : in std_logic;
        sp_dec_q        : in std_logic;
        pc_src_q        : in std_logic;
        branch_q        : in std_logic;
        branch_type_q   : in std_logic_vector(1 downto 0);
        ex1_interrupt_signal : in std_logic;

        -- flags forwarded from EX1's CCR (combinational, same cycle)
        Z_flag : in std_logic;
        N_flag : in std_logic;
        C_flag : in std_logic;

        -- ---- outputs to EX/MEM register ----
        sp_d            : out std_logic_vector(31 downto 0);
        pc1_d           : out std_logic_vector(31 downto 0);
        alu_d           : out std_logic_vector(31 downto 0);
        mem_addr_d      : out std_logic_vector(31 downto 0);  -- effective address for LDD/STD
        inputport_d     : out std_logic_vector(31 downto 0);
        readdata1_d     : out std_logic_vector(31 downto 0);
        readdata2_d     : out std_logic_vector(31 downto 0);
        writeaddress1_d : out std_logic_vector(2 downto 0);
        writeaddress2_d : out std_logic_vector(2 downto 0);
        memtoreg_d      : out std_logic;
        outputenable_d  : out std_logic;
        regwrite1_d     : out std_logic;
        regwrite2_d     : out std_logic;
        inputenable_d   : out std_logic;
        memwrite_d      : out std_logic;
        memread_d       : out std_logic;
        mem_add_src_d   : out std_logic;
        mem_data_src_d  : out std_logic;
        sp_dec_d        : out std_logic;
        pc_src_d        : out std_logic;

        -- branch resolution outputs (go directly to fetch/PC, not stored in register)
        do_branch       : out std_logic;
        branch_target   : out std_logic_vector(31 downto 0);

        ex2_interrupt_signal : out std_logic
    );
end execute2;

architecture exec2 of execute2 is
    signal branchtype      : std_logic;
    signal do_branch_sig   : std_logic;
    -- effective address = ALU result (Rsrc already computed in EX1) + offset
    -- Note: for LDD/STD the ALU in EX1 computes Rsrc; we add the sign-extended
    -- immediate (offset) here to form the final memory address.
    signal effective_addr  : std_logic_vector(31 downto 0);
begin

    -- ============================================================
    -- Effective address for LDD / STD:
    --   addr = R[Rsrc] + offset
    -- R[Rsrc] arrives as alu_q (EX1 passed readdata1 through the ALU
    -- when mem_add_src is set, or we just add 0; either way we add
    -- the sign-extended immediate here for correctness).
    -- When mem_add_src_q = '1' the address source is Rsrc+offset,
    -- otherwise the plain ALU result is used.
    -- ============================================================
    effective_addr <= std_logic_vector(unsigned(readdata1_q) + unsigned(immediate_q))
                      when mem_add_src_q = '1'
                      else alu_q;

    mem_addr_d <= effective_addr;

    -- ============================================================
    -- Branch target: the immediate already holds the target address
    -- (absolute jump) as assembled by the control unit / assembler.
    -- ============================================================
    branch_target <= immediate_q;

    -- ============================================================
    -- Branch decision
    -- ============================================================
    -- JMP Decision Device
    process(branch_type_q, C_flag, Z_flag, N_flag)
    begin
        case branch_type_q is
            when "00"   => branchtype <= '1';     -- JMP / CALL (unconditional)
            when "01"   => branchtype <= Z_flag;  -- JZ
            when "10"   => branchtype <= N_flag;  -- JN
            when "11"   => branchtype <= C_flag;  -- JC
            when others => branchtype <= '0';
        end case;
    end process;

    do_branch_sig <= branchtype and branch_q;
    do_branch     <= do_branch_sig;

    -- ============================================================
    -- Pass-through to EX/MEM register
    -- ============================================================
    sp_d            <= sp_q;
    pc1_d           <= pc1_q;
    alu_d           <= alu_q;
    inputport_d     <= inputport_q;
    readdata1_d     <= readdata1_q;
    readdata2_d     <= readdata2_q;
    writeaddress1_d <= writeaddress1_q;
    writeaddress2_d <= writeaddress2_q;
    memtoreg_d      <= memtoreg_q;
    outputenable_d  <= outputenable_q;
    regwrite1_d     <= regwrite1_q;
    regwrite2_d     <= regwrite2_q;
    inputenable_d   <= inputenable_q;
    memwrite_d      <= memwrite_q;
    memread_d       <= memread_q;
    mem_add_src_d   <= mem_add_src_q;
    mem_data_src_d  <= mem_data_src_q;
    sp_dec_d        <= sp_dec_q;
    pc_src_d        <= pc_src_q;
    ex2_interrupt_signal <= ex1_interrupt_signal;

end exec2;