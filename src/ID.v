`include "define.v"

module ID(
    input wire clk,
    input wire rst,
    input wire rdy,
    // fetched inst from iqueue
    input wire fetchEmpty_i,
    input wire [`DataBus] fetchData_i,
    input wire [`DataBus] fetchPc_i,
    // decode-inst to dispatcher
    output reg [`RegAddrBus] r1Addr_o,
    output reg [`RegAddrBus] r2Addr_o,
    output reg [`RegAddrBus] rdAddr_o,
    output reg [`OpCodeBus] opCode_o,
    output reg [`MemAddrBus] Imm_o,
    output reg [`DataBus] Pc_o
);
    wire [6:0] OPCODE = fetchData_i[6:0];
    wire [2:0] FUNCT3 = fetchData_i[14:12];
    wire [6:0] FUNCT7 = fetchData_i[31:25]; 
    always @ (*) begin
        if (rst) begin
            r1Addr_o = 0;
            r2Addr_o = 0;
            rdAddr_o = 0;
            opCode_o = 0;
            Imm_o = 0;
            Pc_o = 0;
        end else if (rdy && !fetchEmpty_i) begin
            Pc_o = fetchPc_i;
            case (OPCODE)
                `OP_LUI: begin
                    opCode_o = `LUI;
                    Imm_o = {fetchData_i[31:12], 12'b0};
                    r1Addr_o = 0;
                    r2Addr_o = 0;
                    rdAddr_o = fetchData_i[11:7];
                end
                `OP_AUIPC: begin
                    opCode_o = `AUIPC;
                    Imm_o = {fetchData_i[31:12], 12'b0};
                    r1Addr_o = 0;
                    r2Addr_o = 0;
                    rdAddr_o = fetchData_i[11:7];
                end
                `OP_JAL: begin
                    opCode_o = `JAL;
                    Imm_o = {{12{fetchData_i[31]}}, fetchData_i[19:12], fetchData_i[20], fetchData_i[30:21], 1'b0};
                    r1Addr_o = 0;
                    r2Addr_o = 0;
                    rdAddr_o = fetchData_i[11:7];
                end
                `OP_JALR: begin
                    opCode_o = `JALR;
                    Imm_o = {{20{fetchData_i[31]}}, fetchData_i[31:20]};
                    r1Addr_o = fetchData_i[19:15];
                    r2Addr_o = 0;
                    rdAddr_o = fetchData_i[11:7];
                end
                `OP_BRCH: begin
                    case (FUNCT3)
                        `FUN_BNE: opCode_o = `BNE;
                        `FUN_BLT: opCode_o = `BLT;
                        `FUN_BEQ: opCode_o = `BEQ;
                        `FUN_BGE: opCode_o = `BGE;
                        `FUN_BLTU: opCode_o = `BLTU;
                        `FUN_BGEU: opCode_o = `BGEU;
                    endcase
                    Imm_o = {{20{fetchData_i[31]}}, fetchData_i[7], fetchData_i[30:25], fetchData_i[11:8], 1'b0};
                    r1Addr_o = fetchData_i[19:15];
                    r2Addr_o = fetchData_i[24:20];
                    rdAddr_o = 0;
                end
                `OP_LOAD: begin
                    case (FUNCT3)
                        `FUN_LB: opCode_o = `LB;
                        `FUN_LH: opCode_o = `LH;
                        `FUN_LW: opCode_o = `LW;
                        `FUN_LBU: opCode_o = `LBU;
                        `FUN_LHU: opCode_o = `LHU;
                    endcase
                    Imm_o = {{20{fetchData_i[31]}}, fetchData_i[31:20]};
                    r1Addr_o = fetchData_i[19:15];
                    r2Addr_o = 0;
                    rdAddr_o = fetchData_i[11:7];
                end
                `OP_STORE: begin
                    case (FUNCT3)
                        `FUN_SB: opCode_o = `SB;
                        `FUN_SH: opCode_o = `SH;
                        `FUN_SW: opCode_o = `SW;
                    endcase
                    Imm_o = {{20{fetchData_i[31]}}, fetchData_i[31:25], fetchData_i[11:7]};
                    r1Addr_o = fetchData_i[19:15];
                    r2Addr_o = fetchData_i[24:20];
                    rdAddr_o = 0;
                end
                `OP_OP_IMM: begin
                    case (FUNCT3)
                        `FUN_ADD_SUB: opCode_o = `ADDI;
                        `FUN_SLL    : opCode_o = `SLLI;
                        `FUN_SLT    : opCode_o = `SLTI;
                        `FUN_SLTU   : opCode_o = `SLTIU;
                        `FUN_XOR    : opCode_o = `XORI;
                        `FUN_SR     : begin
                            case (FUNCT7)
                                `FUN_SPEC1: opCode_o = `SRLI;
                                `FUN_SPEC2: opCode_o = `SRAI;
                            endcase
                        end
                        `FUN_OR     : opCode_o = `ORI;
                        `FUN_AND    : opCode_o = `ANDI;
                    endcase
                    Imm_o = {{20{fetchData_i[31]}}, fetchData_i[31:20]};
                    r1Addr_o = fetchData_i[19:15];
                    r2Addr_o = 0;
                    rdAddr_o = fetchData_i[11:7];
                end
                `OP_OP: begin
                    case (FUNCT3)
                        `FUN_ADD_SUB: begin
                            r2Addr_o = fetchData_i[24:20];
                            case (FUNCT7)
                                `FUN_SPEC1: opCode_o = `ADD;
                                `FUN_SPEC2: opCode_o = `SUB;
                            endcase
                        end
                        `FUN_SLL    : begin opCode_o = `SLL; r2Addr_o = 0; end
                        `FUN_SLT    : begin opCode_o = `SLT; r2Addr_o = fetchData_i[24:20]; end
                        `FUN_SLTU   : begin opCode_o = `SLTU; r2Addr_o = fetchData_i[24:20]; end
                        `FUN_XOR    : begin opCode_o = `XOR; r2Addr_o = fetchData_i[24:20]; end
                        `FUN_SR     : begin
                            r2Addr_o = 0;
                            case (FUNCT7)
                                `FUN_SPEC1: opCode_o = `SRL;
                                `FUN_SPEC2: opCode_o = `SRA;
                            endcase
                        end
                        `FUN_OR     : begin opCode_o = `OR; r2Addr_o = fetchData_i[24:20]; end
                        `FUN_AND    : begin opCode_o = `AND; r2Addr_o = fetchData_i[24:20]; end
                    endcase
                    Imm_o = 0;
                    r1Addr_o = fetchData_i[19:15];
                    rdAddr_o = fetchData_i[11:7];
                end
            endcase/*
            if (opCode_o >= `JALR && opCode_o = `ANDI) 
                r1Addr_o = fetchData_i[19:15];
            else 
                r1Addr_o = 0;
            if ((opCode_o >= `BEQ && opCode_o = `BGEU) || 
                    (opCode_o >= `SB && opCode_o = `SW) || 
                    (opCode_o >= `ADD && opCode_o = `AND)) 
                r2Addr_o = fetchData_i[24:20];
            else 
                r2Addr_o = 0;
            if ((opCode_o >= `LUI && opCode_o = `JALR) || 
                    (opCode_o >= `LB && opCode_o = `LHU) || 
                    (opCode_o >= `ADD && opCode_o = `ANDI)) 
                rdAddr_o = fetchData_i[11:7];
            else
                rdAddr_o = 0;//*/
        end else begin
            opCode_o = 0;
            Imm_o = 0;
        end
    end
endmodule