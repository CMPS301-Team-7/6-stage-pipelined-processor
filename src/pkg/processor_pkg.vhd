library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package processor_pkg is

    constant DATA_WIDTH          : natural := 32;
    constant ADDR_WIDTH          : natural := 12;
    constant REG_ADDR_WIDTH      : natural := 3;
    constant GPR_COUNT           : natural := 8;
    constant CCR_WIDTH           : natural := 3;
    constant WORD_BYTES          : natural := 4;
    constant SP_RESET_VALUE      : natural := 2**ADDR_WIDTH - 1;

    constant CCR_Z_BIT           : natural := 0;
    constant CCR_N_BIT           : natural := 1;
    constant CCR_C_BIT           : natural := 2;

    subtype word_t               is std_logic_vector(DATA_WIDTH - 1 downto 0);
    subtype addr_t               is std_logic_vector(ADDR_WIDTH - 1 downto 0);
    subtype reg_addr_t           is std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    subtype opcode_t             is std_logic_vector(5 downto 0);
    subtype ccr_t                is std_logic_vector(CCR_WIDTH - 1 downto 0);

    constant OP_ADD              : opcode_t := "000000";
    constant OP_SUB              : opcode_t := "000001";
    constant OP_AND              : opcode_t := "000010";
    constant OP_MOV              : opcode_t := "000011";
    constant OP_SWAP             : opcode_t := "000100";
    constant OP_NOT              : opcode_t := "000101";
    constant OP_INC              : opcode_t := "000110";

    constant OP_IADD             : opcode_t := "001000";
    constant OP_LDM              : opcode_t := "001001";

    constant OP_LDD              : opcode_t := "010000";
    constant OP_STD              : opcode_t := "010001";

    constant OP_JZ               : opcode_t := "011000";
    constant OP_JN               : opcode_t := "011001";
    constant OP_JC               : opcode_t := "011010";
    constant OP_JMP              : opcode_t := "011011";

    constant OP_PUSH             : opcode_t := "100000";
    constant OP_POP              : opcode_t := "100001";
    constant OP_CALL             : opcode_t := "100010";
    constant OP_RET              : opcode_t := "100011";

    constant OP_IN               : opcode_t := "101000";
    constant OP_OUT              : opcode_t := "101001";
    constant OP_NOP              : opcode_t := "101010";
    constant OP_HLT              : opcode_t := "101011";
    constant OP_SETC             : opcode_t := "101100";
    constant OP_INT              : opcode_t := "101101";
    constant OP_RTI              : opcode_t := "101110";

    type alu_op_t is (
        ALU_ADD,
        ALU_SUB,
        ALU_AND,
        ALU_NOT,
        ALU_INC,
        ALU_PASS,
        ALU_NONE
    );

    type branch_sel_t is (
        BR_NONE,
        BR_Z,
        BR_N,
        BR_C,
        BR_UNCOND
    );

    type stack_op_t is (
        STACK_NONE,
        STACK_PUSH,
        STACK_POP,
        STACK_CTRL
    );

    type control_t is record
        reg_write     : std_logic;
        mem_read      : std_logic;
        mem_write     : std_logic;
        alu_src2_imm  : std_logic;
        alu_op        : alu_op_t;
        mem_to_reg    : std_logic;
        branch_en     : std_logic;
        branch_sel    : branch_sel_t;
        jump_en       : std_logic;
        stack_op      : stack_op_t;
        flags_write   : std_logic;
        halt          : std_logic;
    end record;

    constant CONTROL_NOP : control_t := (
        reg_write     => '0',
        mem_read      => '0',
        mem_write     => '0',
        alu_src2_imm  => '0',
        alu_op        => ALU_NONE,
        mem_to_reg    => '0',
        branch_en     => '0',
        branch_sel    => BR_NONE,
        jump_en       => '0',
        stack_op      => STACK_NONE,
        flags_write   => '0',
        halt          => '0'
    );

    type if_id_t is record
        pc            : word_t;
        pc_next       : word_t;
        instr         : word_t;
        valid         : std_logic;
    end record;

    type id_ex1_t is record
        pc            : word_t;
        pc_next       : word_t;
        instr         : word_t;
        read_data1    : word_t;
        read_data2    : word_t;
        imm32         : word_t;
        rdst          : reg_addr_t;
        rsrc1         : reg_addr_t;
        rsrc2         : reg_addr_t;
        control       : control_t;
        valid         : std_logic;
    end record;

    type ex1_ex2_t is record
        pc            : word_t;
        pc_next       : word_t;
        alu_result    : word_t;
        alu_result_b  : word_t;
        read_data2    : word_t;
        branch_target : word_t;
        rdst          : reg_addr_t;
        rsrc1         : reg_addr_t;
        rsrc2         : reg_addr_t;
        ccr_next      : ccr_t;
        control       : control_t;
        valid         : std_logic;
    end record;

    type ex2_mem_t is record
        alu_result    : word_t;
        alu_result_b  : word_t;
        write_data    : word_t;
        mem_addr      : word_t;
        branch_taken  : std_logic;
        branch_target : word_t;
        rdst          : reg_addr_t;
        rsrc1         : reg_addr_t;
        ccr_next      : ccr_t;
        control       : control_t;
        valid         : std_logic;
    end record;

    type mem_wb_t is record
        wb_data       : word_t;
        rdst          : reg_addr_t;
        ccr_next      : ccr_t;
        control       : control_t;
        valid         : std_logic;
    end record;

    -- Structural hazard helper:
    -- fetch must stall whenever the unified memory is serving a data-memory access.
    function memory_stage_uses_ram(ctrl : control_t) return boolean;

end package processor_pkg;

package body processor_pkg is

    function memory_stage_uses_ram(ctrl : control_t) return boolean is
    begin
        return (ctrl.mem_read = '1') or (ctrl.mem_write = '1');
    end function;

end package body processor_pkg;
