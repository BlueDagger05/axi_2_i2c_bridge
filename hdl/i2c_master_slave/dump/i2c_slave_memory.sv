`timescale 1ns/1ps

module i2c_slave_memory (
	input SCL, // Clock line
	input wire RESETn,
    input  wire  s_sda_i,
    output logic s_sda_o,
    output logic s_sda_o_en // Experimental
);

typedef enum bit {LOW, HIGH} e_level;
typedef enum bit {ACK, NACK} e_ack_nack;
// temporary variables
reg start_i2c = 0;
reg stop_i2c;

reg [7:0] devID_Check;
reg [7:0] data_reg;
reg [7:0] counter = 0 ;
reg [7:0] DEV_ID  = 8'h01;

// memory register
reg [7:0] slave_memory[255:0];

// for storing address
reg[7:0] addr_reg;

// check if write/read
reg is_wr_rdb;

// state variables
reg [1:0] next_state, present_state;

////////////////////////////
// state parameters
////////////////////////////

parameter [2:0] IDLE_PHASE       = 3'b000; 
parameter [2:0] DEV_ADDR_PHASE   = 3'b001;
parameter [2:0] WRITE_READ_PHASE = 3'b010;
parameter [2:0] REG_ADDR_PHASE   = 3'b011;
parameter [2:0] STORE_DATA_PHASE = 3'b100;        
parameter [2:0] DATA_OUT_PHASE   = 3'b101;  
parameter [2:0] STOP_PHASE       = 3'b111; 


// for start condition
always @(negedge s_sda_i)
begin
	// start condition detected
	if( (SCL == 1) || ((next_state == REG_ADDR_PHASE) && (start_i2c == 0)) )
	begin
		start_i2c <= 1;
	end
end

// for stop condition
always_ff @(posedge s_sda_i)
begin

	// checking for stop condition 
	if(SCL == 1)
		start_i2c <= 0;
end

// using two state design pattern

always_ff @(posedge SCL, negedge RESETn)
begin
	if(~RESETn)
	begin
		present_state          <= IDLE_PHASE;
		slave_memory[addr_reg] <= 0; 
	end

	else
		present_state <= next_state;
end

always_comb
begin
	case(present_state)
		IDLE_PHASE :
		begin
			if(start_i2c)
			begin
				next_state = DEV_ADDR_PHASE;
				s_sda_o_en = 0;
			end

			else
			begin
				s_sda_o_en = 0;
				next_state = IDLE_PHASE;
			end
		end

        DEV_ADDR_PHASE :
        begin  //{

        	// storing data bit by bit
        	devID_Check[counter] = s_sda_i;
        	counter++;

        	// At 7th count, check for valid DEV ID
        	if(counter == 6)
        	begin // {
        		// check with first 6 bits
        		if(DEV_ID == devID_Check[6:0])
        		begin
        			next_state = REG_ADDR_PHASE;
        			// resetting the count
        			counter    = 0;
        		end

        		else
        			begin
        			    // If ID dosen't matches go to IDLE_PHASE
        			    next_state = IDLE_PHASE;
        			end
        	end   // }

        	else
        		// stay in same state
        		next_state = DEV_ADDR_PHASE;

        end  // }


        WRITE_READ_PHASE :
        begin // {

        	// storing the read_bit
        	devID_Check[7] = s_sda_i;
        	next_state     = STORE_DATA_PHASE;
        end // }


        REG_ADDR_PHASE: 
        begin // {
        	addr_reg[counter] = s_sda_i;
        	counter++;

        	// After storing address, transit to data phase 
        	if(counter == 7)
        		begin
        			s_sda_o    = ACK;
        		    next_state = STORE_DATA_PHASE;

        		    // reset the counter
        		    counter    = 0;
        		end

        	// else stay in same state
        	else
        		next_state = REG_ADDR_PHASE;

        end   // }

        STORE_DATA_PHASE :
        begin //{

        	// if repeated start detected
        	if(start)
        	begin
        		next_state = DATA_OUT_PHASE;
        		is_wr_rdb  = 0;
        	end

        	else
        	begin
        		// storing data bit by bit
        		data_reg[counter] = s_sda_o;

        		// incrementing the count
        		counter++;

        		if(counter == 7)
        		begin
        			slave_memory[addr_reg] = data_reg;
        			next_state             = STOP_PHASE;

        			// write operation
        			is_wr_rdb = 1;

        			// resetting the count
        			counter = 0;
        		end
        	end

        end //	}
        	

        DATA_OUT_PHASE :
        begin

        	// retriving the content of memory to the data_reg
        	data_reg = slave_memory[addr_reg];

        	if(counter == 7)
        	begin
        		next_state = STOP_PHASE;

        		// resetting the counter 
        		counter = 0;
        	end

        	else

        		// else stay in same phase
        		next_state = DATA_OUT_PHASE;

        	// sending data out
        	s_sda_o   = data_reg[counter];

        	// valid s_sda_o
        	s_sda_o_en = 1;

        	// incrementing the count
        	counter++;
        end


        STOP_PHASE :
        begin
        	if(is_wr_rdb == 1)
        		s_sda_o = ACK;
        	else
        	begin
        		s_sda_o = NACK;
        	end

        	next_state = IDLE_PHASE;
        end

        default : next_state = IDLE_PHASE;

	endcase // present_state

end



//// next state logic
//always_ff @(posedge SCL , negedge RESETn)
//begin
//	if(~RESETn)
//	begin
//		present_state <= IDLE_PHASE;
//	end

//	else
//	begin
//		present_state <= next_state;
		
//        if(start_i2c)
        
//        begin
//    	case(present_state)
//    		IDLE_PHASE:
//    		begin
//    				next_state <= DEVICE_ADDR_PHASE;
//    		end
    
//    		DEVICE_ADDR_PHASE:
//	    	begin
//	    		// storing the device address bit by bit in register
//	    		addr_register[counter] <= s_sda_i;
//	    		counter++;
    
//                // comparing device_addr with received address
//		    	if(counter == 6)
//		    	begin  // {
//		    		if(addr_register[6:0] == device_addr[6:0]) 
//	    			begin
//                 			  next_state <= WRITE_READ_PHASE;
//				     end
				     
//				     else
//				     begin
//					     // send nack, for device address dosen't matches
//					     next_state <= ACK_NACK_PHASE;
//					 end
					 
//			      end // }
    
//     		    end


//     		WRITE_READ_PHASE:
//     		begin
     		     
//     			// checking for repeated start
//     			// if holds true, save address and send data out
//     			if(start_i2c)
//     			begin
////     				 to match device address
//     				next_state <= DEVICE_ADDR_PHASE;
     
//     				// read transfer
////     				is_wr_rdb <= LOW;


//     			end
     
//                 // in write state, store address and write data to the memory
//     			else
//     			begin
//     				// write transfer
//     				is_wr_rdb <= HIGH;
     
//     				// storing address
//     				addr_register[counter] <= s_sda_i;
     
//     				// incrementing count
//     				counter++;

//	     			// if recvd address, transit to data phase
//	     			if(&counter)
//	     			begin
//	     				s_sda_o    <= ACK;
//	     				next_state <= DATA_PHASE;
//	     			end
     
//		     		// while counter completes count, maintain the same state
//			    	else
//				    	next_state <= WRITE_READ_PHASE;
//			    end
//		    end

//		    DATA_PHASE:
//		    begin

//			// write transaction
//			if(is_wr_rdb == HIGH)
//			begin
//				// serially storing data bit by bit
//				data_reg[counter] <= s_sda_i;
//				counter++;

//				if(&counter)
//				begin
//					// storing data in memory
//					slave_memory[addr_register] <= data_reg;

//					// sending ACK
//					s_sda_o    <= ACK;
//					next_state <= STOP_PHASE;
//				end

//				else
//     				next_state <= DATA_PHASE;
//     			end     

//     			else
//     			begin

//     				// storing memory data to data_reg
//     				data_reg <= slave_memory[addr_register];
//     				s_sda_o  <= data_reg[counter];
//     				counter++;     

//     				if(&counter)
//     				begin
//     					s_sda_o    <= NACK;
//     					next_state <= STOP_PHASE;
//     				end     

//     				else
//     					next_state <= DATA_PHASE;
//     			end     

     				
//     		end     

//     		STOP_PHASE:
//     		begin
//     			s_sda_o    <= ACK;
//     			next_state <= IDLE_PHASE;
//     			start_i2c  <= LOW;
//     		end     

//     		default: next_state <= IDLE_PHASE;
//     	endcase // present_state     

//     end     
//     end
//     end
endmodule : i2c_slave_memory 