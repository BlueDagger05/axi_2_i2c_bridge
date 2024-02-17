`ifndef SCOREBOARD
`define SCOREBOARD
class scoreboard extends uvm_scoreboard;

	`uvm_component_utils(scoreboard)
	
function new(string name = "scoreboard",uvm_component parent = null);
	super.new(name,parent);
endfunction
axi_pkt axi_q[$];

uvm_analysis_imp #(axi_pkt,scoreboard) m_axi_analysis_imp;
	
virtual function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	m_axi_analysis_imp = new("m_axi_analysis_imp",this);
endfunction
	
function void  write(axi_pkt m_axi_pkt);
	axi_q.push_back(m_axi_pkt);
endfunction 
endclass :  scoreboard

`endif