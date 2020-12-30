`include "define.v"

module ALU(
    input wire clk,
    input wire rst,
    input wire rdy,
    // request(add-inst) from RS
    input wire En_i,
    input wire [`OpCodeBus] Opcode_i,
    input wire [`DataBus] Imm_i,
    input wire [`DataBus] Pc_i,
    input wire [`DataBus] r1Data_i,
    input wire [`DataBus] r2Data_i,
    input wire [`ROBBus] Id_i,
    // inform to CBD( then to RS & ROB)
    output reg cdbEn_o,
    output reg [`ROBAddrBus] cdbId_o,
    output reg [`DataBus] cdbData_o,
    output reg [`DataBus] cdbPc_o,
    output reg cdbCond_o
);

    always @ (*) begin
        if (rst || !En_i)  cdbEn_o <= 0;
        else if (rdy) begin
            cdbEn_o <= 1;
            cdbId_o <= Id_i;
            case (Opcode_i)
                `LUI: cdbData_o <= Imm_i;
                `AUIPC: cdbData_o <= Imm_i + Pc_i;
                `JAL: begin
                    cdbData_o <= Pc_i + 32'h4;
                    cdbPc_o <= Pc_i + Imm_i;
                    cdbCond_o <= 1;
                end
                `JALR: begin
                    cdbData_o <= Pc_i + 32'h4;
                    cdbPc_o <= ((r1Data_i + Imm_i) & ~1);
                    cdbCond_o <= 1;
                end 
                `BEQ: begin
                    cdbData_o <= 0;
                    cdbPc_o <= Pc_i + Imm_i;
                    cdbCond_o <= (r1Data_i == r2Data_i);
                end
                `BNE: begin
                    cdbData_o <= 0;
                    cdbPc_o <= Pc_i + Imm_i;
                    cdbCond_o <= (r1Data_i != r2Data_i);
                end
                `BLT: begin
                    cdbData_o <= 0;
                    cdbPc_o <= Pc_i + Imm_i;
                    cdbCond_o <= ($signed(r1Data_i) < $signed(r2Data_i));
                end 
                `BGE: begin
                    cdbData_o <= 0;
                    cdbPc_o <= Pc_i + Imm_i;
                    cdbCond_o <= ($signed(r1Data_i) >= $signed(r2Data_i));
                end 
                `BLTU: begin
                    cdbData_o <= 0;
                    cdbPc_o <= Pc_i + Imm_i;
                    cdbCond_o <= ($unsigned(r1Data_i) < $unsigned(r2Data_i));
                end 
                `BGEU: begin
                    cdbData_o <= 0;
                    cdbPc_o <= Pc_i + Imm_i;
                    cdbCond_o <= ($unsigned(r1Data_i) >= $unsigned(r2Data_i));
                end 
                `ADD: cdbData_o <= r1Data_i + r2Data_i;
                `SUB: cdbData_o <= r1Data_i - r2Data_i;
                `SLL: cdbData_o <= (r1Data_i << r2Data_i[4:0]);
                `SLT: cdbData_o <= ($signed(r1Data_i) < $signed(r2Data_i));
                `SLTU: cdbData_o <= ($unsigned(r1Data_i) < $unsigned(r2Data_i));
                `XOR: cdbData_o <= (r1Data_i ^ r2Data_i);
                `SRL: cdbData_o <= (r1Data_i >> r2Data_i[4:0]);
                `SRA: cdbData_o <= ($signed(r1Data_i) >> r2Data_i[4:0]);
                `OR: cdbData_o <= (r1Data_i | r2Data_i);
                `AND: cdbData_o <= (r1Data_i & r2Data_i);
                `ADDI: cdbData_o <= r1Data_i + Imm_i;
                `SLLI: cdbData_o <= (r1Data_i << Imm_i[4:0]);
                `SLTI: cdbData_o <= ($signed(r1Data_i) + $signed(Imm_i));
                `SLTIU: cdbData_o <= ($unsigned(r1Data_i) < $unsigned(Imm_i));
                `XORI: cdbData_o <= (r1Data_i ^ Imm_i);
                `SRLI: cdbData_o <= (r1Data_i >> Imm_i[4:0]);
                `SRAI: cdbData_o <= ($signed(r1Data_i) >> Imm_i[4:0]);
                `ORI: cdbData_o <= (r1Data_i | Imm_i);
                `ANDI: cdbData_o <= (r1Data_i & Imm_i);
            endcase
        end
    end
    
endmodule