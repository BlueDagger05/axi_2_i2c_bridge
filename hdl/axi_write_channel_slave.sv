// fixed parameters considered in this design
// default value of burst = 4 beats (therefore unconnected AWSIZE pin)
// Additional output pins, defying standard for slave (AWADDROUT, WDATAOUT)
// used memory model to store AWADRR and AWDATA 
// (reg [31:0] Data_Store [7:0], reg [31:0] Control_Store [7:0]) 

`include "./defines.sv"

`ifndef WR_CHNL
`define WR_CHNL

typedef enum bit {LOW, HIGH} e_bool;
typedef enum bit [1:0] {OKAY, EXOKAY, SLVERR, DECERR} e_resp;

module axi_write_channel_slave(

    ////////////////////////////////////
	// Global clock and active-low reset
    ////////////////////////////////////
	input wire ACLK,
	input wire ARESETn,

	////////////////////////////////
	// Write Request channel signals
	////////////////////////////////
	output logic [`ADDR_WIDTH -1:0] AWADDROUT,
	output logic AWREADY,
	input   wire AWVALID,
	input   wire [`ADDR_WIDTH -1:0] AWADDR,
	input   wire      [`SIZE  -1:0] AWSIZE,
	input   wire [`BURST_SIZE -1:0] AWBURST,


	/////////////////////////////
	// Write Data channel signals
	/////////////////////////////
	output logic [`WDATA_WIDTH -1:0] WDATAOUT,
	output logic WREADY,
	input   wire WVALID,
	input   wire WLAST,
	input   wire [`WDATA_WIDTH -1:0] WDATA,


	/////////////////////////////////
	// Write Response channel signals
	/////////////////////////////////
	output logic [`RESPONSE_WIDTH-1:0] BRESP,
	output logic                       BVALID,
	input   wire                       BREADY
);

// temporary variables
reg resetOut;

// stores the Contents from axi-req channel
reg [31:0] Control_Store [7:0];
reg [7:0]  Control_Count;

// stores the Contents from axi-data channel
reg [31:0] Data_Store [7:0];
reg [7:0]  Data_Count;
reg [31:0] aligned_addr;
// state registers
reg [3:0] present_state, next_state;

// state variables
localparam IDLE       = 4'b0001;
localparam WRITE_REQ  = 4'b0010;
localparam WRITE_DATA = 4'b0100;
localparam WRITE_RESP = 4'b1000;

// sync_reset
reg SYN_ARESETn;

int loop_var;

// reset synchronizer
always_ff @(posedge ACLK, negedge ARESETn)
begin : syn_reset_proc
	if(~ARESETn)
	begin
		{resetOut, SYN_ARESETn} <= 2'b0;
	end

	else
	begin
		{SYN_ARESETn, resetOut} <= {resetOut, 1'b1};
		
	end
	
end : syn_reset_proc


// state regsiter
always_ff @(posedge ACLK or negedge SYN_ARESETn)
begin : state_register_proc
	if(~SYN_ARESETn)
	begin
		present_state <= IDLE;
		{AWREADY, WREADY, BVALID} <= 3'b0;
	end

	else 
	begin
		present_state <= next_state;
	end
end : state_register_proc



// next state logic
always_comb
begin : next_state_logic

case(present_state)
	IDLE:
	begin
		if(~SYN_ARESETn)
			next_state = IDLE;

		else if(AWVALID)
			next_state = WRITE_REQ;

		else if(WVALID)
			next_state = WRITE_DATA;

		else if(AWVALID && WVALID && WLAST)
			next_state = WRITE_RESP;
			
		else
		    next_state = IDLE;
		    
	end

	WRITE_DATA:
	begin
		if(WVALID)
			next_state = WRITE_DATA;

		else 
			next_state = IDLE;

	end

	WRITE_REQ:
	begin
        if(AWVALID)
			next_state = WRITE_REQ;

		else 
			next_state = IDLE;
	end

	WRITE_RESP:
	begin
		if(AWVALID & WVALID & BREADY & WLAST)
			next_state = WRITE_RESP;

		else 
			next_state = IDLE;
	end
	
	default:
	next_state = IDLE;

endcase	
end : next_state_logic



// output logic
always_comb
begin
case(present_state)
	IDLE:
	begin
		// when in idle, de-assert READY and 
		AWREADY = 0;
		WREADY  = 0;
		BVALID  = 0;

		Control_Count = 0;
		Data_Count = 0;
	end

    WRITE_REQ:
	begin
		// for storing control and data asserting AWREADY as HIGH
		AWREADY = HIGH;
		
		
		loop_var = AWSIZE;


		// storing control/address if AWVALID is HIGH
		if(AWVALID)
		begin
			// fixed burst, writing in the same location
			if(AWBURST == 2'b00)
			   Control_Store[0] = AWADDR;

			else if(AWBURST == 2'b01)
			begin
			// aligned_addr = $ceil(AWADDR/8);
			     // storing data at subsequent location, in a single burst (fixed the value to 4 bursts) 
			     for(int i = 0; i<5; i= i+1)
			     begin
			     	Control_Store[Control_Count+i] = AWADDR;
			     	
			     	// incrementing the count, Incremental burst 
			     	Control_Count = Control_Count + 1'b1;
			     end
			end
			
			else 
			begin
			     Control_Store[Control_Count] = 0;
			     Control_Count = Control_Count;
			end
			
			// temporary logic
			AWADDROUT = AWADDR;

		end

		else
		begin

			// holding the counter value
			Control_Count = Control_Count;


			// throws last stored data
			AWADDROUT = Control_Store[Control_Count];
		end

	end


	WRITE_DATA:
	begin
		// for storing data asserting WREADY as HIGH when WLAST not asserted
		if(WLAST)
			WREADY = LOW;
		else 
			WREADY = HIGH;

		// storing wdata if WVALID is HIGH
		if(WVALID)
		begin
			// Storing WDATA
			Data_Store[Data_Count] = WDATA;

			// Incrementing the count
			Data_Count = Data_Count + 1'b1;
		end

		else
		begin
			// holding the previous value of Data_Count
			Data_Count = Data_Count;

			// throws last stored data
			WDATAOUT = Data_Store[Data_Count];
		end
	end


	WRITE_RESP:
	begin
		if(WLAST == HIGH )
		begin
			// all data okay
			BRESP  = OKAY;
			BVALID = HIGH;
		end

		else 
		begin
			BRESP  = EXOKAY;
			BVALID = LOW;
		end
		
	end

	default:
	begin
		AWREADY = LOW;
		WREADY  = LOW;
		BVALID  = LOW;

		Data_Count    = 0;
		Control_Count = 0;
	end
	
endcase 
end

endmodule : axi_write_channel_slave
`endif