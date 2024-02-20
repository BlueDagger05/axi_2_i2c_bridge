`timescale 1ns / 1ps

module top_i2c_master_slave(
input clk, resetn, 
input [7:0] addr,
input [7:0] din,
input [6:0] slv_addr,
input op_type,
input I2C_trigger,
output [7:0] dout,
output busy,ack_err,
output done
);

wire sda, scl;
wire m_sda_o, s_sda_o;
wire ack_errm, ack_errs;
wire handshake;
wire slv_handshake;
wire [9:0] sync_count;
wire valid_addr_data_out;

i2c_master master (
.clk(clk),
.resetn(resetn),
.I2C_trigger(I2C_trigger),
.addr_data_out({din, addr, op_type, slv_addr}),
.m_sda_i(sda),
.m_sda_o(m_sda_o),
.scl_o(scl),
.slave_handshake(handshake),
.sync_count(sync_count),
.ack_err(ack_errm),
.valid_addr_data_out(valid_addr_data_out),
.done(done));


//i2c_slave slave(
//.clk(clk),
//.resetn(resetn),
//.scl(scl),
//.s_sda_i(sda_o),
//.s_sda_o(sda_i),
//.slave_handshake(handshake),
//.sync_count(sync_count),
//.ack_err(ack_errs));

assign sda = m_sda_o & s_sda_o;

i2c_slave slave(
.SCL(scl),
.SDA_i(sda),
.SDA_o(s_sda_o),
.RST(~resetn)
);

assign ack_err = ack_errs | ack_errm;

endmodule : top_i2c_master_slave
