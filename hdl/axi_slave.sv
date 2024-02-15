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

    ////////////////////////////////////
	// Read Address channel signals (AR)
	////////////////////////////////////
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

    /////////////////////////////////////////
    // AXI slave to I2C master Write signals
    /////////////////////////////////////////
	output logic [`OUTPUT_ADDR_WIDTH -1:0] ADDR_DATA_OUT,
	output logic VALID_ADDR_DATA_OUT,
    input  wire  VALID_ADDR_DATA_OUT_ACK,
    input  wire  VALID_ADDR_DATA_OUT_ACK_VALID,
    
    
    /////////////////////////////////////////
    // AXI slave to I2C master Read signals
    /////////////////////////////////////////
	output logic RDATA_VALID_ACK,
	output logic I2C_MASTER_TRIGGER,

	input  wire [`RDATA_WIDTH -1:0] RDATA_OUT,
	input  wire RDATA_VALID,

	input wire PENDING_TRANSACTION_WR,
	input wire PENDING_TRANSACTION_RD
);
/////////////////////////////////////////////
// +++++++++ temporary variables +++++++++ //
//////////////////////////////////////////////
reg [3:0] DEVICE_ID = 4'hA;


////////////////////////////////////////////
// +++++++++ reset synchronizer +++++++++ //
////////////////////////////////////////////
 
reg SYN_RESET;
reg resetOut;
always_ff @(posedge ACLK, negedge ARESETn)
begin
	if(~ARESETn)
		{SYN_RESET, resetOut} <= 1'b0;
	else
		{SYN_RESET, resetOut} <= {resetOut, 1'b1};
end


//////////////////////////////////////////
// +++++++++++++++ CDC ++++++++++++++++ //  
//////////////////////////////////////////


////// VALID_ADDR_DATA_OUT_ACK, VALID_ADDR_DATA_OUT_ACK_VALID //////
reg SYN_VALID_ADDR_DATA_OUT_ACK, SYN_VALID_ADDR_DATA_OUT_ACK_S1;
reg SYN_VALID_ADDR_DATA_OUT_ACK_VALID, SYN_VALID_ADDR_DATA_OUT_ACK_VALID_S1;


always_ff @(posedge ACLK, negedge SYN_RESET)
begin
   if(~SYN_RESET)
   begin
      {SYN_VALID_ADDR_DATA_OUT_ACK, SYN_VALID_ADDR_DATA_OUT_ACK_S1} <= 0;
      {SYN_VALID_ADDR_DATA_OUT_ACK_VALID, SYN_VALID_ADDR_DATA_OUT_ACK_VALID_S1} <= 0;
   end
   
   else
   begin
      {SYN_VALID_ADDR_DATA_OUT_ACK, 
       SYN_VALID_ADDR_DATA_OUT_ACK_S1}   <= {SYN_VALID_ADDR_DATA_OUT_ACK_S1, 
                                             VALID_ADDR_DATA_OUT_ACK};
       
      {SYN_VALID_ADDR_DATA_OUT_ACK_VALID,
       SYN_VALID_ADDR_DATA_OUT_ACK_VALID_S1} <= {SYN_VALID_ADDR_DATA_OUT_ACK_VALID_S1, 
                                                 VALID_ADDR_DATA_OUT_ACK_VALID};
      
   end
end 

//////// PENDING_WR Signal ////////
reg PENDING_TRANSACTION_WR_S1, PENDING_TRANSACTION_WR_S2;

always_ff @(posedge ACLK, negedge SYN_RESET)
begin
   if(~SYN_RESET)
   begin
      {PENDING_TRANSACTION_WR_S2, PENDING_TRANSACTION_WR_S1} <= 0;
   end
   
   else
   begin
      {PENDING_TRANSACTION_WR_S2, PENDING_TRANSACTION_WR_S1} <= {PENDING_TRANSACTION_WR_S1, PENDING_TRANSACTION_WR};
   end
end

// level to pulse conversion
reg P2L_VALID_ADDR_DATA_OUT_ACK;
reg P2L_VALID_ADDR_DATA_OUT_ACK_VALID;

always_ff @(posedge ACLK or negedge SYN_RESET)
begin
   if(~SYN_RESET)
   begin
      {P2L_VALID_ADDR_DATA_OUT_ACK, P2L_VALID_ADDR_DATA_OUT_ACK_VALID} <= 0;
   
   end

   else
   begin
        P2L_VALID_ADDR_DATA_OUT_ACK       <= (P2L_VALID_ADDR_DATA_OUT_ACK ^ SYN_VALID_ADDR_DATA_OUT_ACK);
        P2L_VALID_ADDR_DATA_OUT_ACK_VALID <= (P2L_VALID_ADDR_DATA_OUT_ACK_VALID ^ SYN_VALID_ADDR_DATA_OUT_ACK_VALID);
   end
end

// level to pulse conversion
reg P2L_PENDING_TRANSACTION_WR;

always_ff @(posedge ACLK or negedge SYN_RESET)
begin
   if(~SYN_RESET)
   begin
      P2L_PENDING_TRANSACTION_WR <= 0;
   end
   
   else
   begin
      P2L_PENDING_TRANSACTION_WR <= (P2L_PENDING_TRANSACTION_WR ^ PENDING_TRANSACTION_WR_S2);
   end


end
///////////////////////////////////////////////////////
// ++++++++++++++ Write Channel ++++++++++++++++++++ //
///////////////////////////////////////////////////////


////////////////////////////////////
// Write Address Channel FSM
////////////////////////////////////

reg [`DATA_WIDTH -1:0] slave_mem [15]; // storing 15 data
reg [`ADDR_WIDTH -1:0] AWADDR_reg;

// variables for write address slave
parameter [1:0] AW_IDLE_S = 2'b00;
parameter [1:0] AW_START_S= 2'b01;
parameter [1:0] AW_READY_S= 2'b10;

// state varibales
reg [1:0] AW_next_state, AW_present_state;

// next state logic
always_ff @(posedge  ACLK, negedge SYN_RESET)
begin : AW_next_state_logic_proc

	if(~SYN_RESET)
		AW_present_state <= AW_IDLE_S;
		
	else
		AW_present_state <= AW_next_state;
		
end : AW_next_state_logic_proc

// combinational logic
always_comb 
begin : AW_combinational_logic_proc
	case(AW_present_state)

		AW_IDLE_S:
		begin
			if(AWVALID)
				AW_next_state = AW_START_S;

			else
				AW_next_state = AW_IDLE_S;
		end

		AW_START_S:
		begin
			AW_next_state = AW_READY_S;
		end

		AW_READY_S:
		begin
			AW_next_state = AW_IDLE_S;
		end

		default:
		begin
			AW_next_state = AW_IDLE_S;
		end

	endcase
end : AW_combinational_logic_proc

// Output logic
always @(posedge ACLK or negedge SYN_RESET)
begin : AW_output_logic
	if(~SYN_RESET)
	begin
		AWREADY <= 1'b0;
	    I2C_MASTER_TRIGGER <= 0;
	end	

	else
	begin
		case(AW_next_state)
			AW_IDLE_S:
			begin
			     AWREADY <= 1'b0;
			end

			AW_START_S:
			begin
			 	 AWREADY <= 1'b1;
			 	 AWADDR_reg <= AWADDR;

			 	 // Sending trigger to I2C
			 	 // sending level high to I2C master
			 	 I2C_MASTER_TRIGGER <= 1 ^ I2C_MASTER_TRIGGER;

			end

			AW_READY_S:
			begin
			AWREADY <= 1'b0;
		    end

			default: 
			AWREADY <= 1'b0;

		endcase // AW_next_state
		
	end

end : AW_output_logic
/////////////////////////////
// Write Data Channel FSM ///
/////////////////////////////

// temporary variables 
// pulse to level
reg P2L_VALID_ADDR_DATA_OUT; 

// FSM parameters
parameter [1:0] W_IDLE_S  = 2'b00;
parameter [1:0] W_START_S = 2'b01;
parameter [1:0] W_WAIT_S  = 2'b10; 
parameter [1:0] W_TFR_S   = 2'b11;


// state varibales
reg [1:0] W_present_state, W_next_state;

// next state logic
always_ff @(posedge ACLK, negedge SYN_RESET)
begin : W_next_state_logic_proc
	if(~SYN_RESET)
		W_present_state <= W_IDLE_S;

	else 
		W_present_state <= W_next_state;

end : W_next_state_logic_proc


// combinational logic
always_comb
begin : W_combination_logic_proc
	case(W_present_state)

		W_IDLE_S:
		begin
			W_next_state = W_START_S;
		end

		W_START_S:
		begin
			if(AWREADY)
				W_next_state = W_WAIT_S;
			else
				W_next_state = W_START_S;
			
		end

		W_WAIT_S:
		begin
			if(WVALID)
				W_next_state = W_TFR_S;
			else
				W_next_state = W_WAIT_S;
		end

		W_TFR_S:
		begin	
			W_next_state = W_IDLE_S;
		end

		default: 
		begin
			W_next_state = W_IDLE_S;
		end

	endcase
end : W_combination_logic_proc


// output logic
	always_ff @(posedge ACLK, negedge SYN_RESET)
	begin : W_output_logic_proc
		if(~SYN_RESET)
		begin
			WREADY <= 1'b0;
//			VALID_ADDR_DATA_OUT <= 1'b0;
			P2L_VALID_ADDR_DATA_OUT <= 1'b0;
	    end


		else
		begin
			case(W_next_state)
				W_IDLE_S:
				begin
					WREADY <= 1'b0;
					P2L_VALID_ADDR_DATA_OUT  <= 0;
				end

				W_START_S:
				begin
					WREADY <= 1'b0;
				end

				W_WAIT_S:
				begin
					WREADY <= 1'b0;
				end

				W_TFR_S:
				begin
					WREADY <= 1'b1;
					slave_mem[0] <= WDATA; 

					 // Comparing Upper HW for valid I2C address space
			 	     if(AWADDR_reg[31:16] == 16'h1234)
			 	     begin
			 	     	// Sending valid data to I2C channel 
			 	     	{ADDR_DATA_OUT[19:16], ADDR_DATA_OUT[15:8], ADDR_DATA_OUT[7:0]} <= {DEVICE_ID, AWADDR_reg[6:0], WDATA[7:0]};
			 	     	P2L_VALID_ADDR_DATA_OUT <= 1'b1 ^ P2L_VALID_ADDR_DATA_OUT;
			 	     end

			 	     else
			 	     begin
			 	     	{ADDR_DATA_OUT[19:16], ADDR_DATA_OUT[15:8], ADDR_DATA_OUT[7:0]} <= {DEVICE_ID, AWADDR_reg[6:0], WDATA[7:0]};
			 	     	P2L_VALID_ADDR_DATA_OUT <= 1'b0 ^ P2L_VALID_ADDR_DATA_OUT;
			 	     end
				end


				default:
				begin
					WREADY <= 1'b0;
//					P2L_VALID_ADDR_DATA_OUT  <= 0;
				end

			endcase
		end

	end : W_output_logic_proc

assign VALID_ADDR_DATA_OUT = P2L_VALID_ADDR_DATA_OUT;
/////////////////////////////////
// Write Response channel FSM // 
/////////////////////////////////

// FSM parameters
parameter [1:0] B_IDLE_s = 2'b00;
parameter [1:0] B_START_s = 2'b01;
parameter [1:0] B_READY_s= 2'b10;


// response channel state variables
reg [1:0] B_present_state, B_next_state;


// next_state logic
always_ff @(posedge ACLK, negedge SYN_RESET)
begin : B_next_state_logic_proc
	if(~SYN_RESET)
		B_present_state <= B_IDLE_s;

	else
		B_present_state <= B_next_state;

end : B_next_state_logic_proc


// Combo logic
always_comb
begin : B_combinational_logic_proc
	case(B_present_state)
		B_IDLE_s:
		begin
			if(BREADY)
				B_next_state = B_START_s;
			else
				B_next_state = B_IDLE_s;
		end

		B_START_s:
		begin
			if(~P2L_PENDING_TRANSACTION_WR & P2L_VALID_ADDR_DATA_OUT_ACK_VALID & P2L_VALID_ADDR_DATA_OUT_ACK)
			    B_next_state = B_READY_s;

			else
				B_next_state = B_IDLE_s;
		end

		B_READY_s:
		begin
		if(P2L_PENDING_TRANSACTION_WR)
			B_next_state = B_IDLE_s;
			
		else
			B_next_state = B_READY_s;
			
		end

		default:
		begin
			B_next_state = B_IDLE_s;
			
		end
	endcase

end : B_combinational_logic_proc

always_ff @(posedge ACLK, negedge SYN_RESET)
begin : B_output_logic_proc
	if(~SYN_RESET)
		BVALID <= 1'b0;

	else
	begin
		case(B_next_state)
		     B_IDLE_s:
		     begin
		     	BVALID <= 1'b0;
		     	BRESP  <= OKAY;
		     end
     
		     B_START_s:
		     begin
		     	BVALID <= 1'b1;
		     	BRESP  <= EXOKAY;
		     	
		     end
     
		     B_READY_s:
		     begin
		     	BVALID <= 1'b1;
		     	BRESP  <= OKAY;
		     end
     
		     default:
		     begin
		     	BVALID <= 1'b0;
		     	BRESP  <= EXOKAY;
		     end

     	endcase
		
	end

end : B_output_logic_proc

endmodule : axi_slave
`endif