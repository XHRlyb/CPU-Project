`include "define.v"

module CDB(
    input wire clk,
    input wire rst,
    input wire rdy,
    // inform from LSBuffer
    input wire LSBufEn_i,
    input wire [`ROBAddrBus] LSBufId_i,
    input wire [`DataBus] LSBufData_i,
    // inform from ALU
    input wire ALUEn_i,
    input wire [`ROBAddrBus] ALUId_i,
    input wire [`DataBus] ALUData_i,
    input wire [`DataBus] ALUPc_i,
    input wire ALUCond_i,
    // infrom to LSRS
    output reg LSRScdb1En_o,
    output reg [`ROBBus] LSRScdb1Id_o,
    output reg [`DataBus] LSRScdb1Data_o,
    output reg LSRScdb2En_o,
    output reg [`ROBBus] LSRScdb2Id_o,
    output reg [`DataBus] LSRScdb2Data_o,
    // infrom to RS
    output reg RScdb1En_o,
    output reg [`ROBBus] RScdb1Id_o,
    output reg [`DataBus] RScdb1Data_o,
    output reg RScdb2En_o,
    output reg [`ROBBus] RScdb2Id_o,
    output reg [`DataBus] RScdb2Data_o,
    // infrom to dispatch
    output reg DPcdb1En_o,
    output reg [`ROBBus] DPcdb1Id_o,
    output reg [`DataBus] DPcdb1Data_o,
    output reg DPcdb2En_o,
    output reg [`ROBBus] DPcdb2Id_o,
    output reg [`DataBus] DPcdb2Data_o,
    // inform to ROB
    output reg ROBcdb1En_o,
    output reg [`ROBBus] ROBcdb1Id_o,
    output reg [`DataBus] ROBcdb1Data_o,
    output reg ROBcdb2En_o,
    output reg [`ROBBus] ROBcdb2Id_o,
    output reg [`DataBus] ROBcdb2Data_o,
    output reg [`DataBus] ROBcdb2Pc_o,
    output reg ROBcdb2Cond_o
);

    always @ (*) begin
        if (rst) begin
            LSRScdb1En_o <= 0; LSRScdb2En_o <= 0;
            RScdb1En_o <= 0; RScdb2En_o <= 0;
            ROBcdb1En_o <= 0; ROBcdb2En_o <= 0;
        end else if (rdy) begin
            if (LSBufEn_i) begin
                LSRScdb1En_o <= 1;
                LSRScdb1Id_o <= LSBufId_i;
                LSRScdb1Data_o <= LSBufData_i;
                RScdb1En_o <= 1;
                RScdb1Id_o <= LSBufId_i;
                RScdb1Data_o <= LSBufData_i;
                DPcdb1En_o <= 1;
                DPcdb1Id_o <= LSBufId_i;
                DPcdb1Data_o <= LSBufData_i;
                ROBcdb1En_o <= 1;
                ROBcdb1Id_o <= LSBufId_i;
                ROBcdb1Data_o <= LSBufData_i;
            end else begin
                LSRScdb1En_o <= 0;
                RScdb1En_o <= 0;
                ROBcdb1En_o <= 0;
            end
            if (ALUEn_i) begin
                LSRScdb2En_o <= 1;
                LSRScdb2Id_o <= ALUId_i;
                LSRScdb2Data_o <= ALUData_i;
                RScdb2En_o <= 1;
                RScdb2Id_o <= ALUId_i;
                RScdb2Data_o <= ALUData_i;
                DPcdb2En_o <= 1;
                DPcdb2Id_o <= LSBufId_i;
                DPcdb2Data_o <= LSBufData_i;
                ROBcdb2En_o <= 1;
                ROBcdb2Id_o <= ALUId_i;
                ROBcdb2Data_o <= ALUData_i;
                ROBcdb2Pc_o <= ALUPc_i;
                ROBcdb2Cond_o <= ALUCond_i;
            end else begin
                LSRScdb2En_o <= 0;
                RScdb2En_o <= 0;
                ROBcdb2En_o <= 0;
            end
        end
    end

endmodule