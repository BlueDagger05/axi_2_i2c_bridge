/////////////////////////////////////////////////////////
// This interface consists of AXI master write channels
// AXI write have three sub-channels under write domain
// Write request; write data; write response respectively
/////////////////////////////////////////////////////////
`include "./defines.sv"

interface axi_wr_chnl;

   ////////////////////////////////////
	// Global clock and active-low reset
    ////////////////////////////////////
	logic ACLK;
	logic ARESETn;

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
	logic ARVALID;
	logic [`ADDR_WIDTH -1:0] ARADDR;
	
	/////////////////////////////////
	// Read Data channel signals (R)
	/////////////////////////////////
	logic [`RDATA_WIDTH -1:0] RDATA;
	logic [`RESPONSE_WIDTH -1:0] RRESP;
	logic  RVALID;
	logic RREADY;
	
	/////////////////////////////////
	// I2C signals
	/////////////////////////////////
	
	logic SDA;
	logic SCL;
endinterface : axi_wr_chnl