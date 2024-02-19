`include "defines.sv"
class pkt extends uvm_sequence_item;
 
////////////////////////////////
// data fields
////////////////////////////////

  randc bit                    I2C_MASTER_TRIGGER;
  randc bit [`DATA_WIDTH -1:0] ADDR_DATA_OUT;
  randc bit                    VALID_ADDR_DATA_OUT;
  randc bit                    RDATA_VALID_ACK;
  
 ////////////////////////////////
 // Constraints
 ////////////////////////////////
  constraint set_adr_c   {ADDR_DATA_OUT inside {[20'h4:20'h5]} ;} 

  constraint valid_addr_c {ADDR_DATA_OUT == 20'h41234 -> VALID_ADDR_DATA_OUT == 1;}

////////////////////////////////
// CTOR and registering 
// it to the factory
////////////////////////////////


 `uvm_object_utils_begin(pkt)
 `uvm_field_int(I2C_MASTER_TRIGGER,  | UVM_ALL_ON | UVM_DEFAULT)
 `uvm_field_int(ADDR_DATA_OUT,       | UVM_ALL_ON | UVM_DEFAULT)
 `uvm_field_int(VALID_ADDR_DATA_OUT, | UVM_ALL_ON | UVM_DEFAULT)
 `uvm_field_int(RDATA_VALID_ACK,     | UVM_ALL_ON | UVM_DEFAULT)
 `uvm_object_utils_end

  function new (string name = "pkt");
	  super.new(name);
  endfunction : new

endclass: pkt
