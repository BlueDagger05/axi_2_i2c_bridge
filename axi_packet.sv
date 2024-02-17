`define ADDR_WIDTH 32
`define DATA_WIDTH 32
`define RESPONSE_WIDTH 2
`define _ADDR_WIDTH 20
`define RDATA_WIDTH 8

class axi_pkt extends uvm_sequence_item;
  `uvm_object_utils(axi_pkt)  
    ////////////////////////////////////
	// Global clock and active-low reset
    ////////////////////////////////////
	//rand  bit ACLK,
	//rand  bit ARESETn,

	////////////////////////////////
	// Write Request channel signals
	////////////////////////////////
	bit AWREADY;
	rand  bit AWVALID;
	rand  bit [`ADDR_WIDTH -1:0] AWADDR;

	/////////////////////////////
	// Write Data channel signals
	/////////////////////////////
	bit WREADY;
	rand   bit WVALID;
	rand   bit [`DATA_WIDTH -1:0] WDATA;

	/////////////////////////////////
	// Write Response channel signals
	/////////////////////////////////
	logic [`RESPONSE_WIDTH-1:0] BRESP;
	logic                       BVALID;
	rand   bit                   BREADY;

    /////////////////////////////////
	// Read Address channel signals (AR)
	/////////////////////////////////
	logic ARREADY;
	rand  bit  ARVALID;
	rand  bit [`ADDR_WIDTH -1:0] ARADDR;
	
	/////////////////////////////////
	// Read Data channel signals (R)
	/////////////////////////////////
	logic [`RESPONSE_WIDTH -1:0] RRESP;
	logic [`RDATA_WIDTH -1:0] RDATA;
	logic  RVALID;
	rand  bit  RREADY;

    /////////////////////////////////////////////////
    // CTOR and registering 
    // it to the factory
    /////////////////////////////////////////////////

function new(string name = "axi_pkt");
    super.new(name);

endfunction : new

endclass : axi_pkt
