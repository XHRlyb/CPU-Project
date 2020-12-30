`include "define.v"

module ctrl_mem4(
    input wire clk,
    input wire rst,
    input wire rdy,
    // 清空标记
    input wire clr_i,
    // request from icache
    input wire ifEn_i,
    input wire [`InstAddrBus] ifAddr_i,
    // response to icahce
    output reg ifRdy_o,
    output reg ifBusy_o,
    output reg [`InstBus] ifData_o,
    // request about data-loading&storing
    input wire dataEn_i,
    input wire dataRw_i, // 0-read, 1-write
    input wire [`DataWidBus] dataWid_i,
    input wire [`InstAddrBus] dataAddr_i,
    input wire [`InstBus] dataData_i, // just for write
    output reg dataRdy_o,
    output reg [`DataBus] dataData_o,
    // request to RAM
    output wire memRw_o,
    output wire [`MemAddrBus] memAddr_o,
    output wire [`ByteBus] memData_o,
    // response from RAM
    input wire [`ByteBus] memData_i
);

    reg sta, rw, port, wai_rw;
    reg [1:0] wai;
    reg [31:0] wai_addr[1:0], wai_data, plfm_addr;
    reg [`DataWidBus] wai_wid, stag, wid;
    reg [`ByteBus] plfm_data[4:0];

    assign memRw_o = rw;
    assign memAddr_o = plfm_addr;
    assign memData_o = plfm_data[stag];

    /*always @ (*) begin
        if (rst) 
            ifBusy_o = 0;
        else begin
            if (sta == 0)
                ifBusy_o = !(wai[1] == 0 && wai[0] == 1);
            else begin
                if (stag == wid) ifBusy_o = 
            end
        end
    end //*/

    always @ (*) begin
        if (rst || clr_i) begin
            ifBusy_o = 0;
            plfm_data[4] = 0;
        end else if (rdy) begin
            case (sta)
                0: begin
                    if (dataEn_i) begin
                        if (ifEn_i) begin
                            ifBusy_o = 1;
                        end
                    end else begin 
                        ifBusy_o = 0;
                    end
                end
                1: begin 
                    ifBusy_o = 1;/*
                    if (stag == wid) begin
                        if (wai[1]) begin
                            ifBusy_o = wai[0];
                        end else if (wai[0]) begin
                            ifBusy_o = 0;
                        end else if (dataEn_i) begin
                            ifBusy_o = wai[0];
                        end else if (ifEn_i) begin
                            ifBusy_o = 0;
                        end else begin
                            ifBusy_o <= 0;
                        end
                    end else begin
                        if (ifEn_i) begin
                            ifBusy_o = 1;
                        end 
                    end //*/

                end

            endcase
        end
    end
    

    always @ (posedge clk) begin
        if (rst || clr_i) begin
            sta <= 0; stag <= 0; wai <= 0;
            ifRdy_o <= 0; dataRdy_o <= 0; 
            //ifBusy_o <= 0;
        end else if (rdy) begin
            /*if (ifEn_i) begin
                wai[0] <= 1;
                wai_rw[0] <= 0;
                wai_wid[0] <= 4;
                wai_addr[0] <= ifAddr_i;
            end
            if (dataEn_i) begin
                wai[1] <= 1;
                wai_rw[1] <= dataRdy_o;
                wai_wid[1] <= dataWid_i;
                wai_addr[1] <= dataAddr_i;
                wai_data <= dataData_i;
            end*/
            case (sta)
                0: begin
                    ifRdy_o <= 0; dataRdy_o <= 0; 
                    if (dataEn_i) begin
                        port <= 1;
                        rw <= dataRw_i;
                        wid <= dataWid_i;
                        plfm_addr <= dataAddr_i;
                        plfm_data[0] <= dataData_i[7:0];
                        plfm_data[1] <= dataData_i[15:8];
                        plfm_data[2] <= dataData_i[23:16];
                        plfm_data[3] <= dataData_i[31:24];
                        sta <= 1; stag <= 0;
                        if (ifEn_i) begin
                            wai[0] <= 1;
                            wai_addr[0] <= ifAddr_i;
                            //ifBusy_o <= 1;
                        end else begin
                            //ifBusy_o <= 1;
                        end
                    end else begin 
                        if (ifEn_i) begin
                            port <= 0;
                            rw <= 0;
                            wid <= 4;
                            plfm_addr <= ifAddr_i;
                            sta <= 1; stag <= 0;
                            //ifBusy_o <= 0;
                        end else begin
                            sta <= 0; 
                            //ifBusy_o <= 0;
                        end
                    end
                end

                1: begin
                    if (port == 0) begin
                        case (stag)
                            1: ifData_o[7:0] <= memData_i;
                            2: ifData_o[15:8] <= memData_i;
                            3: ifData_o[23:16] <= memData_i;
                            4: ifData_o[31:24] <= memData_i;
                        endcase
                    end else begin
                        case (stag)
                            1: dataData_o[7:0] <= memData_i;
                            2: dataData_o[15:8] <= memData_i;
                            3: dataData_o[23:16] <= memData_i;
                            4: dataData_o[31:24] <= memData_i;
                        endcase
                    end 

                    if (stag == wid) begin
                        
                        ifRdy_o <= (port == 0);
                        dataRdy_o <= (port == 1);
                        
                        if (wai[1]) begin
                            //ifBusy_o <= wai[0];
                            port <= 1;
                            rw <= wai_rw;
                            wid <= wai_wid;
                            plfm_addr <= wai_addr[1];
                            plfm_data[0] <= wai_data[7:0];
                            plfm_data[1] <= wai_data[15:8];
                            plfm_data[2] <= wai_data[23:16];
                            plfm_data[3] <= wai_data[31:24];
                            sta <= 1; stag <= 0; wai[1] <= 0;
                        end else if (wai[0]) begin
                            //ifBusy_o <= 0;
                            port <= 0;
                            rw <= 0;
                            wid <= 4;
                            plfm_addr <= wai_addr[0];
                            sta <= 1; stag <= 0; wai[0] <= 0;
                        end else if (dataEn_i) begin
                            //ifBusy_o <= wai[0];
                            port <= 1;
                            rw <= dataRw_i;
                            wid <= dataWid_i;
                            plfm_addr <= dataAddr_i;
                            plfm_data[0] <= dataData_i[7:0];
                            plfm_data[1] <= dataData_i[15:8];
                            plfm_data[2] <= dataData_i[23:16];
                            plfm_data[3] <= dataData_i[31:24];
                            sta <= 1; stag <= 0;
                        end else if (ifEn_i) begin
                            //ifBusy_o <= 0;
                            port <= 0;
                            rw <= 0;
                            wid <= 4;
                            plfm_addr <= ifAddr_i;
                            sta <= 1; stag <= 0; 
                        end else begin
                            sta <= 0; stag <= 0;
                            //ifBusy_o <= 0;
                        end
                    end else begin
                        if (stag + 1 == wid) rw <= 0;
                        if (dataEn_i) begin
                            wai[1] <= 1;
                            wai_rw <= dataRw_i;
                            wai_wid <= dataWid_i;
                            wai_addr[1] <= dataAddr_i;
                            wai_data <= dataData_i;
                        end
                        ifRdy_o <= 0; dataRdy_o <= 0;
                        sta <= 1; stag <= stag + 1;
                        plfm_addr <= plfm_addr + 1;
                    end

                end

            endcase
        end
    end

    


endmodule