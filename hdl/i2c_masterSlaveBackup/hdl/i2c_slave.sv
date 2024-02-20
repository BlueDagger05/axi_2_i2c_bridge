`timescale 1ns / 1ps


module i2c_slave(

// AXI signals
input   wire scl,
input   wire clk,
input   wire resetn,
input   wire s_sda_i,
output logic s_sda_o,
output logic ack_err,
input  wire  slave_handshake,
input  wire [9:0] sync_count,
output logic done
//output logic  done
);

typedef enum logic [3:0] {IDLE, READ_ADDR, SEND_ACK1, SEND_DATA, MASTER_ACK, READ_DATA, SEND_ACK2, WAIT, STOP} e_state;

// local parameters
localparam MEM_DEPTH  = 256;
localparam DATA_WIDTH = 8;

// memory variable
reg [DATA_WIDTH -1 :0] memory [MEM_DEPTH -1 : 0];

// address register
reg [DATA_WIDTH -1:0] addrReg;
reg [DATA_WIDTH -1:0] addr;

// slave address register
reg [DATA_WIDTH -1:0] slvAddr;

// read operation
reg r_mem = 0;

// write operation
reg w_mem = 0;

// output data
reg [DATA_WIDTH -1:0] dataOut;

// input data
reg [DATA_WIDTH -1:0] inData;

// temporary sda
reg s_sda_t;

// enable signal
reg sda_en;

// counter
reg [3:0] dataCount = 0;



// configuring memory
always @(posedge clk, negedge resetn)
begin // {
	for(int i=0; i<MEM_DEPTH ; i++)
	begin
		memory[i] <= 0;
		dataOut   <= 0;
	end

	// store data for write operation
	else if(w_mem == 1)
	begin
		memory[addrReg] <= s_sda_i;
	end

	// send data for read operation
	else if(r_mem == 1)
	begin
		dataOut <= memory[addrReg];
	end

end // }

// setting i2cFreq to 5MHz due to board constraint
parameter i2c_freq = 5000000;   // 5MHz
parameter sys_clk  = 100000000; // 100MHz

parameter clk_count4 = (sys_clk/i2c_freq)*4; // 100
parameter clk_count1 = clk_count4/4 // 25

// counter variable
int count = 0;

// pulse variable
reg [1:0] pulse;

reg [3:0] state;

reg busy;

reg r_ack;
//// pulse generation
always_ff @(posedge clk, negedge resetn)
begin //{
	if(~resetn)
	begin
		pulse <= 0;
		count <= 0;
	end

	else if(busy == 0)
	begin
		if(slave_handshake == 1)
		pulse <= 2;
	    count <= sync_count;
	end

	else if(count == clk_count1 -1)
	begin
		pulse <= 1;
		count <= count+1;
	end

	else if(count == clk_count1*2 -1)
	begin
		pulse <= 2;
		count <= count+1 
	end

	else if(count == clk_count1*3 -1)
	begin
		pulse <= 3;
		count <= count+1;
	end

	else if(count == clk_count1*4 -1)
	begin
		pulse <= 0;
		count <= 0;
	end

	else begin
		count <= count+1;
	end
	
end //}


// temporary scl
reg scl_t;

logic start;

always@(posedge clk)
begin
	scl_t <= scl;
end

// temporary
assign start = ~scl & scl_t

always_ff @(posedge clk, negedge resetn)
begin
	if(~resetn)
	begin
		dataCount <= 0;
		state     <= IDLE;
		addrReg   <= 0;
		sda_en    <= 0;
		s_sda_t   <= 0;
		addr      <= 0;
		memory    <= 0;
		inData    <= 0;
		ack_err   <= 0;
		done      <= 0;
		busy      <= 0;


	end

	else
	begin //{
		case(state)
			IDLE:
			begin
				if(scl == 1'b1 && sda == 1'b0)
				begin
					busy  <= 1'b1;
					state <= WAIT;
				end

				else
				begin
					state <= IDLE;
				end
				
			end

			WAIT:
			begin
				// wait for two SCL clocks 
				if(pulse == 2'b11 && count == 100)
					state <= READ_ADDR;
				else
					state <= WAIT;
			end

			READ_ADDR:
			begin // {
				sda_en <= 1'b0;
				if(dataCount <= 7)
				begin
					case(pulse)
						0: begin end
						1: begin end
						2: 
						begin 
							addrReg <= (count == 50) ? {addrReg[6:0], s_sda_i} : addrReg;
						end	
						3: begin end

					endcase // pulse

					if(count == clk_count1*4 -1)
					begin
						state <= READ_ADDR;
						dataCount <= dataCount + 1;
					end

					else
					begin
						state <= READ_ADDR;
					end

				end

				else
				begin
					state     <= SEND_ACK1;
					dataCount <= 0;
					sda_en    <= 1'b1;
					addr      <= addrReg[7:1];
				end

				

			end // }

			SEND_ACK1:
			begin
				case (pulse)
					0: s_sda_t <= 1'b0; 
					1: begin end
					2: begin end	
					3: begin end	
				
				endcase

				if(count == clk_count1*4 -1)
				begin
					if(addrReg[0] == 1'b1) // read operation
					begin
						state <= SEND_DATA;
						r_mem <= 1'b1;
					end

					else 
					begin
						state <= READ_DATA;
						r_mem <= 0;
					end
				end

				else
				begin
					state <= SEND_ACK1;
				end
				
			end

			READ_DATA:
			begin // {
				sda_en <= 1'b0;
				if(dataCount <= 7)
				begin
					case (pulse)
						0: begin end
						1: begin end
						2: 
						begin 
							inData <= (count1 == 50) ? {din[7:0], s_sda_i} : inData;
						end
						3: begin end
					endcase

					if(count == clk_count1*4 -1)
					begin
						state     <= READ_DATA;
						dataCount <= dataCount + 1;
					end

					else
					begin
						state <= READ_DATA;
					end
					
				end

				else
				begin
					state <= SEND_ACK2;
					dataCount <= 0;
					sda_en    <= 1;
					w_mem     <= 1;
				end
				
			end // }

			SEND_ACK2:
			begin
					case (pulse)
						0: begin sda_t <= 1'b0; end
						1: begin w_mem <= 1'b0; end
						2: begin end
						3: begin end
					endcase

					if(count == clk_count1*4 -1)
					begin
						state  <= STOP;
						sda_en <= 1'b0;
					end

					else
					begin
						state <= SEND_ACK2;
					end
				

			end

			SEND_DATA:
			begin // {
				// reading addr to slave
				sda_en <=1; 
				if(dataCount <= 7)
				begin
					r_mem <= 1'b0;
					case (pulse)
						0: begin end
						1: begin s_sda_t <= (count == 25) ? dataOut[7-dataCount] : sda_t end	
						2: begin end	
						3: begin end	
					endcase

					if(count == clk_count1*4 -1)
					begin
						state <= SEND_DATA;
						dataCount <= dataCount + 1;
					end

					else
					begin
						state <= SEND_DATA;
					end
				end

				else
				begin
					state     <= MASTER_ACK;
					dataCount <= 0;
					sda_en    <= 0;
				end
				
			end // }

			MASTER_ACK:
			begin
					case (pulse)
						0: begin end
						1: begin r_ack <= (count == 25) ? sda_t : r_ack end	
						2: begin end	
						3: begin end	
					endcase

					if(count == clk_count1*4 -1)
					begin
						if(r_ack == 1'b1) // nack
						begin
							ack_err <= 1'b0;
							state   <= STOP;
							sda_en  <= 1'b0;
						end

						else
						begin
							ack_err <= 1'b1;
							state   <= STOP;
							sda_en  <= 0;
						end
					end

					else
					begin
						state <= MASTER_ACK;
					end
			end

			STOP:
			begin
				if(pulse == 2'b11 && count == 99)
				begin
					state <= IDLE;
					busy  <= 0;
					done  <= 1;
				end

				else 
					state <= STOP;
				
			end


			default: state <= IDLE;

		endcase


	end // }

end

assign s_sda_o = sda_t;
// assign s_sda_o = (sda_en == 1'b1) ? sda_t : 1'bz; // experimental
endmodule i2c_slave  
