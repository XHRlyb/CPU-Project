`include "define.v"

module LS_RS(
    input wire clk,
    input wire rst,
    input wire rdy,
    //清空标记
    input wire clr_i,
    //
    output reg Empty_o,
    output reg Full_o,
    // request(add-inst) from dispatcher
    input wire En_i,
    input wire [`OpCodeBus] Opcode_i,
    input wire [`DataBus] Imm_i,
    input wire [`DataBus] r1Data_i,
    input wire [`DataBus] r2Data_i,
    input wire [`ROBBus] r1Id_i,
    input wire [`ROBBus] r2Id_i,
    input wire [`ROBBus] Id_i,
    // inform form LSBuffer
    input wire LSBufFull_i,
    // request(add-inst) to LSBuffer
    output reg LSBufEn_o,
    output reg [`OpCodeBus] LSBufOpcode_o,
    output reg [`DataBus] LSBufAddr_o,
    output reg [`DataBus] LSBufr2Data_o,
    output reg [`ROBBus] LSBufId_o,
    // fetch updated data from CDB
    input wire cdb1En_i,
    input wire [`ROBBus] cdb1Id_i,
    input wire [`DataBus] cdb1Data_i,
    input wire cdb2En_i,
    input wire [`ROBBus] cdb2Id_i,
    input wire [`DataBus] cdb2Data_i
);

    reg [`ROBBus] r1_id[`LSRSNum-1:0], r2_id[`LSRSNum-1:0], id[`LSRSNum-1:0];
    reg [`DataBus] addr[`LSRSNum-1:0], r2_data[`LSRSNum-1:0];
    reg [`OpCodeBus] op[`LSRSNum-1:0];
    reg [`LSRSNum-1:0] r1_rdy, r2_rdy;
    reg [31:0] tou, wei, i;

    wire [31:0] cnt;
    wire Full, Empty, tou_p, wei_p;

    assign cnt = wei - tou;
    assign tou_p = tou[`LSRSNumLog2-1:0];
    assign wei_p = wei[`LSRSNumLog2-1:0];
    
// 
    always @ (posedge clk) begin
        if (rst || clr_i) begin
            tou <= 0; wei <= 0;
            Full_o <= 0; Empty_o <= 1; 
            LSBufEn_o <= 0;
        end else if (rdy) begin
            if (En_i) begin
                if (!LSBufFull_i && r1Id_i == 0 && r2Id_i == 0) begin
                    LSBufEn_o <= 1;
                    LSBufOpcode_o <= Opcode_i;
                    LSBufAddr_o <= Imm_i + r1Data_i;
                    LSBufr2Data_o <= r2Data_i;
                    LSBufId_o <= Id_i;
                end else begin 
                    wei <= wei + 1;                      
                    r1_id[wei_p] <= r1Id_i;
                    r2_id[wei_p] <= r2Id_i;
                    if (r1Id_i == 0) begin
                        r1_rdy[wei_p] <= 1;
                        addr[wei_p] <= Imm_i + r1Data_i;
                    end else begin
                        r1_rdy[wei_p] <= 0;
                        addr[wei_p] <= Imm_i;
                    end
                    r2_data[wei_p] <= r2Data_i;
                    r2_rdy[wei_p] <= (r2Id_i == 0);
                    id[wei_p] <= Id_i;
                    op[wei_p] <= Opcode_i;
                    if (r1_rdy[tou_p] && r2_rdy[tou_p]) begin
                        tou <= tou + 1;
                        LSBufEn_o <= 1;
                        LSBufOpcode_o <= op[tou_p];
                        LSBufAddr_o <= addr[tou_p];
                        LSBufr2Data_o <= r2_data[tou_p];
                        LSBufId_o <= id[tou_p];
                        r1_rdy[tou_p] <= 0;
                        r2_rdy[tou_p] <= 0;
                    end else LSBufEn_o <= 0;
                end
            end else begin
                if (r1_rdy[tou_p] && r2_rdy[tou_p]) begin
                    tou <= tou + 1;
                    LSBufEn_o <= 1;
                    LSBufOpcode_o <= op[tou_p];
                    LSBufAddr_o <= addr[tou_p];
                    LSBufr2Data_o <= r2_data[tou_p];
                    LSBufId_o <= id[tou_p];
                    r1_rdy[tou_p] <= 0;
                    r2_rdy[tou_p] <= 0;
                end else LSBufEn_o <= 0;
            end
            if (cdb1En_i) begin
                for (i = 0; i < `LSRSNum; i = i + 1) begin
                    if (r1_id[i] == cdb1Id_i) begin
                        addr[i] <= addr[i] + cdb1Data_i;
                        r1_rdy[i] <= 1;
                    end
                    if (r2_id[i] == cdb1Id_i) begin
                        r2_data[i] <= cdb1Data_i; 
                        r2_rdy[i] <= 1;
                    end
                end
            end
            if (cdb2En_i) begin
                for (i = 0; i < `LSRSNum; i = i + 1) begin
                    if (r1_id[i] == cdb2Id_i) begin
                        addr[i] <= addr[i] + cdb2Data_i;
                        r1_rdy[i] <= 1;
                    end
                    if (r2_id[i] == cdb2Id_i) begin
                        r2_data[i] <= cdb2Data_i; 
                        r2_rdy[i] <= 1;
                    end
                end
            end
        end
    end

endmodule