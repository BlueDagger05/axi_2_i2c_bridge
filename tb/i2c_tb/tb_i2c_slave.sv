`timescale 1ns / 1ps

module tb_i2c_slave();

	bit SCL;
	bit RESETn;
	
    logic s_sda_i;
    logic s_sda_o;
    logic s_sda_o_en;
    
i2c_slave_memory DUT (.SCL(SCL),
                      .RESETn(RESETn),
                      .s_sda_i(s_sda_i),
                      .s_sda_o(s_sda_o),
                      .s_sda_o_en(s_sda_o_en));

reg [7:0] temp_data ;


pullup(SCL);
pullup(s_sda_i);
pullup(s_sda_o);


reg [6:0] sendAddress = 7'h10B;
reg [7:0] sendData = 7'h10A;
reg is_wr_rd = 1; // write operation

bit clk;

// initial
initial begin
   #10 RESETn = 1;
end

initial begin
   force SCL = clk;
   forever #10 clk = ~clk;
end

// tasks and functions
task only_wr();
       force s_sda_i = 1;
   #10 force s_sda_i = 1;

      for(int i = i; i<7; i++)
      begin
         #10 force s_sda_i = sendAddress[i];
      end
         #10 force s_sda_i = 0;
endtask : only_wr

initial only_wr();

// final
initial #1000 $finish;

endmodule
