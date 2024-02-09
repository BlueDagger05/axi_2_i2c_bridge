`timescale 1ns/1ps
/////////////////////////////////////////////////////////
// AXI master RTL
/////////////////////////////////////////////////////////
`include "./defines.sv"

typedef enum bit [1:0] {OKAY, EXOKAY, SLVERR, DECERR} e_resp;

module axi_master (
    
    input wire ACLK,
    input wire ARESETn,

	// write requeset channel signals
	input    wire                   AWREADY,
	output  logic                   AWVALID,
	output  logic [`ADDR_WIDTH -1:0] AWADDR,
	output  logic [`SIZE -1:0] 	    AWSIZE,
	output  logic [`BURST_SIZE -1:0] AWBURST,

	// write data channel signals
	input    wire                    WREADY,
	output  logic                    WVALID,
	output  logic                    WLAST,
	output  logic [`WDATA_WIDTH -1:0] WDATA,

	// write response channel signals
	 input wire  [`RESPONSE_WIDTH -1:0] BRESP,
	input  wire                        BVALID,
	output logic                       BREADY
);
//////////////////////////////////////
// .......temporary variables.........
//////////////////////////////////////
reg [2:0] present_state, next_state;

// variable for ALL_VALID state
bit all_valid_returns;

// variable for WRITE_DATA state
bit [7:0] is_last;

// variable for WRITE_DATA state
bit [`WDATA_WIDTH-1:0] WDATA_temp;

// enums
e_resp st;

// one hot encoding states
parameter IDLE       = 5'b00001;
parameter WRITE_REQ  = 5'b00010;
parameter WRITE_DATA = 5'b00100;
parameter WRITE_RESP = 5'b01000;
parameter ALL_VALID  = 5'b10000;

// state register 
always_ff @(posedge ACLK or negedge ARESETn)
begin : response_proc

	if(~ARESETn)
	begin : reset_proc
		// settting response, data and response 
		// channel valid and ready signal to LOW
		{AWVALID, WVALID, BREADY} <= 3'b0;
		present_state <= IDLE;

	end : reset_proc

	else 
	begin : post_reset_proc
		// assigning next_state to present state
		// when reset is de-asserted
		present_state <= next_state;
	end : post_reset_proc

end : response_proc


// next state logic
always_comb 
begin : next_state_proc
	case(present_state)
		IDLE: 
		begin : idle_state_proc
			if(~ARESETn)
			begin
				next_state = IDLE;
			end

			else if(AWREADY)
			begin
				next_state = WRITE_REQ;
			end

			else if(WREADY)
			begin
				next_state = WRITE_DATA;
			end

			else if(BVALID & ~|BRESP)
			begin
				next_state = WRITE_RESP;
			end

			else
			begin
				next_state = IDLE;
			end
			
		end : idle_state_proc


		WRITE_REQ:
		begin : WRITE_REQ_proc
			if(AWREADY)
				next_state = WRITE_REQ;

            // Response channel dependency
            // if AWREADY and AWVALID are HIGH
            // transite to ALL_VALID state
			else if(AWREADY && AWVALID)
				next_state = ALL_VALID;
			else 
				next_state = IDLE;
		end : WRITE_REQ_proc


		WRITE_DATA:
		begin : write_data_proc
			if(WREADY)
				next_state = WRITE_DATA;

            // if transaction completes, transit to 
            // ALL_VALID state
			else if(WREADY && WVALID && WLAST)
				next_state = ALL_VALID;

			else 
				next_state = IDLE;

		end : write_data_proc


		WRITE_RESP:
		begin : write_resp_proc

			if(BRESP == st.OKAY && BVALID)
			begin
				// transiting to WRITE_DATA state,
				// after completion of transfer
				next_state = WRITE_DATA;
			end

			else
				// transiting to IDLE state
				next_state = IDLE;

		end : write_resp_proc


		ALL_VALID: 
		begin : all_valid_proc
			// all valid and response condtions met
			// transit to write_resp state
            if(BRESP == st.OKAY && BVALID)
                 next_state = WRITE_RESP;
                 
            else 
                 next_state = IDLE;

		end : all_valid_proc 

		default:
		next_state = IDLE;

	endcase // present_state


end : next_state_proc


// output logic
always_comb
begin : output_logic_proc

	case(present_state) 
		IDLE:
		begin
			// Invalidating the transactions in IDLE state
			{BREADY, AWVALID, WVALID} = 3'b0;
            
            // sending stream of zeroe's when IDLE
			WDATA_temp = 32'b0000_0000_0000_0000;

			// resetting the count value
			is_last = 8'b000_00000;
		end
		WRITE_REQ:
		begin
			// assertion of AWVALID is independent of 
			// arrival of AWREADY from subordinate 
			AWVALID = 1'b1;

            // fixed address of 8'hAA
			AWADDR = 8'hAA;

			// Fixed burst
			AWBURST = 2'b00;

			// Fixed size of 8 transfers
			AWSIZE = 2'b11;
			
		end

		WRITE_DATA:
		begin
			WVALID = 1'b1;

			// incrementing WDATA value
			WDATA  = WDATA_temp + 1'b1;

			// checking if is_last completes its cycles
			if(&is_last)
				WLAST = 1'b1;

			// incrementing is_last variable
			is_last = is_last + 1'b1;

		end

		WRITE_RESP:
		begin
			if(all_valid_returns)
				BREADY = 1;
		end

		ALL_VALID:
		begin
		    if((~|BRESP) & (BVALID) )
			all_valid_returns = 1;
		end

		default :
		{BREADY, AWVALID, WVALID} = 3'b0;
	endcase

end: output_logic_proc


endmodule : axi_master
