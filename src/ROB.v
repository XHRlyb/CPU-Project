`include "define.v"

module ROB(
    input wire clk,
    input wire rst,
    input wire rdy,
    //清空标记
    input wire clr_i,

    output reg Full_o,
    output reg Empty_o,
    // inform to dispatcher
    output reg [`ROBAddrBus] ROBId_o,
    // request(add inst) from dispatcher
    input wire addEn_i,
    input wire [`ROBAddrBus] addId_i,
    input wire [`RegAddrBus] addRd_i,
    input wire [`DataBus] addPc_i,
    input wire [1:0] addBrTag_i,
    // inform from CDB
    input wire cdb1En_i,
    input wire [`ROBAddrBus] cdb1Id_i,
    input wire [`DataBus] cdb1Data_i,
    input wire cdb2En_i,
    input wire [`ROBAddrBus] cdb2Id_i,
    input wire [`DataBus] cdb2Data_i,
    input wire [`DataBus] cdb2Pc_i,
    input wire cdb2Cond_i,
    // br_clr信号
    output reg clr_o,
    output reg [`DataBus] clrPc_o,
    // request to regfile
    output reg wEn_o,
    output reg [`ROBAddrBus] wId_o,
    output reg [`RegAddrBus] wAddr_o,
    output reg [`RegBus] wData_o
);

    reg [`DataBus] pc[`ROBNum-1:0], data[`ROBNum-1:0];
    reg [1:0] br_tag[`ROBNum-1:0];
    reg [`RegAddrBus] rd[`ROBNum-1:0];
    reg [`ROBNum-1:0] rdy_tag;
    reg [31:0] tou, wei;

    wire Full, Empty;
    wire [`ROBNumLog2-1:0] tou_p, wei_p, ntou_p, nwei_p, cnt;

    assign Full = (wei - tou + addEn_i >= 31);
    assign Empty = (wei - tou + addEn_i == 0);
    assign cnt = wei - tou - (wei / 32 != tou / 32);
    assign tou_p = tou[`ROBNumLog2-1:0] + (tou[`ROBNumLog2-1:0] == 0);
    assign wei_p = wei[`ROBNumLog2-1:0] + (wei[`ROBNumLog2-1:0] == 0);
    assign ntou_p = (tou_p == 5'b11111 ? 1 : tou_p + 1);
    assign nwei_p = (wei_p == 5'b11111 ? 1 : wei_p + 1);

// 存取新指令
    always @ (posedge clk) begin
        if (rst || clr_i) begin
            tou <= 1; wei <= 1; rdy_tag <= 0;
            Full_o <= 0; Empty_o <= 1;
            clr_o <= 0; wEn_o <= 0; ROBId_o <= 1;
        end else if (rdy) begin
            if (addEn_i) begin
                wei <= wei + 1 + (wei[4:0] == 5'h1f);
                if (cnt + 1 >= `ROBNum) ROBId_o <= 0;
                    else ROBId_o <= nwei_p;
                rd[addId_i] <= addRd_i;
                pc[addId_i] <= addPc_i;
                //rdy_tag[addId_i] <= 0;
                br_tag[addId_i] <= addBrTag_i;
                rdy_tag[addId_i] <= 0;
                //if (addRd_i == 0) rdy_tag[addId_i] <= 1;
                //    else rdy_tag[addId_i] <= 0;
            end else begin
                if (cnt >= `ROBNum) ROBId_o <= 0;
                    else ROBId_o <= wei_p;
            end
            Full_o <= Full;
            Empty_o <= Empty;

            if (cdb1En_i && cdb1Id_i == tou_p) begin
                clr_o <= 0;
                wEn_o <= 1;
                wId_o <= cdb1Id_i;
                wData_o <= cdb1Data_i;
                wAddr_o <= rd[cdb1Id_i];
                rdy_tag[cdb1Id_i] <= 0;
                tou <= tou + 1 + (tou[4:0] == 5'h1f);

                if (cdb2En_i) begin
                    br_tag[cdb2Id_i] <= (br_tag[cdb2Id_i] < 2 && cdb2Cond_i != br_tag[cdb2Id_i])?3:2;
                    pc[cdb2Id_i] <= (cdb2Cond_i == 1 ? cdb2Pc_i : pc[cdb2Id_i]);
                    data[cdb2Id_i] <= cdb2Data_i;
                    rdy_tag[cdb2Id_i] <= 1;
                end
            end else if (cdb2En_i && cdb2Id_i == tou_p) begin
                wEn_o <= 1;
                wId_o <= cdb2Id_i;
                wData_o <= cdb2Data_i;
                wAddr_o <= rd[cdb2Id_i];
                rdy_tag[cdb2Id_i] <= 0;
                tou <= tou + 1 + (tou[4:0] == 5'h1f);
                if (br_tag[cdb2Id_i] < 2 && cdb2Cond_i != br_tag[cdb2Id_i]) begin
                    clr_o <= 1;
                    clrPc_o <= (cdb2Cond_i == 1 ? cdb2Pc_i : pc[cdb2Id_i]);
                end else clr_o <= 0;

                if (cdb1En_i) begin
                    data[cdb1Id_i] <= cdb1Data_i;
                    rdy_tag[cdb1Id_i] <= 1;
                end
            end else begin                
                if (cdb1En_i) begin
                    data[cdb1Id_i] <= cdb1Data_i;
                    rdy_tag[cdb1Id_i] <= 1;
                end
                if (cdb2En_i) begin
                    br_tag[cdb2Id_i] <= (br_tag[cdb2Id_i] < 2 && cdb2Cond_i != br_tag[cdb2Id_i])?3:2;
                    pc[cdb2Id_i] <= (cdb2Cond_i == 1 ? cdb2Pc_i : pc[cdb2Id_i]);
                    data[cdb2Id_i] <= cdb2Data_i;
                    rdy_tag[cdb2Id_i] <= 1;
                end

                if (rdy_tag[tou_p]) begin
                    wEn_o <= 1;
                    wId_o <= tou_p;
                    wAddr_o <= rd[tou_p];
                    wData_o <= data[tou_p];
                    rdy_tag[tou_p] <= 0;
                    tou <= tou + 1 + (tou[4:0] == 5'h1f);
                    if (br_tag[tou_p] == 3) begin
                        clr_o <= 1;
                        clrPc_o <= pc[tou_p];
                    end else clr_o <= 0;
                end else clr_o <= 0;
            end
        end 
    end

/* 回答 RS的data require
    always @ (*) begin
        if (rst || clr_i || !r1En_i) begin
            r1Rdy_o <= 0;
            r1Data_o <= 0;
        end else if (rdy_tag[r1Id_i]) begin
            r1Rdy_o <= 1;
            r1Data_o <= data[r1Id_i];
        end else begin
            r1Rdy_o <= 0;
            r1Data_o <= 0;
        end
    end
    always @ (*) begin
        if (rst || clr_i || !r2En_i) begin
            r2Rdy_o <= 0;
            r2Data_o <= 0;
        end else if (rdy_tag[r2Id_i]) begin
            r2Rdy_o <= 1;
            r2Data_o <= data[r2Id_i];
        end else begin
            r2Rdy_o <= 0;
            r2Data_o <= 0;
        end
    end
*/

endmodule