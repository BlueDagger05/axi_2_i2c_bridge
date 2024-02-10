`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.02.2024 20:32:47
// Design Name: 
// Module Name: read_pointer_empty
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


module read_pointer_empty
#(
  parameter ADDRSIZE = 4
)
(
input   logic rd_en, rd_clk, rrst_n,
input   logic [ADDRSIZE :0] rq2_wptr,
output logic rempty,
output logic [ADDRSIZE-1:0] rd_addr,
output logic [ADDRSIZE :0] rptr
);

logic [ADDRSIZE:0] rbin;
logic [ADDRSIZE:0] rgraynext, rbinnext;

//-------------------
// GRAYSTYLE2 pointer
//-------------------
always_ff @(posedge rd_clk or negedge rrst_n)
if (!rrst_n)
    begin
    {rbin, rptr} <= '0;
    end 
else
    begin
      {rbin, rptr} <= {rbinnext, rgraynext};
    end
    
// Memory read-address pointer (okay to use binary to address memory)
assign rd_addr = rbin[ADDRSIZE-1:0];
assign rbinnext = rbin + (rd_en & ~rempty);
assign rgraynext = (rbinnext>>1) ^ rbinnext;

//---------------------------------------------------------------
// FIFO empty when the next rptr == synchronized wptr or on reset
//---------------------------------------------------------------
assign rempty_val = (rgraynext == rq2_wptr);

always_ff @(posedge rd_clk or negedge rrst_n)
   if (!rrst_n)
     rempty <= 1'b1;
   else
     rempty <= rempty_val;
endmodule
