`include "./defines.sv"

module top (

   ////////////////////////////////////
	// Global clock and active-low reset
    ////////////////////////////////////
	input wire ACLK,
	input wire ARESETn,

	////////////////////////////////
	// Write Request channel signals
	////////////////////////////////
	output logic AWREADY,
	input   wire AWVALID,
	input   wire [`ADDR_WIDTH -1:0] AWADDR,

	/////////////////////////////
	// Write Data channel signals
	/////////////////////////////
	output logic WREADY,
	input   wire WVALID,
	input   wire [`DATA_WIDTH -1:0] WDATA,

	/////////////////////////////////
	// Write Response channel signals
	/////////////////////////////////
	output logic [`RESPONSE_WIDTH-1:0] BRESP,
	output logic                       BVALID,
	input   wire                       BREADY,

    /////////////////////////////////
	// Read Address channel signals (AR)
	/////////////////////////////////
	output wire ARREADY,
	input  wire ARVALID,
	input  wire [`ADDR_WIDTH -1:0] ARADDR,
	
	/////////////////////////////////
	// Read Data channel signals (R)
	/////////////////////////////////
	output logic     [`RDATA_WIDTH -1:0] RDATA,
	output logic [`RESPONSE_WIDTH -1:0] RRESP,
	output  wire RVALID,
	input   wire RREADY,
	
	/////////////////////////////////
	// I2C signals
	/////////////////////////////////
	
	inout SDA,
	inout SCL
);
// internal wires
wire [`OUTPUT_ADDR_WIDTH -1:0] wire_addr_data_out;
wire wire_valid_addr_data_out;
wire wire_valid_addr_data_out_ack;
wire wire_valid_addr_data_out_ack_valid;
wire [`DATA_WIDTH -1:0] wire_rdata_out;
wire wire_rdata_valid;
wire wire_rdata_valid_ack;
wire wire_pending_transaction_rd;
wire wire_pending_transaction_wr;
wire wire_i2c_master_trigger;
// wire wire_sda;
// wire wire_scl;

axi_slave u0(
             .ACLK(ACLK), 
             .ARESETn(ARESETn),
             .AWREADY(AWREADY),
             .AWVALID(AWVALID),
             .AWADDR(AWADDR),
             .WREADY(WREADY),
             .WVALID(WVALID),
             .WDATA(WDATA),
             .BRESP(BRESP),
             .BVALID(BVALID),
             .BREADY(BREADY),
             .ARREADY(ARREADY),
             .ARVALID(ARVALID),
             .ARADDR(ARADDR),
             .RDATA(RDATA),
             .RVALID(RVALID),
             .RREADY(RREADY),
             .RRESP(RRESP),
             .I2C_MASTER_TRIGGER(wire_i2c_master_trigger),
             .ADDR_DATA_OUT(wire_addr_data_out),
             .VALID_ADDR_DATA_OUT(wire_valid_addr_data_out),
             .VALID_ADDR_DATA_OUT_ACK(wire_valid_addr_data_out_ack),
             .VALID_ADDR_DATA_OUT_ACK_VALID(wire_valid_addr_data_out_ack_valid),
             .RDATA_OUT(wire_rdata_out),
             .RDATA_VALID(wire_rdata_valid),
             .RDATA_VALID_ACK(wire_rdata_valid_ack),
             .PENDING_TRANSACTION_WR(wire_pending_transaction_wr),
             .PENDING_TRANSACTION_RD(wire_pending_transaction_rd)
);

i2c_master u1(
             .ACLK(ACLK),
             .ARESETn(ARESETn),
             .I2C_MASTER_TRIGGER(wire_i2c_master_trigger),
             .ADDR_DATA_OUT(wire_addr_data_out),
             .VALID_ADDR_DATA_OUT(wire_valid_addr_data_out),
             .VALID_ADDR_DATA_OUT_ACK(wire_valid_addr_data_out_ack),
             .VALID_ADDR_DATA_OUT_ACK_VALID(wire_valid_addr_data_out_ack_valid),
             .RDATA_OUT(wire_rdata_out),
             .RDATA_VALID(wire_rdata_valid),
             .RDATA_VALID_ACK(wire_rdata_valid_ack),
             .PENDING_TRANSACTION_WR(wire_pending_transaction_wr),
             .PENDING_TRANSACTION_RD(wire_pending_transaction_rd),
             .SDA(SDA),
             .SCL(SCL)
);


endmodule : top