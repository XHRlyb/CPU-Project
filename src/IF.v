`include "define.v"

module IF(
    input wire clk,
    input wire rst,
    input wire rdy,
    // request to icache
    output reg icacheEn_o,
    output reg [`MemAddrBus] icacheAddr_o,
    // response from icache
    input wire icacheRdy_i,
    input wire [`MemDataBus] icacheData_i,
    // inform from iqueue
    input wire iqueueFull_i,
    // inst add to iqueue
    output reg iqueueEn_o,
    output reg [`DataBus] iqueueData_o,
    output reg [`DataBus] iqueuePc_o,
    // from ROB-cleaner
    input wire newEn_i,
    input wire [`DataBus] newPc_i,
    // from dispatcher-pridict
    input wire BrPridEn_i,
    input wire [`DataBus] BrPridPc_i
);

    reg [`DataBus] pc, npc;

    always @ (posedge clk) begin
        if (rst) begin
            pc <= 0;
            npc <= 4;
            icacheEn_o <= 0;
            iqueueEn_o <= 0;
        end else if (rdy) begin
            if (newEn_i) begin
                pc <= newPc_i; npc <= newPc_i + 4;
                icacheEn_o <= 1;
                icacheAddr_o <= newPc_i;
                iqueueEn_o <= 0;
            end else if (BrPridEn_i) begin
                pc <= BrPridPc_i; npc <= BrPridPc_i + 4;
                icacheEn_o <= 1;
                icacheAddr_o <= BrPridPc_i;
                iqueueEn_o <= 0;
            end else if (icacheRdy_i && !iqueueFull_i) begin
                pc <= npc; npc <= npc + 4;
                icacheEn_o <= 1;
                icacheAddr_o <= npc;
                iqueueEn_o <= 1;
                iqueueData_o <= icacheData_i;
                iqueuePc_o <= pc;
            end else begin
                icacheEn_o <= 1;
                icacheAddr_o <= pc;
                iqueueEn_o <= 0;
            end
        end
    end

endmodule