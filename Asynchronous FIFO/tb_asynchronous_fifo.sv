`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.02.2024 10:42:25
// Design Name: 
// Module Name: tb_asynchronous_fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_asynchronous_fifo();

parameter DATASIZE = 8;
parameter ADDRSIZE = 4;

// Define Signals
logic  wr_en, wr_clk, wrst_n;
logic  rd_en, rd_clk, rrst_n;
logic wr_full;
logic rempty;

logic [DATASIZE-1:0] wdata;
logic [DATASIZE-1:0] rdata;
logic [DATASIZE-1:0] ref_data_q[$];
logic [DATASIZE-1:0] temp_data;

// Instantiate the Asynchronous fifo
asynchronous_fifo DUT(.wr_en(wr_en),
                      .wr_clk(wr_clk),
                      .wrst_n(wrst_n),
                      .rd_en(rd_en),
                      .rd_clk(rd_clk),
                      .rrst_n(rrst_n),
                      .wr_full(wr_full),
                      .rempty(rempty),
                      .wdata(wdata),
                      .rdata(rdata)
                      );

// Clock generators
always #1 wr_clk = ~wr_clk;
always #1 rd_clk = ~rd_clk;
initial
begin
    wr_clk = 'b0;
    rd_clk = 'b0;
end

// write process 
initial
begin
wr_en = 1'b0;
wdata = 1'b0;
wrst_n = 1'b0;
repeat(5) @(posedge wr_clk);
wrst_n = 1'b1;

// write the data to fifo
for(int i=0;i<2;i++)
begin
    
    for(int j=0;j<32;j++)
    begin
        @(posedge wr_clk);
        wr_en = (i % 2 == 0) && (ref_data_q.size()!= 16);
        $display("ref_data_q.size = %0d",ref_data_q.size());
        $monitor("time = %t,write enable = %0h",$time,wr_en);
        if (wr_en && !wr_full)
        @(negedge wr_clk);
            begin
            wdata = $urandom;
            // Store expected data for verification
            ref_data_q.push_back(wdata);
            $display("Writing data: %h", wdata);
            end
   #1ps;
   end

end
end

// read process
initial 
begin
    rd_en = 1'b0;
    rrst_n = 1'b0;
    repeat(5) @(posedge rd_clk);
    rrst_n = 1'b1;
    
    // read the data from the fifo and verify
    @(negedge rempty);
    begin
        for(int i=0; i<32;i++)
            begin
                @(posedge rd_clk);
                rd_en = (i % 2 == 0) && (ref_data_q.size()!= 0);
                $display("read_ref_data_q.size = %0d",ref_data_q.size());
                $monitor("time = %t,read enable = %0h",$time,rd_en);
                if(rd_en)
                begin
                    temp_data = ref_data_q.pop_front(); 
                    assert(rdata == temp_data)
                    else
                    $error("data mismatch: wdata = %h,rdata = %h",temp_data,rdata);
                end
                // monitor the signals
                 $monitor("At time %0t: wdata = %h, rdata = %h", $time, temp_data, rdata);
            end
    end

#30ns $finish();
end
endmodule
