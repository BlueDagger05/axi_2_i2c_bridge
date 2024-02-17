`define ADDR_WIDTH 32
`define DATA_WIDTH 32
`define RESPONSE_WIDTH 2
`define OUTPUT_ADDR_WIDTH 20
`define RDATA_WIDTH 8


interface axi_slave_if (input logic ACLK, ARESETn);
	
	////////////////////////////////
	// Write Request channel signals
	////////////////////////////////
	logic AWREADY;
	logic AWVALID;
	logic [`ADDR_WIDTH -1:0] AWADDR;

	/////////////////////////////
	// Write Data channel signals
	/////////////////////////////
	logic WREADY;
	logic WVALID;
	logic [`DATA_WIDTH -1:0] WDATA;

	/////////////////////////////////
	// Write Response channel signals
	/////////////////////////////////
	logic [`RESPONSE_WIDTH-1:0] BRESP;
	logic                       BVALID;
	logic                       BREADY;

    /////////////////////////////////
	// Read Address channel signals (AR)
	/////////////////////////////////
	logic ARREADY;
	logic  ARVALID;
	logic [`ADDR_WIDTH -1:0] ARADDR;
	
	/////////////////////////////////
	// Read Data channel signals (R)
	/////////////////////////////////
	logic [`RESPONSE_WIDTH -1:0] RRESP;
	logic [`RDATA_WIDTH -1:0] RDATA;
	logic  RVALID;
	logic  RREADY;
	
	clocking cb @(posedge ACLK);
		default input #1step output #3ns;  ////// read more
		input AWREADY;
		output AWVALID;
		output  AWADDR;

		input WREADY;
		output WVALID;
		output  WDATA;

	
		input  BRESP;
		input  BVALID;
		output BREADY;

   
		input ARREADY;
		output  ARVALID;
		output  ARADDR;
	
			
		input  RRESP;
		input  RDATA;
		input  RVALID;
		output  RREADY;
		endclocking
	

   

endinterface : axi_slave_if