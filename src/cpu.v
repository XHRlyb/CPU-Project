`include "define.v"
/*`include "ctrl_mem.v"
`include "icache.v"
`include "IF.v"
`include "iqueue.v"
`include "ID.v"
`include "dispatch.v"
`include "LS_RS.v"
`include "LSbuffer.v"
`include "RS.v"
`include "ALU.v"
`include "regfile.v"
`include "ROB.v"
`include "CDB.v"*/
// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)


  wire clr_io;
  wire [`DataBus] clr_pc;
  
  wire ic_mc_en;
  wire [`InstAddrBus] ic_mc_addr;
  wire mc_ic_busy;
  wire mc_ic_rdy;
  wire [`InstBus] mc_ic_data;
  
  wire lsbuf_mc_en;
  wire lsbuf_mc_rw;
  wire [`DataWidBus] lsbuf_mc_wid;
  wire [`InstAddrBus] lsbuf_mc_addr;
  wire [`InstBus] lsbuf_mc_data;
  wire mc_lsbuf_rdy;
  wire [`DataBus] mc_lsbuf_data;

ctrl_mem mem_ctrl0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clr_i(clr_io),
    // request from Icache
    .ifEn_i(ic_mc_en),
    .ifAddr_i(ic_mc_addr),
    // response to ICache
    .ifBusy_o(mc_ic_busy),
    .ifRdy_o(mc_ic_rdy),
    .ifData_o(mc_ic_data),
    // request from LSBuffer
    .dataEn_i(lsbuf_mc_en),
    .dataRw_i(lsbuf_mc_rw),
    .dataWid_i(lsbuf_mc_wid),
    .dataAddr_i(lsbuf_mc_addr),
    .dataData_i(lsbuf_mc_data),
    // response to LSBuffer
    .dataRdy_o(mc_lsbuf_rdy),
    .dataData_o(mc_lsbuf_data),
    // interact with RAM
    .memRw_o(mem_wr),
    .memAddr_o(mem_a),
    .memData_o(mem_dout),
    .memData_i(mem_din)
);

  wire if_ic_rdy;
  wire [`MemAddrBus] if_ic_addr;
  wire ic_if_en;
  wire [`MemDataBus] ic_if_data;

icache icache0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    .clr_i(clr_io),
    // request to mem-ctrl
    .memEn_o(ic_mc_en),
    .memAddr_o(ic_mc_addr),
    // response from mem-ctrl
    .memBusy_i(mc_ic_busy),
    .memRdy_i(mc_ic_rdy),
    .memData_i(mc_ic_data),
    // request from IF
    .ifRdy_i(if_ic_rdy),
    .ifAddr_i(if_ic_addr),
    // response to IF
    .ifEn_o(ic_if_en),
    .ifData_o(ic_if_data)
);

  wire iq_if_full;
  wire if_iq_en;
  wire [`DataBus] if_iq_data;
  wire [`DataBus] if_iq_pc;
  
  wire dp_if_br_en;
  wire [`DataBus] dp_if_br_pc;

IF IF0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    // request to icache
    .icacheEn_o(if_ic_rdy),
    .icacheAddr_o(if_ic_addr),
    // response from icache
    .icacheRdy_i(ic_if_en),
    .icacheData_i(ic_if_data),
    // inform from iqueue
    .iqueueFull_i(iq_if_full),
    // inst add to iqueue
    .iqueueEn_o(if_iq_en),
    .iqueueData_o(if_iq_data),
    .iqueuePc_o(if_iq_pc),
    // from ROB-cleaner
    .newEn_i(clr_io),
    .newPc_i(clr_pc),
    // from dispatcher-pridict
    .BrPridEn_i(dp_if_br_en),
    .BrPridPc_i(dp_if_br_pc)
);

  wire iq_id_empty;
  wire [`DataBus] iq_id_data;
  wire [`DataBus] iq_id_pc;

iqueue iqueue0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clr_i(clr_io),
    // inform to IF
    .Full_o(iq_if_full),
    // request from IF
    .addEn_i(if_iq_en),
    .addData_i(if_iq_data),
    .addPc_i(if_iq_pc),
    // inform to ID
    .Empty_o(iq_id_empty),
    .fetchData_o(iq_id_data),
    .fetchPc_o(iq_id_pc)
);

  wire [`RegAddrBus] id_dp_r1;
  wire [`RegAddrBus] id_dp_r2;
  wire [`RegAddrBus] id_dp_rd;
  wire [`OpCodeBus] id_dp_opcode;
  wire [`MemAddrBus] id_dp_imm;
  wire [`DataBus] id_dp_pc;

ID ID0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    // fetched inst from iqueue
    .fetchEmpty_i(iq_id_empty),
    .fetchData_i(iq_id_data),
    .fetchPc_i(iq_id_pc),
    // decode-inst to dispatcher
    .r1Addr_o(id_dp_r1),
    .r2Addr_o(id_dp_r2),
    .rdAddr_o(id_dp_rd),
    .opCode_o(id_dp_opcode),
    .Imm_o(id_dp_imm),
    .Pc_o(id_dp_pc)
);

    wire dp_rf_en;
    wire [`ROBAddrBus] dp_rf_id;
    wire [`RegAddrBus] dp_rf_rd;
    wire dp_rf_r1_en;
    wire [`RegAddrBus] dp_rf_r1;
    wire dp_rf_r2_en;
    wire [`RegAddrBus] dp_rf_r2;
    wire rf_dp_r1_rdy;
    wire [`ROBAddrBus] rf_dp_r1_id;
    wire [`DataBus] rf_dp_r1_data;
    wire rf_dp_r2_rdy;
    wire [`ROBAddrBus] rf_dp_r2_id;
    wire [`DataBus] rf_dp_r2_data;

    wire lsrs_full;
    wire dp_lsrs_en;
    wire [`OpCodeBus] dp_lsrs_op;
    wire [`DataBus] dp_lsrs_imm;
    wire [`DataBus] dp_lsrs_r1_data;
    wire [`DataBus] dp_lsrs_r2_data;
    wire [`ROBAddrBus] dp_lsrs_r1_id;
    wire [`ROBAddrBus] dp_lsrs_r2_id;
    wire [`ROBAddrBus] dp_lsrs_id;
    
    wire rs_full;
    wire dp_rs_en;
    wire [`OpCodeBus] dp_rs_op;
    wire [`DataBus] dp_rs_pc;
    wire [`DataBus] dp_rs_imm;
    wire [`DataBus] dp_rs_r1_data;
    wire [`DataBus] dp_rs_r2_data;
    wire [`ROBAddrBus] dp_rs_r1_id;
    wire [`ROBAddrBus] dp_rs_r2_id;
    wire [`ROBAddrBus] dp_rs_id;

    wire [`ROBAddrBus] rob_dp_id;
    wire dp_rob_en;
    wire [`ROBAddrBus] dp_rob_id;
    wire [`RegAddrBus] dp_rob_rd;
    wire [`DataBus] dp_rob_pc;
    wire [1:0] dp_rob_br_tag;

    wire cdb_lsbuf_dp_en;
    wire [`ROBAddrBus] cdb_lsbuf_dp_id;
    wire [`DataBus] cdb_lsbuf_dp_data;
    wire cdb_alu_dp_en;
    wire [`ROBAddrBus] cdb_alu_dp_id;
    wire [`DataBus] cdb_alu_dp_data;

dispatch dispatch0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    // decoded-inst from ID
    .r1Addr_i(id_dp_r1),
    .r2Addr_i(id_dp_r2),
    .rdAddr_i(id_dp_rd),
    .opCode_i(id_dp_opcode),
    .Pc_i(id_dp_pc),
    .Imm_i(id_dp_imm),
    // request(lock) to regfile
    .lockEn_o(dp_rf_en),
    .lockId_o(dp_rf_id),
    .lockAddr_o(dp_rf_rd),
    // request(data-query) to regfile
    .r1En_o(dp_rf_r1_en),
    .r1Addr_o(dp_rf_r1),
    .r2En_o(dp_rf_r2_en),
    .r2Addr_o(dp_rf_r2),
    // response(data-query) from regfile
    .r1Rdy_i(rf_dp_r1_rdy),
    .r1Id_i(rf_dp_r1_id),
    .r1Data_i(rf_dp_r1_data),
    .r2Rdy_i(rf_dp_r2_rdy),
    .r2Id_i(rf_dp_r2_id),
    .r2Data_i(rf_dp_r2_data),
    // request to LSRS
    .LSRSFull_i(lsrs_full),
    .LSRSEn_o(dp_lsrs_en),
    .LSRSOpcode_o(dp_lsrs_op),
    .LSRSImm_o(dp_lsrs_imm),
    .LSRSr1Data_o(dp_lsrs_r1_data),
    .LSRSr2Data_o(dp_lsrs_r2_data),
    .LSRSr1Id_o(dp_lsrs_r1_id),
    .LSRSr2Id_o(dp_lsrs_r2_id),
    .LSRSId_o(dp_lsrs_id),
    // request to RS
    .RSFull_i(rs_full),
    .RSEn_o(dp_rs_en),
    .RSOpcode_o(dp_rs_op),
    .RSPc_o(dp_rs_pc),
    .RSImm_o(dp_rs_imm),
    .RSr1Data_o(dp_rs_r1_data),
    .RSr2Data_o(dp_rs_r2_data),
    .RSr1Id_o(dp_rs_r1_id),
    .RSr2Id_o(dp_rs_r2_id),
    .RSId_o(dp_rs_id),
    // inform from ROB
    .ROBId_i(rob_dp_id),
    // request to ROB
    .ROBEn_o(dp_rob_en),
    .ROBId_o(dp_rob_id),
    .ROBRd_o(dp_rob_rd),
    .ROBPc_o(dp_rob_pc),
    .ROBBrTag_o(dp_rob_br_tag),
    // request to IF
    .BrPridEn_o(dp_if_br_en),
    .BrPridPc_o(dp_if_br_pc),
    // inform from CDB
    .cdb1En_i(cdb_lsbuf_dp_en),
    .cdb1Id_i(cdb_lsbuf_dp_id),
    .cdb1Data_i(cdb_lsbuf_dp_data),
    .cdb2En_i(cdb_alu_dp_en),
    .cdb2Id_i(cdb_alu_dp_id),
    .cdb2Data_i(cdb_alu_dp_data)
);
    
    wire lsbuf_full;
    
    wire lsrs_lsbuf_en;
    wire [`OpCodeBus] lsrs_lsbuf_op;
    wire [`DataBus] lsrs_lsbuf_addr;
    wire [`DataBus] lsrs_lsbuf_r2_data;
    wire [`ROBBus] lsrs_lsbuf_id;
    
    wire cdb_lsbuf_lsrs_en;
    wire [`ROBAddrBus] cdb_lsbuf_lsrs_id;
    wire [`DataBus] cdb_lsbuf_lsrs_data;
    wire cdb_alu_lsrs_en;
    wire [`ROBAddrBus] cdb_alu_lsrs_id;
    wire [`DataBus] cdb_alu_lsrs_data;

LS_RS LSRS0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clr_i(clr_io),
    //
    .Full_o(lsrs_full),
    // request(add-inst) from dispatcher
    .En_i(dp_lsrs_en),
    .Opcode_i(dp_lsrs_op),
    .Imm_i(dp_lsrs_imm),
    .r1Data_i(dp_lsrs_r1_data),
    .r2Data_i(dp_lsrs_r2_data),
    .r1Id_i(dp_lsrs_r1_id),
    .r2Id_i(dp_lsrs_r2_id),
    .Id_i(dp_lsrs_id),
    // inform form LSBuffer
    .LSBufFull_i(lsbuf_full),
    // request(add-inst) to LSBuffer
    .LSBufEn_o(lsrs_lsbuf_en),
    .LSBufOpcode_o(lsrs_lsbuf_op),
    .LSBufAddr_o(lsrs_lsbuf_addr),
    .LSBufr2Data_o(lsrs_lsbuf_r2_data),
    .LSBufId_o(lsrs_lsbuf_id),
    // fetch updated data from CDB
    .cdb1En_i(cdb_lsbuf_lsrs_en),
    .cdb1Id_i(cdb_lsbuf_lsrs_id),
    .cdb1Data_i(cdb_lsbuf_lsrs_data),
    .cdb2En_i(cdb_alu_lsrs_en),
    .cdb2Id_i(cdb_alu_lsrs_id),
    .cdb2Data_i(cdb_alu_lsrs_data)
);

    wire cdb_lsbuf_en;
    wire [`ROBAddrBus] cdb_lsbuf_id;
    wire [`DataBus] cdb_lsbuf_data;

LSbuffer LSBuf0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clr_i(clr_io),
    //
    .Full_o(lsbuf_full),
    .LSEn_i(lsrs_full), //???????
    // request(add-inst) from LSRS
    .En_i(lsrs_lsbuf_en),
    .Opcode_i(lsrs_lsbuf_op),
    .Addr_i(lsrs_lsbuf_addr),
    .r2Data_i(lsrs_lsbuf_r2_data),
    .Id_i(lsrs_lsbuf_id),
    // request to mem-ctrl
    .dataEn_o(lsbuf_mc_en),
    .dataRw_o(lsbuf_mc_rw),
    .dataWid_o(lsbuf_mc_wid),
    .dataAddr_o(lsbuf_mc_addr),
    .dataData_o(lsbuf_mc_data),
    // response from mem-ctrl
    .Rdy_i(mc_lsbuf_rdy),
    .dataData_i(mc_lsbuf_data),
    // inform to CBD (just for read)
    .cdbEn_o(cdb_lsbuf_en),
    .cdbId_o(cdb_lsbuf_id),
    .cdbData_o(cdb_lsbuf_data)
);

    wire rs_alu_en;
    wire [`OpCodeBus] rs_alu_op;
    wire [`DataBus] rs_alu_imm;
    wire [`DataBus] rs_alu_pc;
    wire [`DataBus] rs_alu_r1_data;
    wire [`DataBus] rs_alu_r2_data;
    wire [`ROBAddrBus] rs_alu_id;

    wire cdb_lsbuf_rs_en;
    wire [`ROBAddrBus] cdb_lsbuf_rs_id;
    wire [`DataBus] cdb_lsbuf_rs_data;
    wire cdb_alu_rs_en;
    wire [`ROBAddrBus] cdb_alu_rs_id;
    wire [`DataBus] cdb_alu_rs_data;

RS RS0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clr_i(clr_io),
    //
    .Full_o(rs_full),
    // request(add-inst) from dispatcher
    .En_i(dp_rs_en),
    .Opcode_i(dp_rs_op),
    .Pc_i(dp_rs_pc),
    .Imm_i(dp_rs_imm),
    .r1Data_i(dp_rs_r1_data),
    .r2Data_i(dp_rs_r2_data),
    .r1Id_i(dp_rs_r1_id),
    .r2Id_i(dp_rs_r2_id),
    .Id_i(dp_rs_id),
    // request(add-inst) to ALU
    .ALUEn_o(rs_alu_en),
    .ALUOpcode_o(rs_alu_op),
    .ALUImm_o(rs_alu_imm),
    .ALUPc_o(rs_alu_pc),
    .ALUr1Data_o(rs_alu_r1_data),
    .ALUr2Data_o(rs_alu_r2_data),
    .ALUId_o(rs_alu_id),
    // fetch updated data from CDB
    .cdb1En_i(cdb_lsbuf_rs_en),
    .cdb1Id_i(cdb_lsbuf_rs_id),
    .cdb1Data_i(cdb_lsbuf_rs_data),
    .cdb2En_i(cdb_alu_rs_en),
    .cdb2Id_i(cdb_alu_rs_id),
    .cdb2Data_i(cdb_alu_rs_data)
);

    wire cdb_alu_en;
    wire [`ROBAddrBus] cdb_alu_id;
    wire [`DataBus] cdb_alu_data;
    wire [`DataBus] cdb_alu_pc;
    wire cdb_alu_cond;

ALU ALU0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    // request(add-inst) from RS
    .En_i(rs_alu_en),
    .Opcode_i(rs_alu_op),
    .Imm_i(rs_alu_imm),
    .Pc_i(rs_alu_pc),
    .r1Data_i(rs_alu_r1_data),
    .r2Data_i(rs_alu_r2_data),
    .Id_i(rs_alu_id),
    // inform to CBD( then to RS & ROB)
    .cdbEn_o(cdb_alu_en),
    .cdbId_o(cdb_alu_id),
    .cdbData_o(cdb_alu_data),
    .cdbPc_o(cdb_alu_pc),
    .cdbCond_o(cdb_alu_cond)
);

    wire rob_rf_en;
    wire [`ROBAddrBus] rob_rf_id;
    wire [`RegAddrBus] rob_rf_rd;
    wire [`DataBus] rob_rf_data;

regfile regfile0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    // request from ROB
    .wEn_i(rob_rf_en),
    .wId_i(rob_rf_id),
    .wAddr_i(rob_rf_rd),
    .wData_i(rob_rf_data),
    // request(lock) from dispatcher
    .sEn_i(dp_rf_en),
    .sAddr_i(dp_rf_rd),
    .sId_i(dp_rf_id),
    // request from dispatcher
    .r1En_i(dp_rf_r1_en),
    .r1Addr_i(dp_rf_r1),
    .r2En_i(dp_rf_r2_en),
    .r2Addr_i(dp_rf_r2),    
    // response to dispather
    .r1Rdy_o(rf_dp_r1_rdy),
    .r1Id_o(rf_dp_r1_id),
    .r1Data_o(rf_dp_r1_data),
    .r2Rdy_o(rf_dp_r2_rdy),
    .r2Id_o(rf_dp_r2_id),
    .r2Data_o(rf_dp_r2_data)
);

    wire cdb_lsbuf_rob_en;
    wire [`ROBAddrBus] cdb_lsbuf_rob_id;
    wire [`DataBus] cdb_lsbuf_rob_data;
    wire cdb_alu_rob_en;
    wire [`ROBAddrBus] cdb_alu_rob_id;
    wire [`DataBus] cdb_alu_rob_data;
    wire [`DataBus] cdb_alu_rob_pc;
    wire cdb_alu_rob_cond;

ROB ROB0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .clr_i(clr_io),
    // inform to dispatcher
    .ROBId_o(rob_dp_id),
    // request(add inst) from dispatcher
    .addEn_i(dp_rob_en),
    .addId_i(dp_rob_id),
    .addRd_i(dp_rob_rd),
    .addPc_i(dp_rob_pc),
    .addBrTag_i(dp_rob_br_tag),
    // inform from CDB
    .cdb1En_i(cdb_lsbuf_rob_en),
    .cdb1Id_i(cdb_lsbuf_rob_id),
    .cdb1Data_i(cdb_lsbuf_rob_data),
    .cdb2En_i(cdb_alu_rob_en),
    .cdb2Id_i(cdb_alu_rob_id),
    .cdb2Data_i(cdb_alu_rob_data),
    .cdb2Pc_i(cdb_alu_rob_pc),
    .cdb2Cond_i(cdb_alu_rob_cond),
    // br_clr信号
    .clr_o(clr_io),
    .clrPc_o(clr_pc),
    // request to regfile
    .wEn_o(rob_rf_en),
    .wId_o(rob_rf_id),
    .wAddr_o(rob_rf_rd),
    .wData_o(rob_rf_data)
);

CDB CDB0(
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    // inform from LSBuffer
    .LSBufEn_i(cdb_lsbuf_en),
    .LSBufId_i(cdb_lsbuf_id),
    .LSBufData_i(cdb_lsbuf_data),
    // inform from ALU
    .ALUEn_i(cdb_alu_en),
    .ALUId_i(cdb_alu_id),
    .ALUData_i(cdb_alu_data),
    .ALUPc_i(cdb_alu_pc),
    .ALUCond_i(cdb_alu_cond),
    // infrom to LSRS
    .LSRScdb1En_o(cdb_lsbuf_lsrs_en),
    .LSRScdb1Id_o(cdb_lsbuf_lsrs_id),
    .LSRScdb1Data_o(cdb_lsbuf_lsrs_data),
    .LSRScdb2En_o(cdb_alu_lsrs_en),
    .LSRScdb2Id_o(cdb_alu_lsrs_id),
    .LSRScdb2Data_o(cdb_alu_lsrs_data),
    // infrom to RS
    .RScdb1En_o(cdb_lsbuf_rs_en),
    .RScdb1Id_o(cdb_lsbuf_rs_id),
    .RScdb1Data_o(cdb_lsbuf_rs_data),
    .RScdb2En_o(cdb_alu_rs_en),
    .RScdb2Id_o(cdb_alu_rs_id),
    .RScdb2Data_o(cdb_alu_rs_data),
    // infrom to DP
    .DPcdb1En_o(cdb_lsbuf_rs_en),
    .DPcdb1Id_o(cdb_lsbuf_rs_id),
    .DPcdb1Data_o(cdb_lsbuf_rs_data),
    .DPcdb2En_o(cdb_alu_rs_en),
    .DPcdb2Id_o(cdb_alu_rs_id),
    .DPcdb2Data_o(cdb_alu_rs_data),
    // inform to ROB
    .ROBcdb1En_o(cdb_lsbuf_rob_en),
    .ROBcdb1Id_o(cdb_lsbuf_rob_id),
    .ROBcdb1Data_o(cdb_lsbuf_rob_data),
    .ROBcdb2En_o(cdb_alu_rob_en),
    .ROBcdb2Id_o(cdb_alu_rob_id),
    .ROBcdb2Data_o(cdb_alu_rob_data),
    .ROBcdb2Pc_o(cdb_alu_rob_pc),
    .ROBcdb2Cond_o(cdb_alu_rob_cond)
);

always @(posedge clk_in) begin
  if (rst_in) begin
    
  end else if (!rdy_in) begin
    
  end else begin
    
  end
end

endmodule