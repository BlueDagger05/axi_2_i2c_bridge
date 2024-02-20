`timescale 1ns / 1ps

module level_conversion(
   input wire  clk, resetn,
   
   input wire [23:0] addr_data_out,

   
   input wire  valid_addr_data_out_i,
//   output logic valid_addr_data_out_o,
   
   input wire  I2C_trigger_i,
//   output logic I2C_trigger_o,
   
//   input   wire  valid_data_ack_i,
   output logic valid_data_ack_o,
   
//   input   wire valid_data_ack_valid_i,
   output logic valid_data_ack_valid_o,
   
//   input  wire rdata_out_valid_i,
   output logic rdata_out_valid_o,
   
//   input  wire  PENDING_WR_i,
   output logic PENDING_WR_o,
   
//   input wire PENDING_RD_i,
   output logic PENDING_RD_o,
   
   output logic [7:0] rdata_out
   
);

parameter sys_freq = 200000000; // 200 MHz
parameter i2c_freq = 100000; // 100 KHz 


parameter clk_count4 = (sys_freq/i2c_freq); //2000
parameter clk_count1 = clk_count4/4;        //500

// assign unique value to the transition of the pulse
reg [1:0] pulse;

// temporary clock
reg temp_clk;

// temporary valid_addr_data_out
reg valid_addr_data_out_t;
reg valid_addr_data_out_t1;
reg valid_addr_data_out_t2;

// temporary trigger
reg I2C_trigger_t;
reg I2C_trigger_t1;
reg I2C_trigger_t2;

// level2pulse
reg L2P_en;

int count = 0;
wire PENDING_WR_i;
wire PENDING_RD_i;

wire rdata_out_valid_i;
wire valid_data_ack_valid_i;
wire valid_data_ack_i;


wire s_sda_i;
wire s_sda_o;



always @(posedge clk, negedge resetn)
begin
  if(~resetn)
  begin
    pulse <= 0;
    count <= 0;
  end
  
  else
  begin // {
  
    // counts till 0 to 499
    if(count == clk_count1 -1)
    begin
        pulse <= 1;
        count <= count + 1;
    end
       
    // counts till 500 to 999   
    else if(count == 2*clk_count1 -1)
    begin
      pulse <= 2;
      count <= count + 1;
   end
   
   // counts till 1000 to 1499
   else if(count == 3*clk_count1 -1)
   begin
      pulse <= 3;
      count <= count + 1;
   end
   
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
   
   end // }
end   

always @(posedge clk)
begin
case(pulse)
         0: begin
               temp_clk <= 1'b1; 
               L2P_en   <= 1;
            end
            
         1: begin 
               temp_clk <= 1'b1;
               L2P_en   <= 1;
            end
            
         2: begin 
               temp_clk <= 1'b0;
               L2P_en   <= 0;
                
            end
            
         3: begin
               temp_clk <= 1'b0;
               L2P_en   <= 0; 
            end
            
         endcase
end

always @(posedge L2P_en, negedge resetn)
begin
if(~resetn)
begin
  {valid_addr_data_out_t, valid_addr_data_out_t1, valid_addr_data_out_t2} <=0;
  {I2C_trigger_t, I2C_trigger_t2, I2C_trigger_t1} <= 0;
end

else begin
  I2C_trigger_t         <= (I2C_trigger_i & (~I2C_trigger_t));
  {I2C_trigger_t2, I2C_trigger_t1} <= {I2C_trigger_t1, I2C_trigger_t};
  
  valid_addr_data_out_t <= (valid_addr_data_out_i & (~valid_addr_data_out_t));
  {valid_addr_data_out_t2, valid_addr_data_out_t1} <= {valid_addr_data_out_t1, valid_addr_data_out_t};
end
end

always @(posedge L2P_en, negedge resetn)
begin
  if(~resetn)
  begin
     PENDING_WR_o <= 0; 
     PENDING_RD_o <= 0; 
     rdata_out_valid_o <= 0;
     valid_data_ack_o <= 0;
     valid_data_ack_valid_o <= 0;
  end
  
  else
  begin
     PENDING_RD_o <= PENDING_RD_i ^ PENDING_RD_o;
     PENDING_WR_o <= PENDING_WR_i ^ PENDING_WR_o;
     rdata_out_valid_o      <= rdata_out_valid_i ^ rdata_out_valid_o;
     valid_data_ack_o       <= valid_data_ack_i ^ valid_data_ack_o; 
     valid_data_ack_valid_o <= valid_data_ack_valid_i ^ valid_data_ack_valid_o; 
  end

end

wire scl_o;
wire busy;
wire ack_errs, ack_errm;
wire done;

i2c_master UUT (
//   .addr_data_out(),
   .clk(clk),
   .resetn(resetn),
   .addr_data_out(addr_data_out),
   .valid_addr_data_out(valid_addr_data_out_t2),
   .I2C_trigger(I2C_trigger_t2),
   .valid_data_ack(valid_data_ack_i),
   .valid_data_ack_valid(valid_data_ack_valid_i),
   .rdata_out_valid(rdata_out_valid_i),
   .PENDING_WR(PENDING_WR_i),
   .PENDING_RD(PENDING_RD_i),
   .scl_o(scl_o),
//   .m_sda_i(s_sda_o),
//   .m_sda_o(s_sda_i),
   .rdata_out(rdata_out),
   .ack_err(ack_errm)
);

i2c_slave UUT1 (
.scl(scl_o),
.resetn(resetn),
.clk(clk),
.s_sda_i(s_sda_i),
.s_sda_o(s_sda_o),
.ack_err(ack_errs)
);

endmodule
