`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.02.2024 20:49:11
// Design Name: 
// Module Name: synchronizer_read_to_write
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

//
// Read pointer to write clock synchronizer
//
module synchronizer_read_to_write#(
  parameter ADDRSIZE = 4
)
(
  input  logic wr_clk, wrst_n,
  input  logic [ADDRSIZE:0] rptr,
  output logic [ADDRSIZE:0] wq2_rptr  //readpointer with write side
);

  logic [ADDRSIZE:0] wq1_rptr;

  always_ff @(posedge wr_clk or negedge wrst_n)
    if (!wrst_n) {wq2_rptr,wq1_rptr} <= 0;
    else {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};

endmodule