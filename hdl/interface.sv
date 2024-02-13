/////////////////////////////////////////////////////////
// This interface consists of AXI master write channels
// AXI write have three sub-channels under write domain
// Write request, write data, write response respectively
/////////////////////////////////////////////////////////
`include "./defines.sv"

interface axi_wr_chnl;

	// Global clock and active-low reset
	bit ACLK;
	bit ARESETn;

	/////////////////////////////////
	// Write Request channel signals
	/////////////////////////////////
	logic AWVALID;
	logic AWREADY;
	logic [`ADDR_WIDTH -1:0] AWADDR;
	logic [`SIZE  -1:0] 	 AWSIZE;
	logic [`BURST_SIZE -1:0] AWBURST;


	/////////////////////////////////
	// Write Data channel signals
	/////////////////////////////////
	logic WVALID;
	logic WREADY;
	logic WLAST;
	logic [`WDATA_WIDTH -1:0] WADATA;


	/////////////////////////////////
	// Write Response channel signals
	/////////////////////////////////
	logic                       BVALID;
	logic                       BREADY;
	logic [`RESPONSE_WIDTH-1:0] BRESP;

	/////////////////////////////////
	// I2C signals
	/////////////////////////////////
	
	logic SDA;
	logic SCL;
endinterface : axi_wr_chnl