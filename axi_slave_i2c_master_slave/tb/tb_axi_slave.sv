`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.02.2024 02:14:54
// Design Name: 
// Module Name: tb_axi_slave
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

module tb_axi_slave;
    
    ////////////////////////////////////
	// Global clock and active-low reset
    ////////////////////////////////////
	bit ACLK;
	bit ARESETn;

	////////////////////////////////
	// Write channel signals
	////////////////////////////////
	
	// Write Request channel signals
	logic                    AWREADY;
	logic                    AWVALID;
	logic [`ADDR_WIDTH -1:0] AWADDR;

	// Write Data channel signals
	logic                    WREADY;
	logic                    WVALID;
	logic [`DATA_WIDTH -1:0] WDATA;

	// Write Response channel signals
	logic [`RESPONSE_WIDTH-1:0] BRESP;
	logic                       BVALID;
	logic                       BREADY;
    
    /////////////////////////////////
    // Read channel signals
    /////////////////////////////////

	// Read Address channel signals (AR)
	logic ARREADY;
	logic ARVALID;
	logic [`ADDR_WIDTH -1:0] ARADDR;
	
	// Read Data channel signals (R)
	logic [`RESPONSE_WIDTH -1:0] RRESP;
	logic [`RDATA_WIDTH -1:0] RDATA;
	logic RVALID;
	logic RREADY;

    /////////////////////////////////
    // AXI slave to I2C master Write signals
	/////////////////////////////////
	logic [`OUTPUT_ADDR_WIDTH -1:0] ADDR_DATA_OUT;
	logic VALID_ADDR_DATA_OUT;
    logic VALID_ADDR_DATA_OUT_ACK;
    logic VALID_ADDR_DATA_OUT_ACK_VALID;

    // AXI slave to I2C master Read signals
    logic RDATA_VALID_ACK;
	logic I2C_MASTER_TRIGGER;

	logic [`RDATA_WIDTH -1:0] RDATA_OUT;
	logic RDATA_VALID;

	logic PENDING_TRANSACTION_WR;
	logic PENDING_TRANSACTION_RD;

// Instantiate AXI Slave
axi_slave DUT(
            .ACLK(ACLK),
            .ARESETn(ARESETn),
            .AWREADY(AWREADY),
            .AWVALID(AWVALID),
            .AWADDR(AWADDR),
            .WREADY(WREADY),
            .WVALID(WVALID),
            .WDATA(WDATA),
            .BRESP(BRESP),
            .BVALID(BVALID),
            .BREADY(BREADY),
            .ARREADY(ARREADY),
            .ARVALID(ARVALID),
            .ARADDR(ARADDR),
            .RRESP(RRESP),
            .RDATA(RDATA),
            .RVALID(RVALID),
            .RREADY(RREADY),
            .ADDR_DATA_OUT(ADDR_DATA_OUT),
            .VALID_ADDR_DATA_OUT(VALID_ADDR_DATA_OUT),
            .VALID_ADDR_DATA_OUT_ACK(VALID_ADDR_DATA_OUT_ACK),
            .VALID_ADDR_DATA_OUT_ACK_VALID(VALID_ADDR_DATA_OUT_ACK_VALID),
            .RDATA_VALID_ACK(RDATA_VALID_ACK),
            .I2C_MASTER_TRIGGER(I2C_MASTER_TRIGGER),
            .RDATA_OUT(RDATA_OUT),
            .RDATA_VALID(RDATA_VALID),
            .PENDING_TRANSACTION_WR(PENDING_TRANSACTION_WR),
            .PENDING_TRANSACTION_RD(PENDING_TRANSACTION_RD)
);

// Clock Generation
initial 
begin
    ACLK = 0;
    forever #5 ACLK = ~ACLK;
end

// Reset Generation
initial 
begin
    ARESETn = 0;
#10 ARESETn = 1;
end

initial 
fork
    wait(ARESETn) @(posedge ACLK) write_addrress();
    wait(ARESETn) @(posedge ACLK) write_data();
    wait(ARESETn) @(posedge ACLK) write_resp();
    wait(ARESETn) @(posedge ACLK) i2c_handshake();
    wait(ARESETn)@(posedge ACLK) read_address();
    wait(ARESETn)@(posedge ACLK) read_data();
    wait(ARESETn)@(posedge ACLK) read_actual_data();
join

task write_addrress();
begin
   #10 AWADDR = 32'h1234_0001;
       AWVALID = 1;

   #20 AWVALID = 0;
   
   repeat(5) @(posedge ACLK);
   
   #10 AWADDR = 32'h1234_AA1D;
       AWVALID = 1;

   #20 AWVALID = 0;
   
   repeat(5) @(posedge ACLK);
   
   #10 AWADDR = 32'h1233_0001;
       AWVALID = 1;

   #20 AWVALID = 0;
   
   repeat(5) @(posedge ACLK);
   #10 AWADDR = 32'h1233_0002;
       AWVALID = 1;

   #20 AWVALID = 0;
   repeat(5) @(posedge ACLK);
 end  
       
endtask : write_addrress

task write_data();
   #40 WDATA = 32'h1;
       WVALID = 1;

   #20 WVALID = 0;   
   repeat(5) @(posedge ACLK);
     
   
    #40 WDATA = 32'h2;
       WVALID = 1;

   #20 WVALID = 0;
   repeat(5) @(posedge ACLK);
   
    #40 WDATA = 32'h3;
        WVALID = 1;

   #20 WVALID = 0;
   repeat(5) @(posedge ACLK);       
   
   
    #40 WDATA = 32'h4;
       WVALID = 1; 
       

   #20 WVALID = 0;
   repeat(5) @(posedge ACLK);
   
    #40 WDATA = 32'h5;
       WVALID = 1;

   #20 WVALID = 0;
   repeat(5) @(posedge ACLK);
      
endtask : write_data


task write_resp();
	#70 BREADY = 1;
endtask : write_resp


task i2c_handshake();
         VALID_ADDR_DATA_OUT_ACK       = 0;
         VALID_ADDR_DATA_OUT_ACK_VALID = 0;
         PENDING_TRANSACTION_WR        = 0;
         
    #100 VALID_ADDR_DATA_OUT_ACK       = 1;
         VALID_ADDR_DATA_OUT_ACK_VALID = 1;
         PENDING_TRANSACTION_WR        = 1;
         
    #20 VALID_ADDR_DATA_OUT_ACK        = 0;
         VALID_ADDR_DATA_OUT_ACK_VALID = 0;
         PENDING_TRANSACTION_WR        = 0;
    

endtask : i2c_handshake


task read_address();
begin
#10 ARADDR = 32'h0000_0002;
       ARVALID = 1;

   #20 ARVALID = 0;
   
   repeat(5) @(posedge ACLK);
   
   #10 ARADDR = 32'h0000_AA1D;
       ARVALID = 1;

   #20 ARVALID = 0;
   
   repeat(5) @(posedge ACLK);
   
   #10 ARADDR = 32'h0000_0001;
       ARVALID = 1;

   #20 ARVALID = 0;
   
   repeat(5) @(posedge ACLK);
   #10 ARADDR = 32'h0000_0002;
       ARVALID = 1;

   #20 ARVALID = 0;
   repeat(5) @(posedge ACLK);
 end  
endtask

task read_data();
begin

#40 RDATA_OUT = 8'hA;
       RREADY = 1;

   #20 RREADY = 0;   
   repeat(5) @(posedge ACLK);
     
   
    #40 RDATA_OUT = 8'hB;
       RREADY = 1;

   #20 RREADY = 0;
   repeat(5) @(posedge ACLK);
   
    #40 RDATA_OUT = 8'hC;
        RREADY = 1;

   #20 RREADY = 0;
   repeat(5) @(posedge ACLK);       
   
   
    #40 RDATA_OUT = 8'hA;
       RREADY = 1; 
       

   #20 RREADY = 0;
   repeat(5) @(posedge ACLK);
   
    #40 RDATA_OUT = 8'hB;
       RREADY = 1;

   #20 RREADY = 0;
   repeat(5) @(posedge ACLK);

end
endtask

task read_actual_data();
begin
    PENDING_TRANSACTION_RD = 0;
    RDATA_VALID            = 0;
    RDATA_VALID            = 0; 
 
#50   
    PENDING_TRANSACTION_RD = 1;
    RDATA_VALID            = 1;
    RDATA_VALID            = 1; 
    
#300   
    PENDING_TRANSACTION_RD = 0;
    RDATA_VALID            = 0;
    RDATA_VALID            = 0;     

end
endtask



//// Monitor
//always @(posedge ACLK) begin
//    // Display relevant signals
//    $display("Time=%0t ARADDR=%h RDATA=%h RRESP=%h RVALID=%0d RREADY=%0d",
//             $time, ARADDR, RDATA, RRESP, RVALID, RREADY);
//  end

// Wait for simulation to finish
initial
begin
    #2000;
    $finish;
end

endmodule: tb_axi_slave

