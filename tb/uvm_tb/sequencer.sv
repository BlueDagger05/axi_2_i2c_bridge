`ifndef SEQR
`define SEQR

class sequencer extends uvm_sequencer #(pkt);

	function new(string name = "sequencer", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new


	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		`uvm_info(get_type_name(), "Building Sequencer ...", UVM_HIGH)
	endfunction : build_phase

endclass : sequencer
`endif

