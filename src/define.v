`ifndef DEFINE_V
`define DEFINE_V

// *************** 全局宏定义 ***************
`define Zero32  32'h00000000
`define One32   32'hffffffff
`define PCnext  32'h00000004

`define LenBus 2:0
`define ZeroLen 3'b000
`define ByteLen 3'b001
`define HexLen 3'b010
`define WordLen 3'b100

// *************** 指令存储器ROM相关 ***************
`define AddrBus         31:0
`define InstBus         31:0
`define InstAddrBus     31:0
`define DataBus         31:0
`define DataAddrBus     31:0
`define MemDataBus      31:0
`define MemAddrBus      31:0
`define RegBus          31:0
`define ByteBus          7:0
`define OpCodeBus        5:0
`define RegAddrBus       4:0
`define ROBBus           4:0 
`define ROBAddrBus       4:0
`define DataWidBus       2:0
`define OpClassBus       2:0

`define RegNum          32
`define IqueueNum       32
`define IqueueNumLog2    5
`define RSNum           32
`define RSNumLog2        5
`define LSRSNum          8
`define LSRSNumLog2      3
`define LSBufNum        32
`define LSBufNumLog2     5
`define ROBNum          32
`define ROBNumLog2       5

`define InstMemNum      131072
`define IstMemNumLog2  17
`define NopRegAdr   5'b00000


`define ICacheBus       9:2
`define ICacheNum       256
`define ICacheNumLog2   8
`define ICacheTagBytes  16:10
`define ICacheTagBus    6:0

// *************** 指令相关宏定义 ***************
// OP_CODE
`define OP_NOP      7'b0000000
`define OP_LUI      7'b0110111
`define OP_AUIPC    7'b0010111
`define OP_JAL      7'b1101111
`define OP_JALR     7'b1100111
`define OP_BRCH     7'b1100011
`define OP_LOAD     7'b0000011
`define OP_STORE    7'b0100011
`define OP_OP_IMM   7'b0010011
`define OP_OP       7'b0110011
`define OP_MISC_MEM 7'b0001111

// FUN_CODE
// BRANCH
`define FUN_BEQ  3'b000
`define FUN_BNE  3'b001
`define FUN_BLT  3'b100
`define FUN_BGE  3'b101
`define FUN_BLTU 3'b110
`define FUN_BGEU 3'b111
// LOAD
`define FUN_LB   3'b000
`define FUN_LH   3'b001
`define FUN_LW   3'b010
`define FUN_LBU  3'b100
`define FUN_LHU  3'b101
// STORE
`define FUN_SB   3'b000
`define FUN_SH   3'b001
`define FUN_SW   3'b010
// OP_IMM & OP
`define FUN_ADD_SUB  3'b000
`define FUN_SLL      3'b001
`define FUN_SLT      3'b010
`define FUN_SLTU     3'b011
`define FUN_XOR      3'b100
`define FUN_SR       3'b101
`define FUN_OR       3'b110
`define FUN_AND      3'b111
// MISC_MEM
`define FUN_FENCE    3'b000
`define FUN_FENCEI   3'b001

// FUNCT7
`define FUN_SPEC1 7'b0000000 // SRLI, ADD, SRL
`define FUN_SPEC2 7'b0100000 // SRAI, SUB, SRA

// OPCODE
`define NOP     6'b000000
`define LUI     6'b000001
`define AUIPC   6'b000010
`define JAL     6'b000011
`define JALR    6'b000100
`define BEQ     6'b000101
`define BNE     6'b000110
`define BLT     6'b000111 
`define BGE     6'b001000
`define BLTU    6'b001001 
`define BGEU    6'b001010 
`define LB      6'b001011 
`define LH      6'b001100 
`define LW      6'b001101 
`define LBU     6'b001110 
`define LHU     6'b001111 
`define SB      6'b010000 
`define SH      6'b010001 
`define SW      6'b010010 
`define ADD     6'b010011 
`define SUB     6'b010100 
`define SLL     6'b010101 
`define SLT     6'b010110 
`define SLTU    6'b010111 
`define XOR     6'b011000 
`define SRL     6'b011001 
`define SRA     6'b011010 
`define OR      6'b011011 
`define AND     6'b011100
`define ADDI    6'b011101 
`define SLLI    6'b011110 
`define SLTI    6'b011111 
`define SLTIU   6'b100000 
`define XORI    6'b100001 
`define SRLI    6'b100010 
`define SRAI    6'b100011 
`define ORI     6'b100100
`define ANDI    6'b100101



`define MemAdrWidth     32
`define MemDataWidth    32
`define DataMemNum      131072
`define DataMemNumLog2  17
`define DCacheBus       8:2
`define DCacheNum       128
`define DCacheNumLog2   7
`define DCacheTagBytes  16:9
`define DCacheTagBus    7:0
`define DCacheAllBytes  31:2
`define BTBBus          6:2
`define BTBNum          32
`define BTBNumLog2      5
`define BTBTagBytes     16:7
`define BTBTagBus       9:0
`define BTBAllBytes     16:2

`define StallBus        5:0

`endif // DEFINE_V