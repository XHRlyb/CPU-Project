`include "define.v"

module iqueue(
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
    // inform to ID
    output reg Empty_o,
    output reg [`DataBus] fetchData_o,
    output reg [`DataBus] fetchPc_o
);

    parameter cap = `IqueueNumLog2'h1e;

    reg [`DataBus] pc[`IqueueNum-1:0], data[`IqueueNum-1:0];
    reg [31:0] tou, wei;

    wire Full, Empty;
    wire [`IqueueNumLog2-1:0] tou_p, wei_p, ntou_p, nwei_p, cnt;

    assign Full = (wei - tou + addEn_i >= 32);
    assign Empty = (wei - tou + addEn_i == 0);
    assign cnt = wei - tou;
    assign tou_p = tou[`IqueueNumLog2-1:0];
    assign wei_p = wei[`IqueueNumLog2-1:0];
    assign ntou_p = (tou_p == 5'b11111 ? 0 : tou_p + 1);
    assign nwei_p = (wei_p == 5'b11111 ? 0 : wei_p + 1);

    always @ (posedge clk) begin
        if (rst || clr_i) begin
            tou <= 0; wei <= 0;
            Full_o <= 0; Empty_o <= 1;
        end else if (rdy) begin
            if (addEn_i && cnt == 32) begin
                fetchData_o <= addData_i;
                fetchPc_o <= addPc_i;
                Empty_o <= 0;
            end else begin
                if (addEn_i) begin
                    wei <= wei + 1;
                    data[wei_p] <= addData_i;
                    pc[wei_p] <= addPc_i;
                end
                if (cnt > 0) begin
                    tou <= tou + 1;
                    fetchData_o <= data[tou_p];
                    fetchPc_o <= pc[tou_p];
                    Empty_o <= 0;
                end else Empty_o <= 1;
            end
        end
    end

endmodule