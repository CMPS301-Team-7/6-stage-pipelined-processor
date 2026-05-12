library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ============================================================
-- EX1 Stage: ALU operations, CCR, forwarding, SP calculation
-- Corresponds to "Execute-1 Stage" in the 6-stage pipeline spec
-- ============================================================
entity execute1 is
    port(
        clk, rst : in std_logic;
        -- outputs of ID/EX register
        immediate_q     : in std_logic_vector(31 downto 0);
        pc1_q           : in std_logic_vector(31 downto 0);
        inputport_q     : in std_logic_vector(31 downto 0);
        readdata1_q     : in std_logic_vector(31 downto 0);
        readdata2_q     : in std_logic_vector(31 downto 0);
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
        alu_control_q   : in std_logic_vector(2 downto 0);
        alu_src_q       : in std_logic;
        branch_q        : in std_logic;
        branch_type_q   : in std_logic_vector(1 downto 0);
        inc_sp_q        : in std_logic;
        set_carry_q     : in std_logic;
        ccr_store_q     : in std_logic;
        ccr_restore_q   : in std_logic;
        flag_enable_q   : in std_logic;
        -- SP feedback from EX/MEM (for decrement chaining)
        exmem_sp        : in std_logic_vector(31 downto 0);
        exmem_decsp     : in std_logic;
        -- forwarding source register indices
        rs_q            : in std_logic_vector(2 downto 0);
        rt_q            : in std_logic_vector(2 downto 0);
        -- forwarding data from EX1/EX2
        ex1ex2_regwrite1     : in std_logic;
        ex1ex2_regwrite2     : in std_logic;
        ex1ex2_writeaddress1 : in std_logic_vector(2 downto 0);
        ex1ex2_writeaddress2 : in std_logic_vector(2 downto 0);
        ex1ex2_alu_output    : in std_logic_vector(31 downto 0);
        ex1ex2_readdata1     : in std_logic_vector(31 downto 0);
        ex1ex2_inputport     : in std_logic_vector(31 downto 0);
        ex1ex2_input_enable  : in std_logic;
        -- forwarding data from EX/MEM
        ex_mem_regwrite1       : in std_logic;
        ex_mem_regwrite2       : in std_logic;
        ex_mem_writeaddress1   : in std_logic_vector(2 downto 0);
        ex_mem_writeaddress2   : in std_logic_vector(2 downto 0);
        ex_mem_alu_output      : in std_logic_vector(31 downto 0);
        ex_mem_readdata1       : in std_logic_vector(31 downto 0);
        ex_mem_readdata2       : in std_logic_vector(31 downto 0);
        ex_mem_inputport       : in std_logic_vector(31 downto 0);
        ex_mem_memory_readdate : in std_logic_vector(31 downto 0);
        ex_mem_memtoreg        : in std_logic;
        ex_mem_input_enable    : in std_logic;
        -- forwarding data from MEM/WB
        mem_wb_regwrite1    : in std_logic;
        mem_wb_regwrite2    : in std_logic;
        mem_wb_writeaddress1: in std_logic_vector(2 downto 0);
        mem_wb_writeaddress2: in std_logic_vector(2 downto 0);
        mem_wb_writedata    : in std_logic_vector(31 downto 0);
        mem_wb_readdata1    : in std_logic_vector(31 downto 0);
        -- interrupt pass-through
        id_ex_interrupt_signal : in std_logic;

        -- ---- outputs to EX1/EX2 register ----
        sp_d            : out std_logic_vector(31 downto 0);
        pc1_d           : out std_logic_vector(31 downto 0);
        alu_d           : out std_logic_vector(31 downto 0);
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
        branch_d        : out std_logic;
        branch_type_d   : out std_logic_vector(1 downto 0);
        immediate_d     : out std_logic_vector(31 downto 0);  -- needed by EX2 for address calc
        ex1_interrupt_signal : out std_logic;

        -- Flags output
        Z_flag : out std_logic;
        N_flag : out std_logic;
        C_flag : out std_logic;

        do_branch_ex2 : in std_logic;
        branch_type_ex2 : in std_logic_vector(1 downto 0)
    );
end execute1;

architecture exec1 of execute1 is

    signal alu_result                         : std_logic_vector(31 downto 0);
    signal alu_zero_flag, alu_negative_flag, alu_carry_flag : std_logic;
    signal carry                              : std_logic;
    signal zero                              : std_logic;
    signal negative                           : std_logic;
    signal alu_a, alu_b                       : std_logic_vector(31 downto 0);
    signal Z_reg, N_reg, C_reg                : std_logic;
    signal ccr_z, ccr_n, ccr_c               : std_logic;
    signal input_c_ccr, input_z_ccr, input_n_ccr : std_logic;
    signal sp_q_sig                           : std_logic_vector(31 downto 0);
    signal sp_d_temp                          : std_logic_vector(31 downto 0);
    signal sp_inc_amount                      : std_logic_vector(31 downto 0);
    signal alu_cin_signal                     : std_logic;
    signal forwardA, forwardB                 : std_logic_vector(2 downto 0);
    signal alu_srcA, alu_srcB                 : std_logic_vector(31 downto 0);
    signal readdata1_output, readdata2_output : std_logic_vector(31 downto 0);

    -- normalised forwarding address helpers
    signal ex1ex2_en1, ex1ex2_en2             : std_logic;
    signal ex1ex2_waddress1, ex1ex2_waddress2 : std_logic_vector(2 downto 0);
    signal ex1ex2_output                      : std_logic_vector(31 downto 0);
    signal ex_mem_en1, ex_mem_en2             : std_logic;
    signal ex_mem_waddress1, ex_mem_waddress2 : std_logic_vector(2 downto 0);
    signal ex_mem_output                      : std_logic_vector(31 downto 0);
    signal mem_wb_en1, mem_wb_en2             : std_logic;
    signal mem_wb_waddress1, mem_wb_waddress2 : std_logic_vector(2 downto 0);

    component CCR is
        Port (
            clk         : in std_logic;
            rst         : in std_logic;
            flag_enable : in std_logic;
            alu_Z       : in std_logic;
            alu_N       : in std_logic;
            alu_C       : in std_logic;
            Z           : out std_logic;
            N           : out std_logic;
            C           : out std_logic;
            branch_type : in std_logic_vector(1 downto 0);
            do_branch   : in std_logic
        );
    end component;

    component alu is
        generic (N : integer);
        port (
            A            : in  std_logic_vector(N-1 downto 0);
            B            : in  std_logic_vector(N-1 downto 0);
            S            : in  std_logic_vector(2 downto 0);
            Cin          : in  std_logic;
            F            : out std_logic_vector(N-1 downto 0);
            zero_flag    : out std_logic;
            negative_flag: out std_logic;
            Cout         : out std_logic
        );
    end component;

    component sp is
        generic (n : integer := 32);
        port(
            Rst, Clk : in  std_logic;
            d        : in  std_logic_vector(n-1 downto 0);
            q        : out std_logic_vector(n-1 downto 0)
        );
    end component;

begin

    -- ---- CCR: main flags ----
    ccr_main: CCR
        port map (
            clk         => clk,
            rst         => rst,
            flag_enable => flag_enable_q,
            alu_Z       => input_z_ccr,
            alu_N       => input_n_ccr,
            alu_C       => input_c_ccr,
            Z           => Z_reg,
            N           => N_reg,
            C           => C_reg,
            branch_type => branch_type_ex2,
            do_branch   => do_branch_ex2
        );

    -- ---- CCR: stored/backup copy (for INT/RTI) ----
    ccr_store: CCR
        port map (
            clk         => clk,
            rst         => rst,
            flag_enable => ccr_store_q,
            alu_Z       => Z_reg,
            alu_N       => N_reg,
            alu_C       => C_reg,
            Z           => ccr_z,
            N           => ccr_n,
            C           => ccr_c,
            branch_type => "00",
            do_branch   => '0'
        );

    -- ---- ALU ----
    alu_inst: alu
        generic map (N => 32)
        port map (
            A             => alu_a,
            B             => alu_b,
            S             => alu_control_q,
            Cin           => alu_cin_signal,
            F             => alu_result,
            zero_flag     => alu_zero_flag,
            negative_flag => alu_negative_flag,
            Cout          => alu_carry_flag
        );

    -- ---- SP register ----
    sp_inst: sp
        generic map (n => 32)
        port map (
            Clk => clk,
            Rst => rst,
            d   => sp_d_temp,
            q   => sp_q_sig
        );

    -- ============================================================
    -- Forwarding unit
    -- ============================================================
    ex1ex2_en1 <= ex1ex2_regwrite1 or  ex1ex2_regwrite2;
    ex1ex2_en2 <= ex1ex2_regwrite1 and ex1ex2_regwrite2;

    ex1ex2_waddress1 <= ex1ex2_writeaddress2 when (ex1ex2_regwrite1='1' and ex1ex2_regwrite2='1')
                        else ex1ex2_writeaddress1;
    ex1ex2_waddress2 <= ex1ex2_writeaddress1 when (ex1ex2_regwrite1='1' and ex1ex2_regwrite2='1')
                        else ex1ex2_writeaddress2;

    ex1ex2_output <= ex1ex2_readdata1     when ex1ex2_regwrite2    = '1' else
                    ex1ex2_inputport     when ex1ex2_input_enable = '1' else
                    ex1ex2_alu_output;
    ex_mem_en1 <= ex_mem_regwrite1 or  ex_mem_regwrite2;
    ex_mem_en2 <= ex_mem_regwrite1 and ex_mem_regwrite2;

    ex_mem_waddress1 <= ex_mem_writeaddress2 when (ex_mem_regwrite1='1' and ex_mem_regwrite2='1')
                        else ex_mem_writeaddress1;
    ex_mem_waddress2 <= ex_mem_writeaddress1 when (ex_mem_regwrite1='1' and ex_mem_regwrite2='1')
                        else ex_mem_writeaddress2;

    mem_wb_en1 <= mem_wb_regwrite1 or  mem_wb_regwrite2;
    mem_wb_en2 <= mem_wb_regwrite1 and mem_wb_regwrite2;

    mem_wb_waddress1 <= mem_wb_writeaddress2 when (mem_wb_regwrite1='1' and mem_wb_regwrite2='1')
                        else mem_wb_writeaddress1;
    mem_wb_waddress2 <= mem_wb_writeaddress1 when (mem_wb_regwrite1='1' and mem_wb_regwrite2='1')
                        else mem_wb_writeaddress2;

    ex_mem_output <= ex_mem_readdata2        when ex_mem_regwrite2    = '1' else
                     ex_mem_inputport        when ex_mem_input_enable = '1' else
                     ex_mem_memory_readdate  when ex_mem_memtoreg     = '1' else
                     ex_mem_alu_output;

    process(rs_q, rt_q,
        ex1ex2_en1, ex1ex2_en2, ex1ex2_waddress1, ex1ex2_waddress2,
        ex_mem_en1, ex_mem_en2, ex_mem_waddress1, ex_mem_waddress2,
        mem_wb_en1, mem_wb_en2, mem_wb_waddress1, mem_wb_waddress2)
    begin
        forwardA <= "000";
        forwardB <= "000";
        -- operand A
        if    ex1ex2_en1='1' and ex1ex2_waddress1 = rs_q then forwardA <= "101";
        elsif ex1ex2_en2='1' and ex1ex2_waddress2 = rs_q then forwardA <= "110";
        elsif ex_mem_en1='1' and ex_mem_waddress1 = rs_q  then forwardA <= "001";
        elsif ex_mem_en2='1' and ex_mem_waddress2 = rs_q  then forwardA <= "011";
        elsif mem_wb_en1='1' and mem_wb_waddress1 = rs_q  then forwardA <= "010";
        elsif mem_wb_en2='1' and mem_wb_waddress2 = rs_q  then forwardA <= "100";
        end if;
        -- operand B
        if    ex1ex2_en1='1' and ex1ex2_waddress1 = rt_q then forwardB <= "101";
        elsif ex1ex2_en2='1' and ex1ex2_waddress2 = rt_q then forwardB <= "110";
        elsif ex_mem_en1='1' and ex_mem_waddress1 = rt_q  then forwardB <= "001";
        elsif ex_mem_en2='1' and ex_mem_waddress2 = rt_q  then forwardB <= "011";
        elsif mem_wb_en1='1' and mem_wb_waddress1 = rt_q  then forwardB <= "010";
        elsif mem_wb_en2='1' and mem_wb_waddress2 = rt_q  then forwardB <= "100";
        end if;
    end process;

    --MUX for input A of ALU
    with forwardA select alu_srcA <=
        readdata1_q      when "000",
        ex_mem_output    when "001",
        mem_wb_writedata when "010",
        ex_mem_readdata1 when "011",
        mem_wb_readdata1 when "100",
        ex1ex2_output    when "101",
        ex1ex2_readdata1 when "110",
        readdata1_q      when others;

    --MUX for input B of ALU
    with forwardB select alu_srcB <=
        readdata2_q      when "000",
        ex_mem_output    when "001",
        mem_wb_writedata when "010",
        ex_mem_readdata1 when "011",
        mem_wb_readdata1 when "100",
        ex1ex2_output    when "101",
        ex1ex2_readdata1 when "110",
        readdata2_q      when others;

    with forwardA select readdata1_output <=
        readdata1_q      when "000",
        ex_mem_output    when "001",
        mem_wb_writedata when "010",
        ex_mem_readdata1 when "011",
        mem_wb_readdata1 when "100",
        ex1ex2_output    when "101",
        ex1ex2_readdata1 when "110",
        readdata1_q      when others;

    with forwardB select readdata2_output <=
        readdata2_q      when "000",
        ex_mem_output    when "001",
        mem_wb_writedata when "010",
        ex_mem_readdata1 when "011",
        mem_wb_readdata1 when "100",
        ex1ex2_output    when "101",
        ex1ex2_readdata1 when "110",
        readdata2_q      when others;

    -- ============================================================
    -- ALU inputs
    -- ============================================================
    alu_a          <= alu_srcA;
    alu_b          <= alu_srcB when alu_src_q = '1' else immediate_q;
    alu_cin_signal <= C_reg;

    -- ============================================================
    -- CCR input mux (normal vs restore-from-backup)
    -- ============================================================
    carry <= '1' when set_carry_q = '1' else alu_carry_flag;
    zero  <=  Z_reg when set_carry_q = '1' else alu_zero_flag;
    negative <= N_reg when set_carry_q = '1' else alu_negative_flag;

    process(ccr_restore_q, alu_zero_flag, carry, alu_negative_flag, ccr_z, ccr_c, ccr_n)
    begin
        if ccr_restore_q = '1' then
            input_z_ccr <= ccr_z;
            input_c_ccr <= ccr_c;
            input_n_ccr <= ccr_n;
        else
            input_z_ccr <= zero;
            input_c_ccr <= carry;
            input_n_ccr <= negative;
        end if;
    end process;

    -- ============================================================
    -- SP calculation
    -- ============================================================
    sp_inc_amount <= std_logic_vector(unsigned(sp_q_sig) + 1) when inc_sp_q = '1' else sp_q_sig;
    sp_d_temp     <= std_logic_vector(unsigned(exmem_sp) - 1) when exmem_decsp = '1' else sp_inc_amount;
    sp_d          <= sp_d_temp;

    -- ============================================================
    -- Output assignments to EX1/EX2 pipeline register
    -- ============================================================
    alu_d           <= alu_result;
    pc1_d           <= pc1_q;
    inputport_d     <= inputport_q;
    readdata1_d     <= readdata1_output;
    readdata2_d     <= readdata2_output;
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
    branch_d        <= branch_q;
    branch_type_d   <= branch_type_q;
    -- pass immediate so EX2 can compute LDD/STD effective address
    immediate_d     <= immediate_q;
    ex1_interrupt_signal <= id_ex_interrupt_signal;
    
    -- Flags outputs
    Z_flag <= Z_reg;
    N_flag <= N_reg;
    C_flag <= C_reg;
end exec1;