`include "define.v"

module icache(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire clr_i,
    // request to mem-ctrl
    output reg memEn_o,
    output wire [`MemAddrBus] memAddr_o,
    // response from mem-ctrl
    input wire memBusy_i,
    input wire memRdy_i,
    input wire [`MemDataBus] memData_i,
    // request from IF
    input wire ifRdy_i,
    input wire [`MemAddrBus] ifAddr_i,
    // response to IF
    output reg ifEn_o,
    output reg [`MemDataBus] ifData_o
);

    reg [`MemDataBus] icacheData[`ICacheNum-1:0];
    reg [`ICacheTagBus] icacheTag[`ICacheNum-1:0];
    reg [`ICacheNum-1:0] icacheVld;

    reg miss;
    reg delayEn;
    reg [31:0] i;

    wire [`ICacheBus] AddrIdx = ifAddr_i[`ICacheBus];
    wire [`ICacheTagBytes] AddrTag = ifAddr_i[`ICacheTagBytes];

    assign memAddr_o = ifAddr_i;

    // 初始化 icache
    initial begin
        for (i = 0; i < `ICacheNum; i = i + 1)
            icacheVld[i] = 0; 
    end
    
    // 
    always @ (*) begin
        if (rst || !ifRdy_i || clr_i) begin
            icacheVld = 0;
            ifEn_o = 0; ifData_o = 0; miss = 0; memEn_o = 0;
        end else begin
            if (icacheVld[AddrIdx] && icacheTag[AddrIdx] == AddrTag) begin
                ifEn_o = 1; ifData_o = icacheData[AddrIdx]; miss = 0; memEn_o = 0;
            end else if (memRdy_i) begin
                ifEn_o = 1; ifData_o = memData_i; miss = 0; memEn_o = 0;
                icacheVld[AddrIdx] = 1;
                icacheTag[AddrIdx] = AddrTag;
                icacheData[AddrIdx] = memData_i;
            end else begin
                if (miss == 0) memEn_o = 1;
                    else memEn_o = 0;
                ifEn_o = 0; ifData_o = 0; miss = 1;
            end
        end
    end

    /*always @ (posedge clk) begin
        delayEn <= !rst && miss;
        memEn_o <= !rst && miss;
        //memEn_o <= delayEn && !memBusy_i;
        //memAddr_o = ifAddr_i;
    end //*/
    /*always @ (*) begin
        delayEn = !rst && miss;
        memEn_o = delayEn;// && !memBusy_i;
        //memAddr_o = ifAddr_i;
    end //*/
    /*always @ (posedge clk) begin
        delayEn <= !rst && miss;
        //memAddr_o <= ifAddr_i;
    end//*/ 

  

endmodule