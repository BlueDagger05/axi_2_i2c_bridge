`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.02.2024 20:54:50
// Design Name: 
// Module Name: asynchronous_fifo
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


module asynchronous_fifo#(
  parameter DATASIZE = 8,
  parameter ADDRSIZE = 4
)
(
  input  logic wr_en, wr_clk, wrst_n,//wr_en write enable signal
  input  logic rd_en, rd_clk, rrst_n,//rd_en read enable signal
  input  logic [DATASIZE-1:0] wdata,

  output logic  [DATASIZE-1:0] rdata,
  output logic wr_full,
  output logic rempty
);

logic [ADDRSIZE-1:0] wr_addr, rd_addr;
logic [ADDRSIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;
 
synchronizer_read_to_write  sy_r2w(.wr_clk(wr_clk),.wrst_n(wrst_n),.rptr(rptr),.wq2_rptr(wq2_rptr));
synchronizer_write_to_read sy_w2r(.rd_clk(rd_clk),.rrst_n(rrst_n),.wptr(wptr),.rq2_wptr(rq2_wptr));
fifo_memory fifo_mem(.wr_en(wr_en),.wr_clk(wr_clk),.wr_full(wr_full),.wdata(wdata),.rdata(rdata),.wr_addr(wr_addr),.rd_addr(rd_addr));
read_pointer_empty DUT(.rd_en(rd_en),.rd_clk(rd_clk),.rrst_n(rrst_n),.rq2_wptr(rq2_wptr),.rd_addr(rd_addr),.rptr(rptr),.rempty(rempty));
write_pointer_full DUT1(.wr_en(wr_en),.wr_clk(wr_clk),.wrst_n(wrst_n),.wq2_rptr(wq2_rptr),.wr_addr(wr_addr),.wptr(wptr),.wr_full(wr_full));
 
endmodule