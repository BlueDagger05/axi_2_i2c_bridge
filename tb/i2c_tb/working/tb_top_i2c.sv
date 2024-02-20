`timescale 1ns/1ps
module tb_top_i2c;
 
bit clk, resetn; 
logic [7:0] addr;
logic [7:0] din;
logic [6:0] slv_addr;
logic op_type;
logic  [7:0] dout;
logic  busy,ack_err;
logic  done;
logic I2C_trigger;

dummy_top dut
(
.clk(clk),
.resetn(resetn),
.addr(addr),
.din(din),
.slv_addr(slv_addr),
.op_type(op_type),
.I2C_trigger(I2C_trigger),
.dout(dout),
.busy(busy),
.ack_err(ack_err),
.done(done)
);
initial begin
I2C_trigger = 0;
#50 {addr, din, op_type, slv_addr} = 24'b00000001_00111010_01011101;
I2C_trigger = 1;
repeat(5) @(posedge clk);
I2C_trigger = 0;
#6us;
#50 {addr, din, op_type, slv_addr} = 24'b00000001_00111010_11011101;
I2C_trigger = 1;
repeat(5) @(posedge clk);
I2C_trigger = 0;
// =  $urandom_range(1,5);
// =  $urandom_range(1,5);

end 
always #5ns clk = ~clk;
 
initial begin
resetn = 0;
repeat(5) @(posedge clk);
resetn = 1;
repeat(5) @(posedge clk);

force dut.master.valid_addr_data_out = 1;
//#1 release dut.master.valid_addr_data_out;
//////////// write operation
 
//for(int i = 0; i < 10 ; i++)
begin
//newd = 1;
//op_type = 0;
//addr = $urandom_range(1,4);
//din  =  $urandom_range(1,5);
//slv_addr =  $urandom_range(1,5);
  repeat(5) @(posedge clk);
  
//  newd <= 1'b0;
@(posedge done);
$display("[WR] din : %0d addr: %0d",din, addr);
@(posedge clk);
 
end
 
////////////read operation
 
for(int i = 0; i < 10 ; i++)
begin
//newd = 1;
op_type  = 1;
addr = $urandom_range(1,4);
din = 0;
  repeat(5) @(posedge clk);
  
//  newd <= 1'b0;  
@(posedge done);
$display("[RD] dout : %0d addr: %0d",dout, addr);
@(posedge clk);
end
 
repeat(10) @(posedge clk);
$stop;
end
 
 
endmodule : tb_top_i2c