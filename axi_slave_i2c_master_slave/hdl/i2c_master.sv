`timescale 1ns / 1ps

module i2c_master(
// Global Signals 
   input wire clk,
   input wire resetn,
   
// From AXI 
   input wire I2C_trigger,
   input wire [23:0] addr_data_out,
   input wire valid_addr_data_out,
   input  wire rdata_out_valid_ack,
   
// Towards AXI
   output logic [7:0] rdata_out,
   output logic       rdata_out_valid,  
   output logic valid_data_ack,
   output logic valid_data_ack_valid,
   output logic PENDING_WR,
   output logic PENDING_RD,

   
   // From I2C Slave 
   input  wire m_sda_i,
   output logic m_sda_o,
   
   // Towards I2C slave
   output scl_o

);

// temporary variable for master scl and sda 
reg m_scl_t = 0;
reg m_sda_t = 0;

parameter sys_freq = 100000000; // 100 MHz
parameter i2c_freq = 5000000; // 5 MHz 


parameter clk_count4 = (sys_freq/i2c_freq);  //20
parameter clk_count1 = clk_count4/4;          //4

// assign unique value to the transition of the pulse
reg [1:0] pulse;

// count integer
int count;

reg [9:0] sync_count;
reg slave_handshake;

// busy, ack_err, done
logic busy;
logic ack_err;
logic done;


always_ff @(posedge clk)
begin
    if(~resetn)
    begin
       pulse <= 0;
       count <= 0;
    end
       // wait till valid AXI data dosen't comes
    else if(busy == 1'b0)
    begin
       pulse <= 0;
       count <= 0;
    end
    
    // counts till 0 to 4
    else if(count == clk_count1 -1)
    begin
        pulse <= 1;
        count <= count + 1;
    end
       
    // counts till 5 to 9
   else if(count == clk_count1*2 -1)
   begin
      pulse <= 2;
      count <= count + 1;
   
   end
   
   // counts till 10 to 14
   else if(count == clk_count1*3 -1)
   begin
      pulse <= 3;
      count <= count + 1;
   end
   
   // counts till 14 to 19
   else if(count  == clk_count1*4 - 1)
   begin
       pulse <= 0;
       
       // reset the count;
       count <= 0;
   end
   // increment the count
   else
   begin
      count <= count + 1;
   end
       
end
/////////////////// AXI data Transfer ////////

// count variable
int countIn = 0;

// stores DEVID addres from addr_data_out
reg [6:0] devIDReg;// = 7'h1B;

// stores addres from addr_data_out
reg [7:0] addrReg; // = 8'hAB;

// stores data from addr_data_out
reg [7:0] dataReg; // = 8'h7A;

// register to store write read operation
reg is_WrRd;

// temporary read register for verification
reg [7:0] readReg = 8'hAB;

int i =0 , j =0;

// storing addr_data_out reg contents
//always_ff @(posedge clk, negedge resetn)
//begin
//  if(~resetn)
//  begin
//    countIn <= 0;
//  end
  
//  else
//  begin
//    if(valid_addr_data_out)
//    begin  // {
    
//      // for valid data, incrementing the count
//      countIn <= countIn + 1;

//      if(countIn < 7)
//      begin
//        devIDReg[countIn] <= addr_data_out[countIn];
//        valid_data_ack <= (countIn == 1) ? 1 :0;
//      end  
        
//      else if(countIn == 7)
//          is_WrRd <= addr_data_out[countIn];
        
//      else if (countIn >7 && countIn <= 15)
//      begin
//        addrReg[i] <= addr_data_out[countIn];
//        i <= i+1;
//      end    
        
//      else if(countIn >15 && countIn <=23)
//      begin
//        dataReg[j] <= addr_data_out[countIn];
//        valid_data_ack_valid = (countIn == 23) ? 1:0;
//        j <= j+1;
//      end    
      
//      end   
////        countIn <= 0;
//    end  // }

//end

always_ff @(posedge clk, negedge resetn)
begin
  if(~resetn)
  begin
    devIDReg    <= 0;
    valid_data_ack    <= 0;
    is_WrRd    <= 0;
    addrReg    <= 0;
    dataReg    <= 0;
    valid_data_ack_valid    <= 0;
  end
  else if(I2C_trigger == 1)
  begin
    devIDReg    <= {
        addr_data_out[0],
        addr_data_out[1],
        addr_data_out[2],
        addr_data_out[3],
        addr_data_out[4],
        addr_data_out[5],
        addr_data_out[6]
    };
    valid_data_ack    <= 1;
    is_WrRd    <= addr_data_out[7];
    addrReg    <= {
        addr_data_out[15],
        addr_data_out[14],
        addr_data_out[13],
        addr_data_out[12],
        addr_data_out[11],
        addr_data_out[10],
        addr_data_out[9],
        addr_data_out[8]
    };
    dataReg    <= {
        addr_data_out[23],
        addr_data_out[22],
        addr_data_out[21],
        addr_data_out[20],
        addr_data_out[19],
        addr_data_out[18],
        addr_data_out[17],
        addr_data_out[16]
    };
    valid_data_ack_valid    <= 1;
  end
end

//////////////////////////
// temporary variables
//////////////////////////
reg [3:0] dataCount;    // counts number of bits
reg [7:0] dataAddrReg;  // stores data and address
reg [7:0] sendData;     // stores write data

reg rcv_ack  = 0;
//reg m_sda_en = 0;  // 
 
reg newData; 

typedef enum logic [3:0] {IDLE, START, SLV_ADDR, ACK1_SLV, WRITE_ADDR, ACK2_SLV, WRITE_DATA, READ_DATA, STOP , ACK3_SLV, MASTER_ACK} e_state;
//parameter [3:0] IDLE        = 4'b0000;
//parameter [3:0] START       = 4'b0001;
//parameter [3:0] SLV_ADDR    = 4'b0010;
//parameter [3:0] WRITE_ADDR  = 4'b0011;
//parameter [3:0] ACK1_SLV    = 4'b0100;
//parameter [3:0] WRITE_DATA  = 4'b0101;
//parameter [3:0] READ_DATA   = 4'b0110;
//parameter [3:0] STOP        = 4'b0111;
//parameter [3:0] ACK2_SLV    = 4'b1000;
//parameter [3:0] ACK3_SLV    = 4'b1001;
//parameter [3:0] MASTER_ACK =  4'b1010;

// default value for state, as IDLE
e_state state = IDLE;


e_state prev_state = IDLE;


// write or read operation
reg operation;


// register to store input data
reg [7:0] rx_data;


// I2C to AXI control variables

// valid rdata
reg validRdata;

// handshake signals 
reg axiHandshake;

// pending write
reg writeIsPending;

// pending read
reg readIsPending;


always @(posedge clk, negedge resetn)
begin // {
   if(~resetn)
      begin // {
         dataCount <= 0;
         dataAddrReg <= 0;
         sendData <= 0;
         m_scl_t <= 1;
         m_sda_t <= 1;
         state   <= IDLE;
         busy    <= 1'b0;
         ack_err <= 1'b0;
         done    <= 1'b0;
         slave_handshake <=0;
      end  // }
      
   // start opertaion when Trigger occurs   
   else
   begin // {
   case(state) // {
   
       /// IDLE 
       IDLE:
       begin // {
          done <= 1'b0;
          newData = 1; // temporary
          prev_state <= IDLE;
          if(I2C_trigger == 1'b1)
          begin
             dataAddrReg <= {addrReg, 1'b0 }; //operation}; // setting it to default write
             sendData    <= dataReg;
             busy        <= 1'b1;
             state       <= START;
             ack_err     <= 1'b0;
          end
          
          else
          begin
             dataAddrReg <= 0;
             sendData    <= 0;
             busy        <= 0;
             state       <= IDLE;
             ack_err     <= 0;
          end
          
       end // }
       
       
       ///   START
       START:
       begin // {
       ////////////////////////////////////////////////////////
 //SCL //  /-------|--------|--------|----------------
       // /        |        |        |
               
 //SDA // /--------|--------|        |
       // /        |        |--------|-------------
       ////////////////////////////////////////////////////////
         case(pulse)
         0: begin
               m_scl_t <= 1'b1; m_sda_t <= 1'b1;
            end
            
         1: begin 
               m_scl_t <= 1'b1; m_sda_t <= 1'b1;
            end
         2: begin 
               m_scl_t <= 1'b1; m_sda_t <= 1'b0;       
               slave_handshake <= 1; // temporary
            end
            
         3: begin
               m_scl_t <= 1'b1; m_sda_t <= 1'b0;
            end
            
         endcase
         
         // wait till full i2c clock period, 0 to 99 
         if(count == clk_count1*4-1)
         begin
//             slave_handshake <= 0; // temporary
             state   <= SLV_ADDR;
             m_scl_t <= 1'b0;
         end
         
         else
             state <= START;       
       
       end  // }
       
       // SLV_ADDR
       SLV_ADDR:
       begin // {
       
         if(dataCount <= 7)
         begin // {
            case(pulse)
            0:
            begin
              m_scl_t <= 0;
              m_sda_t <= 0;
            end
            
            1:
            begin
              m_scl_t <= 0;
              if(prev_state == ACK2_SLV)
              begin
                 m_sda_t <= (dataCount == 7) ? 1 : devIDReg[6- dataCount]; // read operation
              end
              
              else
                m_sda_t <= (dataCount == 7) ? 0 : devIDReg[6- dataCount]; // write operation
            end
            
            2:
            begin
              m_scl_t <= 1;
            end
            
            3:
            begin
              m_scl_t <= 1;
            end
            
            endcase // pulse
            
            if(count == 4*clk_count1 -1)
            begin
              state     <= SLV_ADDR;
              m_scl_t   <= 0;
              dataCount <= dataCount + 1;
            end
            
            else
            begin
               state <= SLV_ADDR;
            end
         end // }
         
         // goto read state if read operation
         else if(prev_state == ACK2_SLV)
         begin
           state     <= ACK1_SLV;
           dataCount <= 0;
         end  
         
         else 
         begin
           state     <= ACK1_SLV;
           dataCount <= 0;
         end
       
       end  // }


       /// ACK1_SLV
       ACK1_SLV:
       begin
         case(pulse)
            0:
            begin
               m_scl_t <= 0;
               m_sda_t <= 1;
            end
            
            1:
            begin
               m_scl_t <= 0;
               m_sda_t <= 1;
            end
            
            2:
            begin
               m_scl_t <= 1;
               m_sda_t <= 1;
               rcv_ack <= m_sda_i; //receiving valid acknowledge // m_sda_in;
            end
            
            3:
            begin
              m_scl_t <= 1;
              m_sda_t <= 1;
            end
         
         endcase // pulse
         
         
         // wating for a pulse
         if(count == clk_count1*4 -1)
         begin // {
//            m_sda_t <= 0;
            
            // if correct acknlg recvd, send stop to slave
            if(rcv_ack == 0)
            begin
                if(prev_state == ACK2_SLV)
                begin
                    state <= READ_DATA;
                    ack_err <= 0;
                end
                else
                begin
                    state   <= WRITE_ADDR;
                    ack_err <= 0;
                end
              
            end
            
            // else go to stop and send ack_err
            else
            begin
              // state   <= STOP;
              ack_err <= 1;
            end
         
         end // }
         
         // stay in same state
         else
         begin
           state <= ACK1_SLV;
         end

       end // }
       
       
           
       /// WRITE_ADDR
       WRITE_ADDR:
       begin // {
          if(dataCount <= 7)
          begin // {
          
             // changing data at the negedge
             case(pulse)
                0: begin
                      m_scl_t <= 1'b0; 
                      m_sda_t <= 1'b0;
                   end
                   
                1: begin 
                      m_scl_t <= 1'b0;
                      // serially shifting data towards the slave
                      m_sda_t <= addrReg[7-dataCount];
                   end
                   
                2: begin 
                      m_scl_t <= 1'b1; 
                   end
                   
                3: begin
                      m_scl_t <= 1'b1;
                   end
                   
             endcase // pulse
             
             // for each clk period, send data to slave
             if(count == 4*clk_count1 -1)
             begin
                state     <= WRITE_ADDR;
                m_scl_t   <= 1'b0;
                dataCount <= dataCount + 1;
             end
             
             // stay in same state unless all bits are transferred
             else
             begin
                state <= WRITE_ADDR;
             end
          
          end  // }
          
          
          else
          begin // {
          // transit to acknowledge state
          state <= ACK2_SLV;
          
          // reset the count, success sending 8-bit
          dataCount <= 0;
          end   // }
       
       end  // }
       
       
      /// ACK2_SLV
       ACK2_SLV:
       begin
         case(pulse)
            0:
            begin
               m_scl_t <= 0;
               m_sda_t <= 1;
            end
            
            1:
            begin
               m_scl_t <= 0;
               m_sda_t <= 1;
            end
            
            2:
            begin
               m_scl_t <= 1;
               m_sda_t <= 1;
               rcv_ack <= m_sda_i; //receiving valid acknowledge // m_sda_in;
            end
            
            3:
            begin
              m_scl_t <= 1;
              m_sda_t <= 1;
            end
         
         endcase // pulse
         
         
         // wating for a pulse
         if(count == clk_count1*4 -1)
         begin // {
//            m_sda_t <= 0;
            
            // if correct acknlg recvd, send stop to slave
            if(rcv_ack == 0)
            begin
              if(prev_state == WRITE_ADDR)
              begin
                 state   <= IDLE;
                 
                 // de asserting pending write
                 writeIsPending = 0;
              end
              
              // check for read or write operation
              else if(is_WrRd)  
              begin
                 prev_state <= ACK2_SLV;
                 state   <= STOP;
                 ack_err <= 0;
              end   
              
              else
                 state <=  WRITE_DATA;
              
            end
            
            // else go to stop and send ack_err
            else
            begin
              // state   <= STOP;
              ack_err <= 1;
            end
         
         end // }
         
         // stay in same state
         else
         begin
           state <= ACK2_SLV;
         end

       end // }


       
       /// WRITE_DATA
       WRITE_DATA:
       begin // {
       
          prev_state = WRITE_DATA;
          
          // for every write setting it as HIGH,
          writeIsPending = 1;

          // writing data to the slave
          if(dataCount <= 7)
          begin // {
             case(pulse)
             
             0:
             begin 
                m_scl_t <= 1'b0;
             end
             
             1:
             begin
               m_scl_t <= 1'b0;
               
               // shifting data out serially
//               m_sda_o <= sendData[7 - dataCount];
               m_sda_t <= dataReg[7 - dataCount];
             end
             
             2:
             begin
               m_scl_t <= 1'b1;
             end
             
             3:
             begin
               m_scl_t <= 1'b1;
             end
             
             endcase // pulse
             
             // increment the count, for a pulse
             if(count == clk_count1*4 -1)
             begin // {
                state     <= WRITE_DATA;
                m_scl_t   <= 1'b0;
                dataCount <= dataCount + 1'b1;
             end // }
             
             // while count dosen't completes stay in same state
             else
             begin
               state <= WRITE_DATA;
             end
          
          
          end  // }
          
          // after sending data, need to wait for slave to have acknowledgement
          else
          begin
            state     <= ACK3_SLV;
            dataCount <= 0;
          end
       
       end  // }
       
       
       
       /// READ_DATA
       READ_DATA:
       begin  // {
       
       // for every read transaction, setting it as high
       readIsPending = 1;
       
         if(dataCount <= 7)
         begin  // {
           case(pulse)
           
              0:
              begin
                m_scl_t <= 0;
                m_sda_t <= 1;
              end
              
              1:
              begin
                m_scl_t <= 1'b1;
                m_sda_t <= 1'b1;
              end
              
              2:
              begin
                m_scl_t <= 1'b1;
                m_sda_t <= 1'b1;
                
                // serially recv the data
                rx_data[7:0] <= (count == 12) ? {rx_data[6:0], m_sda_i} : rx_data;
//                  rx_data[dataCount] <= readReg[dataCount]; 
              end
              
              3:
              begin
                m_scl_t <= 1'b1;
                m_sda_t <= 1'b1;
              end
              
           endcase // pulse
           
           // increment the count after every pulse
           if(count == clk_count1*4 -1)
           begin
             state <= READ_DATA;
             m_scl_t <= 1'b0;
             dataCount <= dataCount + 1;
           end
           
           // after 7th clk valid data is present
//           else if(dataCount == 8)
//             validRdata <= 1'b1;
             
           // stay in same state
           else
           begin
             state <= READ_DATA;
             validRdata <= 1'b0;
           end 
         
         end    // }
         
         else
         begin
           state     <= MASTER_ACK;
           validRdata <= 1'b1;
           dataCount <= 0;
         end
       
       end  // }
 
       ////////////////////////////////////////////////////////
 //SCL //  /-------|--------|--------|----------------
       // /        |        |        |
               
 //SDA // /        |        |--------|---------------
       // /--------|--------|        |
       ////////////////////////////////////////////////////////       
       /// STOP
       STOP:
       begin
          case(pulse)
          
          0:
          begin
            m_scl_t <= 1'b0;
            m_sda_t <= 1'b0;
          end
          
          1:
          begin
            m_scl_t <= 1'b1;
            m_sda_t <= 1'b0;
          end
          
          2:
          begin
            m_scl_t <= 1'b1;
            m_sda_t <= 1'b1;
          end
          
          3:
          begin
            m_scl_t <= 1'b1;
            m_sda_t <= 1'b1;
          end
          
          
          endcase // pulse
          
          if(count == clk_count1*4 -1)
          begin // {
            if(prev_state == ACK2_SLV)
            begin
                state   <= START;
                m_scl_t <= 0;
                busy    <= 1'b1;
                done    <= 1'b0;
            end
            else
            begin
                state   <= IDLE;
                m_scl_t <= 0;
                busy    <= 1'b0;
                done    <= 1'b1;
            end
          end  // }
          
          else
            state <= STOP;
       end
       
       
       /// ACK3_SLV
       ACK3_SLV:
       begin
         case(pulse)
            0:
            begin
               m_scl_t <= 0;
               m_sda_t <= 1;
            end
            
            1:
            begin
               m_scl_t <= 0;
               m_sda_t <= 1;
            end
            
            2:
            begin
               m_scl_t <= 1;
               m_sda_t <= 1;
               rcv_ack <= m_sda_i; //receiving valid acknowledge // m_sda_in;
            end
            
            3:
            begin
              m_scl_t <= 1;
              m_sda_t <= 1;
            end
         
         endcase // pulse
         
         // wating for a pulse
         if(count == clk_count1*4 -1)
         begin // {
//            m_sda_t <= 0;
            
            // if correct acknlg recvd, send stop to slave
            if(rcv_ack == 0)
            begin
              state <= STOP;
              ack_err <= 0;
              
              // making LOW writeIsPending
              writeIsPending = 0;
            end
            
            // else go to stop and send ack_err
            else
            begin
              state <= STOP;
              ack_err <= 1;
            end
         
         end // }
         
         // stay in same state
         else
         begin
           state <= ACK3_SLV;
         end
       end
       
       
       /// MASTER_ACK
       MASTER_ACK:
       begin  // {
       
         // negative acknowledgement to the slave
         case(pulse)
           0:
           begin
             m_scl_t <= 1'b0;
             m_sda_t <= 1'b1;
           end
           
           1:
           begin
             m_scl_t <= 1'b0;
             m_sda_t <= 1'b1;
           end
           
           
           2:
           begin
           
             // setting readIsPending to low
             readIsPending <= 0;
             
             m_scl_t <= 1'b1;
             m_sda_t <= 1'b1;
           end
           
           3:
           begin
             m_scl_t <= 1'b1;
             m_sda_t <= 1'b1;
           end
           
         endcase // pulse
         
         if(count == clk_count1*4 -1)
         begin
            m_sda_t <= 1'b0;
            state   <= STOP;
            prev_state <= MASTER_ACK;
         end
         
         else
         begin
           state <= MASTER_ACK;
         
         end
       
       end  // }
       
   endcase // }
   
   end   // }

end  // }

// valid assign to rdata_out, when valid is HIGH
//assign rdata_out = (rdata_out_valid == 1) ? rx_data : 0;
assign PENDING_WR = (writeIsPending == 1) ? 1 : 0;
assign PENDING_RD = (readIsPending == 1)  ? 1 : 0;


assign m_sda_o    = m_sda_t;
assign scl_o      = m_scl_t;
assign rdata_out  = rx_data;
assign rdata_out_valid = validRdata;

assign sync_count = count;

endmodule : i2c_master
