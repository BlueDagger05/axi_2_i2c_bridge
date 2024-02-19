`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.02.2024 02:00:24
// Design Name: 
// Module Name: tb_i2c_master
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


module tb_i2c_master();
 logic [23:0] addr_data_out;
 logic valid_addr_data_out;
   
   logic valid_data_ack;
   logic valid_data_ack_valid;
   
   logic I2C_trigger;
   
 logic [7:0] rdata_out;
logic       rdata_out_valid;
logic PENDING_WR;
 logic PENDING_RD;
   
// I2C signals
   bit clk;
   bit resetn;
   
   logic m_sda_i;
   logic m_sda_o;
   
   // To I2C slave
   logic scl_o;
   logic busy;
   logic ack_err;
   logic done;
   
   i2c_master DUT (.*);
   
   initial 
   begin
     #100 resetn = 1;
          valid_addr_data_out = 1;
     forever #5 clk = ~clk;
   end
   
   initial #2000 I2C_trigger = 1;
   initial begin
//     addr_data_out = 24'b111010_10111100_01011101; // 3A_BC_05D
       addr_data_out = 24'b111010_10111100_11011101; // 3A_BC_5E
     
   @(negedge busy)
   repeat(5) @(posedge clk);
   
   
   end
   
   
endmodule
