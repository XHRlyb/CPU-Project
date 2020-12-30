`include "define.v"

module iqueue2(
    input wire clk,
    input wire rst,
    input wire rdy,
    //清空标记
    input wire clr_i,
    // inform to IF
    output reg Full_o,
    // request from IF
    input wire addEn_i,
    input wire [`DataBus] addData_i,
    input wire [`DataBus] addPc_i,
    // request from ID
    input wire fetchEn_i,
    // response to ID
    output reg Empty_o,
    output reg [`DataBus] fetchData_o,
    output reg [`DataBus] fetchPc_o
);

    parameter cap = `IqueueNumLog2'h1e;

    reg [`DataBus] pc[`IqueueNum-1:0], data[`IqueueNum-1:0];
    reg [`IqueueNumLog2-1:0] tou, wei;

    wire Full, Empty;
    wire [`IqueueNumLog2-1:0] tou_p;

    assign Full = (wei - tou + addEn_i - 1/*fetchEn_i*/ > cap + 1)?1:0;
    assign Empty = (wei - tou + addEn_i - 1/*fetchEn_i*/ == 0);
    assign tou_p = tou + 1/*fetchEn_i*/;

    always @ (posedge clk) begin
        if (rst || clr_i) begin
            tou <= 0; wei <= 0;
            Full_o <= 0; Empty_o <= 1;
        end else if (rdy) begin
            if (addEn_i) begin
                data[wei] <= addData_i;
                pc[wei] <= addPc_i;
            end
            tou <= tou + 1/*fetchEn_i*/;
            wei <= wei + addEn_i;
            Full_o <= Full;
            Empty_o <= Empty;
            if (wei == tou_p && addEn_i) begin
                fetchData_o <= addData_i;
                fetchPc_o <= addPc_i;
            end else begin
                fetchData_o <= data[tou_p];
                fetchPc_o <= pc[tou_p];
            end
        end
    end

endmodule