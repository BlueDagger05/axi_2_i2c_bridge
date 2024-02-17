class base_test extends uvm_test;
`uvm_component_utils(base_test)

function new(string name ="base_test", uvm_component parent = null);
	super.new(name, parent);
endfunction : new

env m_env;
axi_base_sequence axi_seq;

function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	
	// create environment
	m_env = env::type_id::create("m_env",this);

endfunction

task run_phase(uvm_phase phase);
    super.run_phase(phase);
	axi_seq = axi_base_sequence::type_id::create("axi_seq");
	phase.raise_objection(this);
	axi_seq.start(m_env.axi_agt.sqr);
	phase.drop_objection(this);
endtask


endclass : base_test
	