class env extends uvm_env;
	`uvm_component_utils(env)
	
function new(string name ="env",uvm_component parent = null );
	super.new(name,parent);
endfunction

axi_agent  axi_agt;
scoreboard scb;

virtual function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	axi_agt = axi_agent::type_id::create("axi_agt",this);
	scb = scoreboard::type_id::create("scb",this);
endfunction

virtual function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	axi_agt.mon.axi_monitor_analysis_port.connect(scb.m_axi_analysis_imp);
endfunction

endclass : env