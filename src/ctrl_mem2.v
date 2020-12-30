`include "define.v"

module ctrl_mem1(
    input wire clk,
    input wire rst,
    input wire rdy,
    // 清空标记
    input wire clr_i,
    // request from icache
    input wire ifEn_i,
    input wire [`InstAddrBus] ifAddr_i,
    // response to icahce
    output reg ifBusy_o,
    output reg ifRdy_o,
    output reg [`InstBus] ifData_o,
    // request about data-loading&storing
    input wire dataEn_i,
    input wire dataRw_i, // 0-read, 1-write
    input wire [`DataWidBus] dataWid_i,
    input wire [`InstAddrBus] dataAddr_i,
    input wire [`InstBus] dataData_i, // just for write
    output reg dataRdy_o,
    output reg dataRBusy_o,
    output reg dataWBusy_o,
    output wire dataWSuc,
    output reg [`DataBus] dataData_o,
    // request to RAM
    output wire memRw_o,
    output reg [`MemAddrBus] memAddr_o,
    output wire [`ByteBus] memData_o,
    // response from RAM
    input wire [`ByteBus] memData_i
);

    reg ahead, aheadRdy;
    reg [2:0] cur, ahead_cur;
    reg [`ByteBus] ifRet[3:0], dataRet[2:0];
    reg [`MemAddrBus] aheadAddr;
    wire [`MemAddrBus] delay_aheadAddr = ifAddr_i + 4;

    wire dataRWor, ifWor, aheadWor, dataWWor;
    assign dataRWor = dataEn_i && (dataRw_i == 0) && !dataRdy_o;
    assign ifWor = (ifEn_i == 1) && (ifRdy_o == 0);
    assign aheadWor = ahead && !aheadRdy;
    assign dataWWor = dataEn_i && (dataRw_i == 1);

    assign dataWSuc = !dataRWor && !ifWor && !aheadWor && dataWWor;
    assign memRw_o = dataWSuc;
    assign memData_o = dataData_i;

    always @ (*) begin
        if (dataRWor)
            memAddr_o = (ahead && dataWid_i == cur) ? aheadAddr + ahead_cur : dataAddr_i + cur;
        else if (ifWor)
            memAddr_o = (ahead && aheadAddr == ifAddr_i) ? aheadAddr + ahead_cur : ifAddr_i + cur;
        else if (aheadWor)
            memAddr_o = aheadAddr + ahead_cur;
        else if (dataWWor)
            memAddr_o = dataAddr_i;
        else 
            memAddr_o = 0;
    end

    always @ (posedge clk) begin
        if (rst || clr_i) begin
            ifRdy_o <= 0; dataRdy_o <= 0;
            ifBusy_o <= 0; dataRBusy_o <= 0; dataWBusy_o <= 0;
            ahead <= 0; cur <= 0; ahead_cur <= 0;
        end else if (dataRWor) begin
            if (cur == 0) begin
                ifRdy_o <= 0; dataRdy_o <= 0;
                ifBusy_o <= 1; dataRBusy_o <= 0; dataWBusy_o <= 1;
                if (dataAddr_i[17]) ahead <= 0;  //?????
                else if (!aheadRdy) ifRet[ahead_cur-1] <= memData_i;
                cur <= 1; 
            end else if (cur < dataWid_i) begin
                dataRet[cur-1] <= memData_i;
                cur <= cur + 1;
            end else begin
                dataRdy_o <= 1;
                ifBusy_o <= 0; dataWBusy_o <= 0;
                cur <= 0;
                case (dataWid_i)
                    1: dataData_o <= {{24{memData_i[7]}}, memData_i};
                    2: dataData_o <= {{16{memData_i[7]}}, memData_i, dataRet[0]};
                    4: dataData_o <= {memData_i, dataRet[2], dataRet[1], dataRet[0]};
                endcase
                if (ahead && !aheadRdy) begin
                    if (ahead_cur[2]) aheadRdy <= 1;
                    else ahead_cur <= ahead_cur + 1;
                end
            end
        end else if (ifWor) begin
            if (cur == 0) begin
                if (!ahead || aheadAddr != ifAddr_i) begin
                    ifRdy_o <= 0; dataRdy_o <= 0; 
                    ifBusy_o <= 0; dataRBusy_o <= 1; dataWBusy_o <= 1;
                    cur <= 1;
                end else if (aheadRdy) begin
                    ifRdy_o <= 1; dataRdy_o <= 0; 
                    ifBusy_o <= 0; dataRBusy_o <= 0; dataWBusy_o <= 0;
                    cur <= 0;
                    ifData_o <= {ifRet[3], ifRet[2], ifRet[1], ifRet[0]};
                    aheadAddr <= delay_aheadAddr;
                    ahead_cur <= 1;
                    aheadRdy <= 0;
                end else if (ahead_cur[2]) begin
                    ifRdy_o <= 1; dataRdy_o <= 0; 
                    ifBusy_o <= 0; dataRBusy_o <= 0; dataWBusy_o <= 0;
                    cur <= 0;
                    ifData_o <= {memData_i, ifRet[2], ifRet[1], ifRet[0]};
                    aheadAddr <= delay_aheadAddr;
                    ahead_cur <= 1;
                    aheadRdy <= 0;
                end else begin
                    ifRdy_o <= 0; dataRdy_o <= 0; 
                    ifBusy_o <= 0; dataRBusy_o <= 1; dataWBusy_o <= 1;
                    ifRet[ahead_cur - 1] <= memData_i;
                    cur <= ahead_cur + 1;
                    ahead <= 0;
                end 
            end else if (!cur[2]) begin
                ifRet[cur-1] <= memData_i;
                cur <= cur + 1;
            end else begin
                ifRdy_o <= 1;
                dataRBusy_o <= 0; dataWBusy_o <= 0;
                cur <= 0;
                ifData_o <= {memData_i, ifRet[2], ifRet[1], ifRet[0]};
                ahead <= 1;
                aheadAddr <= delay_aheadAddr;
                ahead_cur <= 1;
                aheadRdy <= 0;
            end
        end else if (aheadWor) begin
            ifRdy_o <= 0; dataRdy_o <= 0;
            ifRet[ahead_cur-1] <= memData_i;
            if (ahead_cur[2]) aheadRdy <= 1;
            else ahead_cur <= ahead_cur + 1;
        end else begin
            ifRdy_o <= 0; dataRdy_o <= 0;
        end
    end


endmodule