`include "define.v"

module LSbuffer2(
    input wire clk,
    input wire rst,
    input wire rdy,
    // 清空标记
    input wire clr_i,
    //
    output reg Empty_o,
    output reg Full_o,
    input wire LSEn_i,
    // request(add-inst) from LSRS
    input wire En_i,
    input wire [`OpCodeBus] Opcode_i,
    input wire [`DataBus] Addr_i,
    input wire [`DataBus] r2Data_i,
    input wire [`ROBBus] Id_i,
    // request to mem-ctrl
    output reg dataEn_o,
    output reg dataRw_o, // 0-read, 1-write
    output reg [`DataWidBus] dataWid_o,
    output reg [`InstAddrBus] dataAddr_o,
    output reg [`InstBus] dataData_o, // just for write
    // response from mem-ctrl
    input wire Rdy_i,
    input wire [`DataBus] dataData_i, // just for read
    // inform to CBD (just for read)
    output reg cdbEn_o,
    output reg [`ROBAddrBus] cdbId_o,
    output reg [`DataBus] cdbData_o
);

    parameter cap = 5'h1d;
    reg [`DataBus] addr[`LSBufNum-1:0], data[`LSBufNum-1:0];
    reg [`OpCodeBus] op[`LSBufNum-1:0];
    reg [`ROBBus] id[`LSBufNum-1:0];
    reg [31:0] tou, wei, cmt;

    wire full, empty;
    wire [`LSBufNumLog2-1:0] tou_p, wei_p;

    assign full = (wei + En_i - tou - 1/*Rdy_i*/ >= cap);
    assign empty = (wei + En_i - tou - 1/*Rdy_i*/ == 0);
    assign tou_p = tou[4:0] + 1/*Rdy_i*/;
    assign wei_p = wei[4:0];

    always @ (posedge clk or negedge rst) begin
        if (rst) begin
            tou <= 0; wei <= 0; cmt <= 0;
            Full_o <= 0; Empty_o <= 1;
            dataEn_o <= 0; cdbEn_o <= 0;
        end else if (rdy) begin
            if (En_i) begin
                addr[wei_p] <= Addr_i;
                data[wei_p] <= r2Data_i;
                op[wei_p] <= Opcode_i;
                id[wei_p] <= Id_i;
            end
            tou <= tou + 1/*Rdy_i*/;
            wei <= (clr_i ? cmt + LSEn_i : wei + En_i);
            Full_o <= full; Empty_o <= empty; cmt <= cmt + LSEn_i;// ????
            if (tou/*Rdy_i*/ < wei && tou/*Rdy_i*/ < cmt) begin
                dataEn_o <= 1;
                dataAddr_o <= addr[tou_p];
                dataData_o <= data[tou_p];
                case (op[tou_p])
                    `LB, `LBU:  begin dataRw_o <= 0; dataWid_o <= 3'h1; end
                    `LH, `LHU:  begin dataRw_o <= 0; dataWid_o <= 3'h2; end
                    `LW:        begin dataRw_o <= 0; dataWid_o <= 3'h4; end
                    `SB:        begin dataRw_o <= 1; dataWid_o <= 3'h1; end
                    `SH:        begin dataRw_o <= 1; dataWid_o <= 3'h2; end
                    `SW:        begin dataRw_o <= 1; dataWid_o <= 3'h4; end
                endcase
            end else dataEn_o <= 0;
            if (1/*Rdy_i*/ && op[tou[4:0]] >= `LB && op[tou[4:0]] <= `LHU) begin
                cdbEn_o <= 1;
                cdbId_o <= id[tou[4:0]];
                case (op[tou[4:0]])
                    `LB:  cdbData_o <= {{24{dataData_i[7]}}, dataData_i[7:0]};
                    `LH:  cdbData_o <= {{16{dataData_i[15]}}, dataData_i[15:0]};
                    `LW:  cdbData_o <= dataData_i;
                    `LBU: cdbData_o <= {24'b0, dataData_i[7:0]};
                    `LHU: cdbData_o <= {16'b0, dataData_i[15:0]};
                endcase
            end else cdbEn_o <= 0;
        end
    end
    
endmodule