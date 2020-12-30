`include "define.v"

module regfile(
    input wire rst,
    input wire clk,
    input wire rdy,

    // request from ROB
    input wire wEn_i,
    input wire [`ROBAddrBus] wId_i,
    input wire [`RegAddrBus] wAddr_i,
    input wire [`RegBus] wData_i,
    // request(lock) from dispatcher
    input wire sEn_i,
    input wire [`RegAddrBus] sAddr_i,
    input wire [`ROBAddrBus] sId_i,

    // request from dispatcher
    input wire r1En_i,
    input wire [`RegAddrBus] r1Addr_i,
    input wire r2En_i,
    input wire [`RegAddrBus] r2Addr_i,    
    // response to dispather
    output reg r1Rdy_o,
    output reg [`ROBBus] r1Id_o,
    output reg [`RegBus] r1Data_o,
    output reg r2Rdy_o,
    output reg [`ROBBus] r2Id_o,
    output reg [`RegBus] r2Data_o
);

//定义32个32位寄存器
    reg [31:0] regs[`RegNum-1:0];
    reg [4:0]  regId[`RegNum-1:0];
    reg [31:0] regRdy;  //1是新值，0还在算
    reg [31:0] i;

//寄存器初始化
    initial begin
        regRdy <= `One32;
        for (i = 0; i < `RegNum; i = i + 1) begin
            regs[i] <= 0;
            regId[i] <= 0;
        end
    end

//写操作(时序，上升沿写)
    always @ (posedge clk or posedge rst) begin
        if (rst)
            regRdy <= `One32;
        /*
        else if (rdy) begin
            if (wEn_i && wAddr_i != 0) // 写入值
                regs[wAddr_i] <= wData_i;
            if (sEn_i)  // 写寄存器编号
                regId[sAddr_i] <= sId_i;
            if (sEn_i && wEn_i && wAddr_i == sAddr_i)
                regRdy[sAddr_i] <= 0;
            else begin
                if (wEn_i && regId[wAddr_i] == wId_i)
                    regRdy[wAddr_i] <= 1;
                if (sEn_i)
                    regRdy[sAddr_i] <= 0;
            end
        end
        */
        else if (rdy) begin
            if (sEn_i) begin
                regId[sAddr_i] <= sId_i;
                regRdy[sAddr_i] <= 0;
            end
            if (wEn_i && regId[wAddr_i] == wId_i && 
                    (!sEn_i || sEn_i != wEn_i)) begin
                regs[wAddr_i] <= wData_i;
                regRdy[wAddr_i] <= 1;
            end
        end
    end

//读操作(组合)
    always @ (*) begin
        if (rst || r1En_i == 0) begin
            r1Rdy_o <= 0;
            r1Id_o <= 0;
            r1Data_o <= 0;
        end else if (r1Addr_i == 0) begin
            r1Rdy_o <= 1;
            r1Id_o <= 0;
            r1Data_o <= 0;
        end else if (r1Addr_i == wAddr_i && // forwarding
                    wEn_i  && wId_i == regId[wAddr_i]) begin
            r1Rdy_o <= 1;
            r1Id_o <= 0;
            r1Data_o <= wData_i;
        end else begin
            r1Rdy_o <= 1;
            if (regRdy[r1Addr_i]) begin
                r1Id_o <= 0;
                r1Data_o <= regs[r1Addr_i];
            end else begin
                r1Id_o <= regId[r1Addr_i];
                r1Data_o <= 0;
            end
        end
    end

    always @(*) begin
        if (rst || r2En_i == 0) begin
            r2Rdy_o <= 0;
            r2Id_o <= 0;
            r2Data_o <= 0;
        end else if (r2Addr_i == 0) begin
            r2Rdy_o <= 1;
            r2Id_o <= 0;
            r2Data_o <= 0;
        end else if (r2Addr_i == wAddr_i && // forwarding
                    wEn_i  && wId_i == regId[wAddr_i]) begin
            r2Rdy_o <= 1;
            r2Id_o <= 0;
            r2Data_o <= wData_i;
        end else begin
            r2Rdy_o <= 1;
            if (regRdy[r2Addr_i]) begin
                r2Id_o <= 0;
                r2Data_o <= regs[r2Addr_i];
            end else begin
                r2Id_o <= regId[r2Addr_i];
                r2Data_o <= 0;
            end
        end
    end

endmodule