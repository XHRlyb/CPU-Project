`include "define.v"

module dispatch(
    input wire clk,
    input wire rst,
    input wire rdy,
    // decoded-inst from ID
    input wire [`RegAddrBus] r1Addr_i,
    input wire [`RegAddrBus] r2Addr_i,
    input wire [`RegAddrBus] rdAddr_i,
    input wire [`OpCodeBus] opCode_i,
    input wire [`MemAddrBus] Pc_i,
    input wire [`DataBus] Imm_i,
    // request(lock) to regfile
    output reg lockEn_o,
    output reg [`ROBAddrBus] lockId_o,
    output reg [`RegAddrBus] lockAddr_o,
    // request(data-query) to regfile
    output reg r1En_o,
    output reg [`RegAddrBus] r1Addr_o,
    output reg r2En_o,
    output reg [`RegAddrBus] r2Addr_o,
    // response(data-query) from regfile
    input wire r1Rdy_i,
    input wire [`ROBAddrBus] r1Id_i,
    input wire [`RegBus] r1Data_i,
    input wire r2Rdy_i,
    input wire [`ROBAddrBus] r2Id_i,
    input wire [`RegBus] r2Data_i,
    // request to LSRS
    input wire LSRSFull_i,
    output reg LSRSEn_o,
    output reg [`OpCodeBus] LSRSOpcode_o,
    output reg [`DataBus] LSRSImm_o,
    output reg [`DataBus] LSRSr1Data_o,
    output reg [`DataBus] LSRSr2Data_o,
    output reg [`ROBAddrBus] LSRSr1Id_o,
    output reg [`ROBAddrBus] LSRSr2Id_o,
    output reg [`ROBAddrBus] LSRSId_o,
    // request to RS
    input wire RSFull_i,
    output reg RSEn_o,
    output reg [`OpCodeBus] RSOpcode_o,
    output reg [`DataBus] RSPc_o,
    output reg [`DataBus] RSImm_o,
    output reg [`DataBus] RSr1Data_o,
    output reg [`DataBus] RSr2Data_o,
    output reg [`ROBAddrBus] RSr1Id_o,
    output reg [`ROBAddrBus] RSr2Id_o,
    output reg [`ROBAddrBus] RSId_o,
    // inform from ROB
    input wire [`ROBAddrBus] ROBId_i,
    // request to ROB
    output reg ROBEn_o,
    output reg [`ROBAddrBus] ROBId_o,
    output reg [`RegAddrBus] ROBRd_o,
    output reg [`DataBus] ROBPc_o,
    output reg [1:0] ROBBrTag_o,
    // request to IF
    output reg BrPridEn_o,
    output reg [`DataBus] BrPridPc_o,
    // inform from cdb
    input wire cdb1En_i,
    input wire [`ROBAddrBus] cdb1Id_i,
    input wire [`DataBus] cdb1Data_i,
    input wire cdb2En_i,
    input wire [`ROBAddrBus] cdb2Id_i,
    input wire [`DataBus] cdb2Data_i
);
    always @ (*) begin
        if (rst || opCode_i == `NOP) begin
            lockEn_o = 0;
            r1En_o = 0; r2En_o = 0;
            LSRSEn_o = 0; RSEn_o = 0; ROBEn_o = 0;
            BrPridEn_o = 0;
        end else if (rdy) begin
            if (ROBId_i != 0) begin
                // regfile
                lockEn_o = (rdAddr_i != 0);
                lockId_o = ROBId_i;
                lockAddr_o = rdAddr_i;
                r1En_o = 1; r1Addr_o = r1Addr_i;
                r2En_o = 1; r2Addr_o = r2Addr_i;
                // LSRS
                if (opCode_i >= `LB && opCode_i <= `SW) begin
                    if (!LSRSFull_i && r1Rdy_i && r2Rdy_i) begin
                        LSRSEn_o = 1;//(r1Rdy_i && r2Rdy_i);
                        LSRSOpcode_o = opCode_i;
                        LSRSImm_o = Imm_i;
                        if (cdb1En_i && cdb1Id_i == r1Id_i) begin
                            LSRSr1Id_o = 0;
                            LSRSr1Data_o = cdb1Data_i;
                        end else if (cdb2En_i && cdb2Id_i == r1Id_i) begin
                            LSRSr1Id_o = 0;
                            LSRSr1Data_o = cdb2Data_i;
                        end else begin
                            LSRSr1Id_o = r1Id_i;
                            LSRSr1Data_o = r1Data_i;
                        end
                        if (cdb1En_i && cdb1Id_i == r2Id_i) begin
                            LSRSr2Id_o = 0;
                            LSRSr2Data_o = cdb1Data_i;
                        end else if (cdb2En_i && cdb2Id_i == r2Id_i) begin
                            LSRSr2Id_o = 0;
                            LSRSr2Data_o = cdb2Data_i;
                        end else begin
                            LSRSr2Id_o = r2Id_i;
                            LSRSr2Data_o = r2Data_i;
                        end
                        LSRSId_o = ROBId_i;
                    end else LSRSEn_o = 0;
                    RSEn_o = 0;
                end else if (!RSFull_i && r1Rdy_i && r2Rdy_i) begin
                // RS
                    RSEn_o = 1;
                    RSOpcode_o = opCode_i;
                    RSImm_o = Imm_i;
                    RSPc_o = Pc_i;
                    if (cdb1En_i && cdb1Id_i == r1Id_i) begin
                        RSr1Id_o = 0;
                        RSr1Data_o = cdb1Data_i;
                    end else if (cdb2En_i && cdb2Id_i == r1Id_i) begin
                        RSr1Id_o = 0;
                        RSr1Data_o = cdb2Data_i;
                    end else begin
                        RSr1Id_o = r1Id_i;
                        RSr1Data_o = r1Data_i;
                    end
                    if (cdb1En_i && cdb1Id_i == r2Id_i) begin
                        RSr2Id_o = 0;
                        RSr2Data_o = cdb1Data_i;
                    end else if (cdb2En_i && cdb2Id_i == r2Id_i) begin
                        RSr2Id_o = 0;
                        RSr2Data_o = cdb2Data_i;
                    end else begin
                        RSr2Id_o = r2Id_i;
                        RSr2Data_o = r2Data_i;
                    end
                    RSId_o = ROBId_i;
                    LSRSEn_o = 0;
                end else begin
                    RSEn_o = 0;
                    LSRSEn_o = 0;
                end
                // ROB
                ROBEn_o = 1;
                ROBId_o = ROBId_i;
                ROBRd_o = rdAddr_i;
                ROBPc_o = Pc_i;
                if (opCode_i >= `JAL && opCode_i <= `BGEU) begin
                    ROBBrTag_o = 0;
                end else begin
                    ROBBrTag_o = 2;
                end
                 // 分支预测了吗？
                BrPridEn_o = 0;
            end else begin
                r1En_o = 1; r1Addr_o = r1Addr_i;
                r2En_o = 1; r2Addr_o = r2Addr_i;
                lockEn_o = 0;
                LSRSEn_o = 0; RSEn_o = 0; ROBEn_o = 0;
                BrPridEn_o = 0;
            end
        end
    end
endmodule