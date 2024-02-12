`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.02.2024 10:32:32
// Design Name: 
// Module Name: tb_axi_slave
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

module tb_axi_slave();
    ////////////////////////////////////
	// Global clock and active-low reset
    ////////////////////////////////////
	bit ACLK;
	bit ARESETn;

	////////////////////////////////
	// Write Request channel signals
	////////////////////////////////
	logic [`ADDR_WIDTH -1:0] AWADDROUT;
	logic AWREADY;
	logic AWVALID;
	logic [`ADDR_WIDTH -1:0] AWADDR;
	logic      [`SIZE  -1:0] AWSIZE;
	logic [`BURST_SIZE -1:0] AWBURST;


	/////////////////////////////
	// Write Data channel signals
	/////////////////////////////
	logic [`WDATA_WIDTH -1:0] WDATAOUT;
	logic WREADY;
	logic WVALID;
	logic WLAST;
	logic [`WDATA_WIDTH -1:0] WDATA;


	/////////////////////////////////
	// Write Response channel signals
	/////////////////////////////////
	logic [`RESPONSE_WIDTH-1:0] BRESP;
	logic                       BVALID;
	logic                       BREADY;
	
axi_write_channel_slave DUT (.*);
  always #10 ACLK = ~ACLK;
  
  initial begin
  #50 ARESETn = 1'b1;
  
   @(posedge ACLK) write_req_handshake();
//  @(posedge ACLK) write_data_handshake(); 
  // @(posedge ACLK) write_resp_handshake(); 
  end
  
  // tasks and functions
  task write_req_handshake();
         AWVALID = 1'b1;
         AWADDR  = 32'hABAB;
         AWBURST = 2'b00;
  endtask : write_req_handshake
  
  
  task write_data_handshake();
          WREADY = 1'b0;
     #100 WREADY = 1'b1;
  endtask : write_data_handshake
  
  task write_resp_handshake();
     #100 BRESP  = 2'b0;
          BVALID = 1'b1;
  endtask : write_resp_handshake
  
  initial #1000 $finish;	
endmodule
