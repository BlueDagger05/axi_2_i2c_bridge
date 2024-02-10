`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.02.2024 20:39:33
// Design Name: 
// Module Name: write_pointer_full
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


module write_pointer_full
#(
  parameter ADDRSIZE = 4
)
(
  input   logic wr_en, wr_clk, wrst_n,
  input  logic [ADDRSIZE :0] wq2_rptr,
  output logic   wr_full,
  output logic  [ADDRSIZE-1:0] wr_addr,
  output logic  [ADDRSIZE :0] wptr
);

   logic [ADDRSIZE:0] wbin;
   logic [ADDRSIZE:0] wgraynext, wbinnext;

  // GRAYSTYLE2 pointer
  always_ff @(posedge wr_clk or negedge wrst_n)
    if (!wrst_n)
      {wbin, wptr} <= '0;
    else
      {wbin, wptr} <= {wbinnext, wgraynext};

  // Memory write-address pointer (okay to use binary to address memory)
  assign wr_addr = wbin[ADDRSIZE-1:0];
  assign wbinnext = wbin + (wr_en & ~wr_full);
  assign wgraynext = (wbinnext>>1) ^ wbinnext;

 
  assign wr_full_val = (wgraynext=={~wq2_rptr[ADDRSIZE:ADDRSIZE-1], wq2_rptr[ADDRSIZE-2:0]});

  always_ff @(posedge wr_clk or negedge wrst_n)
    if (!wrst_n)
      wr_full <= 1'b0;
    else
      wr_full <= wr_full_val;

endmodule