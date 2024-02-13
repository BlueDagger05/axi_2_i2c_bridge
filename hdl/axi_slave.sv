`timescale 1ns/1ps
`include "./defines.sv"
`ifndef AXI_MASTER
`define AXI_MASTER

typedef enum bit [1:0] {OKAY, EXOKAY, SLVERR, DECERR} e_resp;
typedef enum bit {LOW, HIGH} e_bool;

module axi_slave (
	////////////////////////////////////
	// Global clock and active-low reset
    ////////////////////////////////////
	input wire ACLK,
	input wire ARESETn,

	////////////////////////////////
	// Write Request channel signals
	////////////////////////////////
	output logic AWREADY,
	input   wire AWVALID,
	input   wire [`ADDR_WIDTH -1:0] AWADDR,

	/////////////////////////////
	// Write Data channel signals
	/////////////////////////////
	output logic WREADY,
	input   wire WVALID,
	input   wire [`DATA_WIDTH -1:0] WDATA,

	/////////////////////////////////
	// Write Response channel signals
	/////////////////////////////////
	output logic [`RESPONSE_WIDTH-1:0] BRESP,
	output logic                       BVALID,
	input   wire                       BREADY,

    /////////////////////////////////
	// Read Address channel signals (AR)
	/////////////////////////////////
	output logic ARREADY,
	input  wire  ARVALID,
	input  wire [`ADDR_WIDTH -1:0] ARADDR,
	
	/////////////////////////////////
	// Read Data channel signals (R)
	/////////////////////////////////
	output logic [`RESPONSE_WIDTH -1:0] RRESP,
	output logic [`RDATA_WIDTH -1:0] RDATA,
	output wire  RVALID,
	input  wire  RREADY,


    // AXI slave to I2C master Write signals
	output logic [`OUTPUT_ADDR_WIDTH -1:0] ADDR_DATA_OUT,
	output logic VALID_ADDR_DATA_OUT,
    input  wire  VALID_ADDR_DATA_OUT_ACK,
    input  wire  VALID_ADDR_DATA_OUT_ACK_VALID,

    // AXI slave to I2C master Read signals
	output logic RDATA_VALID_ACK,
	output logic I2C_MASTER_TRIGGER,

	input  wire [`RDATA_WIDTH -1:0] RDATA_OUT,
	input  wire RDATA_VALID,

	input wire PENDING_TRANSACTION_WR,
	input wire PENDING_TRANSACTION_RD
);
//////////////////////////////////
// temporary variables
//////////////////////////////////


// state variables
reg [4:0] next_state, present_state;

// synchronous reset 
reg SYN_RESET;
reg resetOut;


// memory variables
reg [`ADDR_WIDTH -1:0] temp_addr;
reg [`DATA_WIDTH -1:0] temp_data_out;
reg [`DATA_WIDTH -1:0] temp_data; 
reg [`DATA_WIDTH -1:0] write_memory [255:0];
reg memory_out;


// registered outputs
// write_req signals
reg temp_AWVALID;
reg temp_AWREADY;
reg [`ADDR_WIDTH -1:0] temp_AWADDR;


// write_data signals
reg temp_WVALID;
reg temp_WREADY;


// write_resp signals
reg [`RESPONSE_WIDTH-1:0] temp_BRESP;
reg temp_BVALID;
reg temp_BREADY;

// I2C temporary signals
reg [`DATA_WIDTH -1:0] temp_ADDR_DATA_OUT;
reg temp_VALID_ADDR_DATA_OUT;
reg temp_RDATA_VALID_ACK;
reg temp_I2C_MASTER_TRIGGER;
////////////////////////////////////


// write state registers
localparam WR_IDLE           = 5'b00001;
localparam WR_I2C_HANDSHAKE  = 5'b00010;
localparam WR_ADDRESS_PHASE  = 5'b00100;
localparam WR_DATA_PHASE     = 5'b01000;
localparam WR_RESPONSE_PHASE = 5'b10000;

// Device_ID variable
localparam DEVICE_ID = 15'hABCD;

// reset synchronizer
always_ff @(posedge ACLK, negedge ARESETn)
begin
	if(~ARESETn)
		{SYN_RESET, resetOut} <= 1'b0;
	else
		{SYN_RESET, resetOut} <= {resetOut, 1'b1};
end


// /////////////////////////////////////////////////////
// Write Operation
////////////////////////////////////////////////////////

// next state register
always_ff @(posedge ACLK, negedge SYN_RESET)
begin
	if(~SYN_RESET)
		present_state <= WR_IDLE;
	else
		present_state <= next_state;
end

// state register
always_comb
begin
	case(present_state)
		WR_IDLE:
		begin
			if(~SYN_RESET)
				next_state = WR_IDLE;

			else 
				next_state = WR_I2C_HANDSHAKE;

		end

		WR_I2C_HANDSHAKE:
		begin
			if(temp_AWVALID)
				next_state = WR_ADDRESS_PHASE;

			else
				next_state = WR_IDLE;
		end

		WR_ADDRESS_PHASE:
		begin
			if(temp_WVALID)
				next_state = WR_DATA_PHASE;
			else if(temp_AWVALID)
				next_state = WR_ADDRESS_PHASE;
			else
				next_state = WR_IDLE;
		end

		WR_DATA_PHASE:
		begin
			if(temp_WVALID)
				next_state = WR_DATA_PHASE;

			else if(VALID_ADDR_DATA_OUT_ACK && VALID_ADDR_DATA_OUT_ACK_VALID)
				next_state = WR_RESPONSE_PHASE;

			else 
				next_state = WR_IDLE;
			
		end

		WR_RESPONSE_PHASE:
		begin
			if(PENDING_TRANSACTION_WR)
				next_state = WR_RESPONSE_PHASE;
			else
				next_state = WR_IDLE;
		end
		
		default:
		begin
		     next_state = WR_IDLE;
		end

	endcase // next_state

end

// output logic
always_comb
begin
	case(present_state)
		WR_IDLE:
		begin
			{temp_AWREADY, temp_WREADY, temp_BVALID, temp_VALID_ADDR_DATA_OUT, temp_I2C_MASTER_TRIGGER} = 5'b0;
		end

		WR_I2C_HANDSHAKE:
		begin
			temp_I2C_MASTER_TRIGGER = 1;
		end

		WR_ADDRESS_PHASE:
		begin
			if(temp_AWVALID)
			begin
				temp_AWREADY = 1'b1;
//			    temp_AWADDR <= AWADDR;
			end

			else
				temp_AWREADY = 1'b0;

		end

		WR_DATA_PHASE:
		begin
			if(temp_WVALID)
			begin
				temp_WREADY = 1'b1;

				if(temp_AWADDR[31:16] == 15'h1234)
				begin
				     memory_out = 1;
				     {temp_ADDR_DATA_OUT[19:16], temp_ADDR_DATA_OUT[15:8], temp_ADDR_DATA_OUT[7:0]} = {DEVICE_ID, {1,temp_AWADDR[6:0]}, temp_data};
				     temp_VALID_ADDR_DATA_OUT = HIGH;
			    end

			   else
			   begin
			   	    {temp_ADDR_DATA_OUT[19:16], temp_ADDR_DATA_OUT[15:8], temp_ADDR_DATA_OUT[7:0]} = {DEVICE_ID, {1,temp_AWADDR[6:0]}, temp_data};
			   	    temp_VALID_ADDR_DATA_OUT = LOW;
			   end
			end
			
		end

		WR_RESPONSE_PHASE:
		begin
			if(PENDING_TRANSACTION_WR && temp_BREADY)
			begin
				temp_BRESP  = DECERR;
			    temp_BVALID = HIGH;
			end

			else if (!PENDING_TRANSACTION_WR && temp_BREADY)
			begin
				temp_BRESP  = OKAY;
				temp_BVALID = HIGH;
			end

			else begin
				temp_BVALID = LOW;
			end
		end
		
		default:
		begin
		    {temp_AWREADY, temp_WREADY, temp_BVALID, temp_VALID_ADDR_DATA_OUT, temp_I2C_MASTER_TRIGGER} = 5'b0;
		end
	endcase // next_state
end

always_ff @(posedge ACLK, negedge SYN_RESET)
begin

// write operation
    if(~SYN_RESET)
    begin
        write_memory [temp_AWADDR] <= 8'b0000_0000;
    end
    
        
    else if(WVALID)
         write_memory[temp_addr] <= WDATA;    
end

// read operation
always_ff @(posedge ACLK, negedge SYN_RESET)
begin
    if(~SYN_RESET)
        temp_data <= 8'b0000_0000;
        
    else if(memory_out)
        temp_data <= write_memory[temp_addr];    
end

/////////////////////////////
// continuous assignment
/////////////////////////////
always_ff @(posedge ACLK or negedge SYN_RESET)
begin
	if(~SYN_RESET)
	begin
		 // registered inputs
         temp_AWVALID <= 0;
         temp_WVALID  <= 0;
         temp_AWADDR <= 0;
         temp_BREADY <= 0;

        // registered outputs
         AWREADY <= 0;
         WREADY  <= 0;
        
         BRESP   <= 0;
         BVALID  <= 0;

         ADDR_DATA_OUT       <= 0;
         VALID_ADDR_DATA_OUT <= 0;
         I2C_MASTER_TRIGGER  <= 0;
	end

	else
	begin
		// registered inputs
		 temp_AWVALID <= AWVALID;
         temp_WVALID  <= WVALID;
         temp_BREADY <= BREADY;
         temp_AWADDR <= AWADDR;

         // registererd outputs
         AWREADY <= temp_AWREADY;
         WREADY  <= temp_WREADY;

         BRESP   <= temp_BRESP;
         BVALID  <= temp_BVALID;

         ADDR_DATA_OUT       <= temp_ADDR_DATA_OUT;
         VALID_ADDR_DATA_OUT <= temp_VALID_ADDR_DATA_OUT;
         I2C_MASTER_TRIGGER  <= temp_I2C_MASTER_TRIGGER;

	end

end

/////////////////////////////////////////////////////
// Read Operation
/////////////////////////////////////////////////////

//////////////////////////////////
// temporary variables for read channel
//////////////////////////////////

// state variables
reg [4:0] RD_next_state, RD_present_state;

// registered outputs read_req signals
reg temp_ARVALID;
reg temp_ARREADY;
reg [`ADDR_WIDTH -1:0] temp_ARADDR;


// read_data signals
reg temp_RVALID;
reg temp_RREADY;
reg [`RESPONSE_WIDTH -1:0] temp_RRESP;


// temp AXI slave to I2C master Read signals
reg temp_RDATA_VALID_ACK;
reg [`RDATA_WIDTH -1:0] temp_RDATA_OUT;
reg temp_RDATA_VALID;
reg temp_RDATA_VALID_ACK;
reg temp_PENDING_TRANSACTION_RD;
reg [`RESPONSE_WIDTH -1:0] temp_RRESP;

// for read channel memory signals
reg memory_out_rd;
reg [`DATA_WIDTH -1:0] temp_data_rd;
reg [`DATA_WIDTH-1:0] temp_RDATA;
reg [`DATA_WIDTH -1:0] rd_memory [255:0];

// write state registers
localparam RD_IDLE           = 4'b0001;
localparam RD_I2C_HANDSHAKE  = 4'b0010;
localparam RD_ADDRESS_PHASE  = 4'b0100;
localparam RD_DATA_PHASE     = 4'b1000;


// read next state register
always_ff @(posedge ACLK, negedge SYN_RESET)
begin
	if(~SYN_RESET)
		RD_present_state <= RD_IDLE;
	else
		RD_present_state <= RD_next_state;
end

// Read State Machine 
always_comb
begin
	case(RD_present_state)
		RD_IDLE:
		begin
			if(~SYN_RESET)
				RD_next_state = RD_IDLE;

			else 
				RD_next_state = RD_I2C_HANDSHAKE;
		end


		RD_I2C_HANDSHAKE:
		begin
			if(temp_ARVALID)
				RD_next_state = RD_ADDRESS_PHASE;

			else
				RD_next_state = RD_IDLE;
		end

		RD_ADDRESS_PHASE:
		begin
			if(temp_ARVALID)
				RD_next_state = RD_ADDRESS_PHASE;

			else if(temp_RVALID)
				RD_next_state = RD_DATA_PHASE;

			else 
				RD_next_state = RD_IDLE;
		end

		RD_DATA_PHASE:
		begin
			if(temp_PENDING_TRANSACTION_RD && temp_RVALID)
				RD_next_state = RD_DATA_PHASE;
			
			else 
				RD_next_state = RD_IDLE;
		end

		default:
		    RD_next_state = RD_IDLE;

	endcase
end

always_comb
begin
	case(RD_present_state)
		RD_IDLE:
		begin
			temp_ARREADY = 0;
			temp_RREADY  = 0;
			temp_RDATA_VALID_ACK = 0;
		end

		RD_I2C_HANDSHAKE:
		begin
			temp_I2C_MASTER_TRIGGER = HIGH;
		end

		RD_ADDRESS_PHASE:
		begin
			if(temp_ARVALID)
			begin
				temp_ARREADY = HIGH;
				{temp_ADDR_DATA_OUT[19:16], temp_ADDR_DATA_OUT[15:8], temp_ADDR_DATA_OUT[7:0]} = {DEVICE_ID, {0, temp_ARADDR[6:0]}, 2'h00};
                temp_VALID_ADDR_DATA_OUT = HIGH;
			end

			else
			begin
				temp_ARREADY = HIGH;
				{temp_ADDR_DATA_OUT[19:16], temp_ADDR_DATA_OUT[15:8], temp_ADDR_DATA_OUT[7:0]} = {DEVICE_ID, {0, temp_ARADDR[6:0]}, 8'b0000_0000};
				temp_VALID_ADDR_DATA_OUT = LOW;
			end
			
		end

		RD_DATA_PHASE:
		begin
			if(temp_RREADY && ~temp_PENDING_TRANSACTION_RD && temp_RDATA_VALID)
			begin
			    temp_RVALID    = HIGH;
				temp_RDATA_OUT = RDATA_OUT;
				temp_RRESP     = OKAY;
				temp_RDATA_VALID_ACK = HIGH;

				// enables read from read memory
				memory_out_rd = HIGH;
			end
			
			else 
			begin
			    temp_RVALID    = HIGH;
				temp_RRESP     = DECERR;
				temp_RDATA_VALID_ACK = LOW;
			end
		end

        default:
        begin
			temp_RREADY  = 0;
			temp_RDATA_VALID_ACK = 0;
        end

	endcase

end

// Memory for Read channel
always_ff @(posedge ACLK, negedge SYN_RESET)
begin

// write operation for read memory
    if(~SYN_RESET)
    begin
        rd_memory [temp_ARADDR] <= 8'b0000_0000;
    end
        
    else if(WVALID)
         rd_memory[temp_ARADDR] <= temp_RDATA_OUT;    
end

// read operation for read memory
always_ff @(posedge ACLK, negedge SYN_RESET)
begin
    if(~SYN_RESET)
        temp_data_rd <= 8'b0000_0000;
        
    else if(memory_out_rd)
        temp_data_rd <= rd_memory[temp_ARADDR];    
end

/////////////////////////////
// continuous assignment
/////////////////////////////
always_ff @(posedge ACLK or negedge SYN_RESET)
begin
	if(~SYN_RESET)
	begin
		// registered inputs
         temp_ARVALID <= 0;
         temp_RVALID  <= 0;
         temp_ARADDR  <= 0;
         temp_RDATA   <= 0;
         temp_RDATA_OUT   <= 0;
         temp_RDATA_VALID <= 0;
         temp_PENDING_TRANSACTION_RD <= 0;
         temp_RREADY  <= 0;

         // registered outputs
         RRESP   <= 0;
         ARREADY <= 0;
         RDATA_VALID_ACK <= 0;
	end

	else
	begin
		// registered inputs
		 temp_ARVALID <= ARVALID;
         temp_RVALID  <= RVALID;
         temp_ARADDR  <= ARADDR;
         temp_RDATA_OUT   <= RDATA_OUT;
         temp_RDATA_VALID <= RDATA_VALID;
         temp_PENDING_TRANSACTION_RD <= PENDING_TRANSACTION_RD;
         temp_RREADY  <= RREADY;
         temp_RDATA_VALID <= RDATA_VALID;


         // registered outputs
         RDATA   <= temp_RDATA_OUT;
         RRESP   <= temp_RRESP;
         ARREADY <= temp_ARREADY;
         RDATA_VALID_ACK <= temp_RDATA_VALID_ACK;
         
	end

end

endmodule : axi_slave
`endif