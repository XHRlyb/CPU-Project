`include "define.v"

module RS(
    input wire clk,
    input wire rst,
    input wire rdy,
    //清空标记
    input wire clr_i,
    //
    output reg Empty_o,
    output reg Full_o,
    // request(add-inst) from dispatcher
    input wire En_i,
    input wire [`OpCodeBus] Opcode_i,
    input wire [`DataBus] Pc_i,
    input wire [`DataBus] Imm_i,
    input wire [`DataBus] r1Data_i,
    input wire [`DataBus] r2Data_i,
    input wire [`ROBBus] r1Id_i,
    input wire [`ROBBus] r2Id_i,
    input wire [`ROBBus] Id_i,
    // request(add-inst) to ALU
    output reg ALUEn_o,
    output reg [`OpCodeBus] ALUOpcode_o,
    output reg [`DataBus] ALUImm_o,
    output reg [`DataBus] ALUPc_o,
    output reg [`DataBus] ALUr1Data_o,
    output reg [`DataBus] ALUr2Data_o,
    output reg [`ROBBus] ALUId_o,
    // fetch updated data from CDB
    input wire cdb1En_i,
    input wire [`ROBBus] cdb1Id_i,
    input wire [`DataBus] cdb1Data_i,
    input wire cdb2En_i,
    input wire [`ROBBus] cdb2Id_i,
    input wire [`DataBus] cdb2Data_i
);

    parameter cap = `RSNumLog2'h1e;
    parameter avail_empty = {`RSNum{1'b1}};

    reg [`ROBBus] r1_id[`RSNum-1:0], r2_id[`RSNum-1:0], id[`RSNum-1:0];
    reg [`DataBus] r1_data[`RSNum-1:0], r2_data[`RSNum-1:0], imm[`RSNum-1:0], pc[`RSNum-1:0];
    reg [`OpCodeBus] op[`RSNum-1:0];
    reg [`RSNum-1:0] r1_rdy, r2_rdy, avail;
    reg [31:0] i;

    wire Full, Empty;
    wire [`RSNum-1:0] rrdy;
    reg [`RSNum-1:0] Cur, cur, i;

    assign Full = (avail == 1);
    assign Empty = (avail == avail_empty);

    always @ (*) begin
        if (rst || clr_i)
            Cur = 1;
        else if (Full) begin
            Cur = 0;
        end else begin
            Cur = 1;
            for (i = 1; i <= `RSNum - 1; i = i + 1)
                if (avail[i]) begin
                    Cur = i;
                end
        end
    end
    
// 
    always @ (posedge clk) begin
        if (rst || clr_i) begin
            Full_o <= 0; Empty_o <= 1; 
            avail <= avail_empty;
            ALUEn_o <= 0;
            r1_rdy <= 0;
            r2_rdy <= 0;
            cur <= 0;
        end else if (rdy) begin
            Full_o <= Full;
            Empty_o <= Empty;
            if (En_i && r1Id_i == 0 && r2Id_i == 0) begin
                ALUEn_o <= 1;
                ALUOpcode_o <= Opcode_i;
                ALUPc_o <= Pc_i;
                ALUImm_o <= Imm_i;
                ALUr1Data_o <= r1Data_i;
                ALUr2Data_o <= r2Data_i;
                ALUId_o <= Id_i;
            end else begin      
                if (En_i) begin
                    pc[Cur] <= Pc_i;
                    imm[Cur] <= Imm_i;                  
                    r1_id[Cur] <= r1Id_i;
                    r2_id[Cur] <= r2Id_i;
                    r1_data[Cur] <= r1Data_i;
                    r2_data[Cur] <= r2Data_i;
                    r1_rdy[Cur] <= (r1Id_i == 0);
                    r2_rdy[Cur] <= (r2Id_i == 0);
                    id[Cur] <= Id_i;
                    op[Cur] <= Opcode_i;
                    avail[Cur] <= 0;
                end
                if (cur != 0) begin
                    ALUEn_o <= 1;
                    ALUOpcode_o <= op[cur];
                    ALUPc_o <= pc[cur];
                    ALUImm_o <= imm[cur];
                    ALUr1Data_o <= r1_data[cur];
                    ALUr2Data_o <= r2_data[cur];
                    ALUId_o <= id[cur];
                    avail[cur] <= 1;
                    r1_rdy[cur] <= 0;
                    r2_rdy[cur] <= 0;
                    cur <= 0;
                end else ALUEn_o <= 0;
            end
            if (cdb1En_i) begin
                for (i = 1; i < `RSNum; i = i + 1) begin
                    if (!avail[i] && r1_id[i] == cdb1Id_i) begin
                        r1_data[i] <= cdb1Data_i;
                        r1_rdy[i] <= 1;
                        if (r2_rdy[i]) cur <= i;
                    end
                    if (!avail[i] && r2_id[i] == cdb1Id_i) begin
                        r2_data[i] <= cdb1Data_i; 
                        r2_rdy[i] <= 1;
                        if (r1_rdy[i]) cur <= i;
                    end
                end
            end
            if (cdb2En_i) begin
                for (i = 1; i < `RSNum; i = i + 1) begin
                    if (!avail[i] && r1_id[i] == cdb2Id_i) begin
                        r1_data[i] <= cdb2Data_i;
                        r1_rdy[i] <= 1;
                        if (r2_rdy[i]) cur <= i;
                    end
                    if (!avail[i] && r2_id[i] == cdb2Id_i) begin
                        r2_data[i] <= cdb2Data_i; 
                        r2_rdy[i] <= 1;
                        if (r1_rdy[i]) cur <= i;
                    end
                end
            end
        end
    end

endmodule