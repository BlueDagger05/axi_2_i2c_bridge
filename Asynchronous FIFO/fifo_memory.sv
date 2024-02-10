`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.02.2024 17:07:11
// Design Name: 
// Module Name: fifo_memory
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


module fifo_memory #(
       parameter DATASIZE = 8,
       parameter ADDRSIZE = 4)
       (
       input logic wr_en,    // write enable
       input logic wr_full,  // write full 
       input logic wr_clk,   // clock write 
       input logic [ADDRSIZE-1:0] wr_addr, rd_addr,
       input logic [DATASIZE-1:0] wdata,
       output logic [DATASIZE-1:0] rdata
       );

// Declare FIFO memory using the calculated depth 
logic [DATASIZE-1:0] mem [(1<<ADDRSIZE)-1:0]; // Memory declaration with implicit depth

// Read data directly from the specified address
assign rdata = mem[rd_addr];

// Perform writes only when enabled and space is available
always_ff @(posedge wr_clk)
begin
    if (wr_en && !wr_full)
    begin
        mem[wr_addr] <= wdata;
    end
end
endmodule
