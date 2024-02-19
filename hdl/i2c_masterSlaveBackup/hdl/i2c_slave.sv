`timescale 1ns / 1ps


module i2c_slave(
// AXI signals
input wire scl,
input wire clk,
input wire resetn,
input wire s_sda_i,
output logic s_sda_o,
output logic ack_err
//output logic  done
);
endmodule
