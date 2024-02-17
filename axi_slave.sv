`timescale 1ns/1ps
`include "./defines.sv"
 
module axi_slave(
	
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
	output logic ARREADY,
	input  wire  ARVALID,
	input  wire [`ADDR_WIDTH -1:0] ARADDR,
	
	/////////////////////////////////
	// Read Data channel signals (R)
	/////////////////////////////////
	output logic [`RESPONSE_WIDTH -1:0] RRESP,
	output logic [`RDATA_WIDTH -1:0] RDATA,
	output logic  RVALID,
	input  wire  RREADY,


    // AXI slave to I2C master Write signals
	output logic [`OUTPUT_ADDR_WIDTH -1:0] ADDR_DATA_OUT,
	output logic VALID_ADDR_DATA_OUT,
    input  wire  VALID_ADDR_DATA_OUT_ACK,
    input  wire  VALID_ADDR_DATA_OUT_ACK_VALID,

    // AXI slave to I2C master Read signals
	output logic RDATA_VALID_ACK,
	output logic I2C_MASTER_TRIGGER,

	input  wire [`RDATA_WIDTH -1:0] RDATA_OUT,
	input  wire RDATA_VALID,

	input wire PENDING_TRANSACTION_WR,
	input wire PENDING_TRANSACTION_RD
);
endmodule