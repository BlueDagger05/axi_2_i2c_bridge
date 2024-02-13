`timescale 1ns/1ps

`include "./defines.sv"
`ifndef I2C
`define I2C
module i2c_master (
    input wire ACLK,
    input wire ARESETn,
	output logic  VALID_ADDR_DATA_OUT_ACK,
	output logic  VALID_ADDR_DATA_OUT_ACK_VALID,
	input   wire [`OUTPUT_ADDR_WIDTH -1:0] ADDR_DATA_OUT,
	input   wire VALID_ADDR_DATA_OUT,

    // AXI slave to I2C master Read signals
	output logic [`RDATA_WIDTH -1:0] RDATA_OUT,
	output logic RDATA_VALID,
	input   wire RDATA_VALID_ACK,

	output logic PENDING_TRANSACTION_WR,
	output logic PENDING_TRANSACTION_RD,
	
	inout logic SDA,
	inout logic SCL
);

endmodule : i2c_master
`endif