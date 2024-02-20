`timescale 1ns / 1ps


module i2c_top( 
   // AXI signals
   (*mark_debug="true"*)input wire [23:0] addr_data_out,
   input wire valid_addr_data_out,
   
   input wire  I2C_trigger,
   
   output logic valid_data_ack,
   output logic valid_data_ack_valid,
   
   output logic [7:0] rdata_out,
   output logic       rdata_out_valid,
   
   output logic PENDING_WR,
   output logic PENDING_RD,
   
   // I2C signals
   input wire clk,
   input wire resetn
   
);



level_conversion UUT 
(
.clk(clk),
.resetn(resetn),
.addr_data_out(addr_data_out),
.valid_addr_data_out_i(valid_addr_data_out),
.I2C_trigger_i(I2C_trigger),
.valid_data_ack_o(valid_data_ack),
.valid_data_ack_valid_o(valid_data_ack_valid),
.rdata_out(rdata_out),
.rdata_out_valid_o(rdata_out_valid),
.PENDING_WR_o(PENDING_WR),
.PENDING_RD_o(PENDING_RD)
);



endmodule
