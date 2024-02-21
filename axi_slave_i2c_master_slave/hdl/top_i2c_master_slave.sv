`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.02.2024 09:09:34
// Design Name: 
// Module Name: dummy_top
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

module top_i2c_master_slave(
input clk, resetn, 
input [7:0] addr,
input [7:0] din,
input [6:0] slv_addr,
input op_type,
input I2C_trigger,

input  valid_addr_data_out,
output logic valid_data_ack,
output logic valid_data_ack_valid,

output logic [7:0] rdata_out,
output logic       rdata_out_valid,
input  logic       rdata_out_valid_ack,
   
output logic PENDING_WR,
output logic PENDING_RD   
);

wire sda, scl;
wire m_sda_o, s_sda_o;


i2c_master master(
    // Global Signals 
    .clk(clk),
    .resetn(resetn),
    
    // From AXI
    .I2C_trigger(I2C_trigger),
    .addr_data_out({din, addr, op_type, slv_addr}),
    .valid_data_ack(valid_data_ack),
    .valid_data_ack_valid(valid_data_ack_valid),
    .valid_addr_data_out(valid_addr_data_out),
    
    // Towards AXI
    .rdata_out(rdata_out),
    .rdata_out_valid(rdata_out_valid),  
    .rdata_out_valid_ack(rdata_out_valid_ack),
    .PENDING_WR(PENDING_WR),
    .PENDING_RD(PENDING_RD),
       
       
    // From I2C Slave 
    .m_sda_i(s_sda_o),
    
    
    // Towards I2C slave
    .scl_o(scl),
    .m_sda_o(s_sda_i)
);



i2c_slave i2c_inst(
  .SCL(scl),
  .SDA_i(s_sda_i),
  .SDA_o(s_sda_o),
  .RST(~resetn)
);

assign s_sda_i = m_sda_o & s_sda_o;

endmodule : top_i2c_master_slave