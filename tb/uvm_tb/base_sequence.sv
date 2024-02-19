`ifndef BSEQ
`define BSEQ
class base_sequence extends uvm_sequence#(pkt);
  `uvm_object_utils(base_sequence)

  function new(string name = "base_sequence")
	  super.new(name);
  endfunction : new

  task body();
	  `uvm_info(get_full_name(), "Body of sequene", UVM_HIGH)
	  `uvm_do(pkt)
  endtask : body 

endclass : base_sequence
`endif
