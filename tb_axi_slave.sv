`timescale 1ns/1ps 
`include "axi_slave.sv"
`include "axi_interface.sv"
`include "uvm_macros.svh"
 import uvm_pkg ::*;
 
 `include "axi_packet.sv"
 `include "axi_sequencer.sv"
 `include "axi_driver.sv"
 `include "axi_monitor.sv"
 `include "axi_agent.sv"
 `include "scoreboard.sv"
 `include "env.sv"
 `include "axi_base_sequence.sv"
 `include "base_test.sv"
 
 
module tb_axi_slave();
/*
///////////////////////////////
// Global clock and actie low reset
///////////////////////////////
    logic ACLK;
    logic ARESETn;

////////////////////////////
// Write channel signals
////////////////////////////

// Write Request channel signals
    logic AWREADY;
    logic AWVALID;
    logic [`ADDR_WIDTH -1:0] AWADDR;
    
// Write Data channel signals
    logic WREADY;
    logic WVALID;
    logic [`DATA_WIDTH -1:0] WDATA;
   
// Write Response channel signals
    logic [`RESPONSE_WIDTH-1:0] BRESP;
    logic BVALID;
    logic BREADY;
    
/////////////////////////////////////
//// Read channel signals
////////////////////////////////////

// Read Address Channel Signals 
    logic [`ADDR_WIDTH -1:0] ARADDR;
    logic ARREADY;
    logic ARVALID;
    
// Read Data channel Signals (R)
    logic [`RESPONSE_WIDTH -1:0] RRESP;
    logic [`RDATA_WIDTH -1:0] RDATA;
    logic RVALID;
    logic RREADY;
*/
    
////////////////////////////////////
// AXI to I2C Master Write Signals
/////////////////////////////////// 

    logic [`OUTPUT_ADDR_WIDTH -1:0] ADDR_DATA_OUT;
    logic VALID_ADDR_DATA_OUT;
    logic VALID_ADDR_DATA_OUT_ACK;
    logic VALID_ADDR_DATA_OUT_ACK_VALID;

// AXI slave to I2C master Read signals
    logic RDATA_VALID_ACK;
    logic I2C_MASTER_TRIGGER;
    logic [`RDATA_WIDTH -1:0] RDATA_OUT;
    logic RDATA_VALID;
    logic PENDING_TRANSACTION_WR;
    logic PENDING_TRANSACTION_RD;

	bit clk;
	bit reset_n;


// Instantiate AXI slave
axi_slave_if axi_vif(clk,reset_n);
 

axi_slave DUT(
            .ACLK(clk),
            .ARESETn(reset_n),
            .AWREADY(axi_vif.AWREADY),
            .AWVALID(axi_vif.AWVALID),
            .AWADDR(axi_vif.AWADDR),
            .WREADY(axi_vif.WREADY),
            .WVALID(axi_vif.WVALID),
            .WDATA(axi_vif.WDATA),
            .BRESP(axi_vif.BRESP),
            .BVALID(axi_vif.BVALID),
            .BREADY(axi_vif.BREADY),
            .ARREADY(axi_vif.ARREADY),
            .ARVALID(axi_vif.ARVALID),
            .ARADDR(axi_vif.ARADDR),
            .RRESP(axi_vif.RRESP),
            .RDATA(axi_vif.RDATA),
            .RVALID(axi_vif.RVALID),
            .RREADY(axi_vif.RREADY),
			
			
			
            .ADDR_DATA_OUT(ADDR_DATA_OUT),
            .VALID_ADDR_DATA_OUT(VALID_ADDR_DATA_OUT),
            .VALID_ADDR_DATA_OUT_ACK(VALID_ADDR_DATA_OUT_ACK),
            .VALID_ADDR_DATA_OUT_ACK_VALID(VALID_ADDR_DATA_OUT_ACK_VALID),
            .RDATA_VALID_ACK(RDATA_VALID_ACK),
            .I2C_MASTER_TRIGGER(I2C_MASTER_TRIGGER),
            .RDATA_OUT(RDATA_OUT),
            .RDATA_VALID(RDATA_VALID),
            .PENDING_TRANSACTION_WR(PENDING_TRANSACTION_WR),
            .PENDING_TRANSACTION_RD(PENDING_TRANSACTION_RD)
);
// clock genration
always 
begin
   #5 clk = ~clk;    
end

initial
begin
	uvm_config_db #(virtual axi_slave_if)::set(null,"*", "KEY", axi_vif);
	run_test("base_test");
	
end
// Reset Generation
initial 
begin
    reset_n = 1'b0;
    #10;
    reset_n = 1'b1;
end


endmodule : tb_axi_slave