`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.02.2024 00:46:09
// Design Name: 
// Module Name: top_axi_i2c
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "./define.sv"

module top_axi_i2c(
    
    //////////////////////////////////////////////
	// ++ Global clock and active-low reset ++ //
    /////////////////////////////////////////////
	input wire ACLK,
	input wire ARESETn,
	
	////////////////////////////////////////////
	// ++++++ Write channel signals +++++++ ///
	///////////////////////////////////////////
	// Write Address channel signals (AW)
	output logic AWREADY,
	input   wire AWVALID, 
	input   wire [`ADDR_WIDTH -1:0] AWADDR, //

	// Write Data channel signals (W)
	output logic WREADY,
	input   wire WVALID,
	input   wire [`DATA_WIDTH -1:0] WDATA,

	// Write Response channel signals
	output logic [`RESPONSE_WIDTH-1:0] BRESP,
	output logic                       BVALID,
	input   wire                       BREADY,

    ///////////////////////////////////////////
	// +++++++ Read channel signals +++++++ //
	//////////////////////////////////////////
	// Read Address channel signals (AR)
	output logic ARREADY,
	input  wire  ARVALID,
	input  wire [`ADDR_WIDTH -1:0] ARADDR,
	
	// Read Data channel signals (R)
	output logic [`RESPONSE_WIDTH -1:0] RRESP,
	output logic [`RDATA_WIDTH -1:0] RDATA,
	output logic RVALID,
	input  wire  RREADY
       
);
wire [7:0] wire_addr;
wire [7:0] wire_din;
wire [6:0] wire_slv_addr;
wire       wire_op_type;
wire       wire_I2C_trigger;

wire       wire_valid_addr_data_out;    
wire       wire_valid_data_ack;
wire       wire_valid_data_ack_valid;
    
wire       wire_rdata_out_valid;
wire       wire_RDATA_VALID_ACK; 
       
wire       wire_PENDING_WR;
wire       wire_PENDING_RD;

wire [7:0] wire_RDATA_OUT;
   
axi_slave u1(
             .ACLK(ACLK),
	         .ARESETn(ARESETn),
	         .ARVALID(ARVALID),
	         .AWVALID(AWVALID),
	         .AWADDR(AWADDR),
	         .AWREADY(AWREADY),
	         .WREADY(WREADY),
	         .WVALID(WVALID),
	         .WDATA(WDATA),
             .BRESP(BRESP),
	         .BVALID(BVALID),
	         .BREADY(BREADY),
	         .ARREADY(ARREADY),
	         .ARADDR(ARADDR),
             .RRESP(RRESP),
	         .RDATA(RDATA),
	         .RVALID(RVALID),
	         .RREADY(RREADY),
	         .ADDR_DATA_OUT({wire_addr, wire_din, wire_op_type, wire_slv_addr}),
	         .VALID_ADDR_DATA_OUT(wire_valid_addr_data_out),
             .VALID_ADDR_DATA_OUT_ACK(wire_valid_data_ack),
             .VALID_ADDR_DATA_OUT_ACK_VALID(wire_valid_data_ack_valid),
	         .RDATA_VALID_ACK(wire_RDATA_VALID_ACK),
             .I2C_MASTER_TRIGGER(wire_I2C_trigger),
 	         .RDATA_OUT(wire_RDATA_OUT),
	         .RDATA_VALID(wire_rdata_out_valid),
             .PENDING_TRANSACTION_WR(wire_PENDING_WR),
             .PENDING_TRANSACTION_RD(wire_PENDING_RD)
            );
            
top_i2c_master_slave u2(
                        .clk(ACLK),
                        .resetn(ARESETn),
                        .addr(wire_addr),
                        .din(wire_din),
                        .slv_addr(wire_slv_addr),
                        .op_type(wire_op_type),
                        .I2C_trigger(wire_I2C_trigger),
                        .valid_addr_data_out(wire_valid_addr_data_out),
                        .valid_data_ack(wire_valid_data_ack),
                        .valid_data_ack_valid(wire_valid_data_ack_valid),
                        .rdata_out(wire_RDATA_OUT),
                        .rdata_out_valid(wire_rdata_out_valid),
                        .rdata_out_valid_ack(wire_RDATA_VALID_ACK),
                        .PENDING_WR(wire_PENDING_WR),
                        .PENDING_RD(wire_PENDING_RD) 
                       );


endmodule
