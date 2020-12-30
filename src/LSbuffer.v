`include "define.v"

module LSbuffer(
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

    wire [31:0] cnt;
    wire [`LSBufNumLog2-1:0] tou_p, wei_p, cmt_p;

    assign cnt = wei - tou;
    assign tou_p = tou[`LSBufNum-1:0];
    assign wei_p = wei[`LSBufNum-1:0];
    assign cmt_p = cmt[`LSBufNum-1:0];

    always @ (posedge clk or negedge rst) begin
        if (rst || clr_i) begin
            tou <= 1; wei <= 1; cmt <= 0;
            cdbEn_o <= 0;
        end else if (rdy) begin
            if (En_i) begin
                wei <= wei + 1;
                addr[wei_p] <= Addr_i;
                data[wei_p] <= r2Data_i;
                op[wei_p] <= Opcode_i;
                id[wei_p] <= Id_i;
            end
            if (cnt > 0 && cmt + 1 == tou) begin
                cmt <= cmt + 1;
            end //else dataEn_o <= 0;
            if (Rdy_i) begin
                tou <= tou + 1;
                if (op[tou_p] >= `LB && op[tou_p] <= `LHU) begin
                    cdbEn_o <= 1;
                    cdbId_o <= id[tou_p];
                    case (op[tou_p])
                        `LB:  cdbData_o <= {{24{dataData_i[7]}}, dataData_i[7:0]};
                        `LH:  cdbData_o <= {{16{dataData_i[15]}}, dataData_i[15:0]};
                        `LW:  cdbData_o <= dataData_i;
                        `LBU: cdbData_o <= {24'b0, dataData_i[7:0]};
                        `LHU: cdbData_o <= {16'b0, dataData_i[15:0]};
                    endcase
                end else if (op[tou_p] >= `SB && op[tou_p] <= `SW) begin
                    cdbEn_o <= 1;
                    cdbId_o <= id[tou_p];
                    cdbData_o <= 0;
                end else cdbEn_o <= 0;
            end else cdbEn_o <= 0;
        end
    end

    always @ (*) begin
        if (rst || clr_i) begin
            dataEn_o = 0;
        end else if (rdy) begin
            if (cnt > 0 && cmt + 1 == tou) begin
                dataEn_o = 1;
                dataAddr_o = addr[tou_p];
                dataData_o = data[tou_p];
                case (op[tou_p])
                    `LB, `LBU:  begin dataRw_o = 0; dataWid_o = 3'h1; end
                    `LH, `LHU:  begin dataRw_o = 0; dataWid_o = 3'h2; end
                    `LW:        begin dataRw_o = 0; dataWid_o = 3'h4; end
                    `SB:        begin dataRw_o = 1; dataWid_o = 3'h1; end
                    `SH:        begin dataRw_o = 1; dataWid_o = 3'h2; end
                    `SW:        begin dataRw_o = 1; dataWid_o = 3'h4; end
                endcase
            end 
            if (Rdy_i) begin
                dataEn_o = 0;
            end
        end
    end
    
endmodule