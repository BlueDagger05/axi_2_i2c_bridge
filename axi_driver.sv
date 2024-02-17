`ifndef DRIVER
`define DRIVER
class axi_driver extends uvm_driver#(axi_pkt);
  `uvm_component_utils(axi_driver)

// interface instance
//axi_slave_if axi_slave_if_inst;

// virtual interface
virtual axi_slave_if vif;

 function new(string name ="axi_driver", uvm_component parent = null);
	super.new(name, parent);
endfunction : new
  
/////////////////////////////////////////
// BUILD_PHASE
/////////////////////////////////////////

function void build_phase(uvm_phase phase);
	super.build_phase(phase);
		if(~uvm_config_db #(virtual axi_slave_if)::get(this, " ", "KEY", vif))
			`uvm_error(get_type_name(), "FAILED TO GET CONFIG_DB")
		else
			`uvm_info(get_type_name(), "SUCCESS WHILE FETCHING CONFIG_DB", UVM_LOW)
		
endfunction: build_phase
  
/////////////////////////////////////////
// CONNECT_PHASE
/////////////////////////////////////////

function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);
endfunction: connect_phase

/////////////////////////////////////////
//RUN_PHASE
/////////////////////////////////////////

virtual task run_phase(uvm_phase phase);
   super.run_phase(phase);
   forever 
   begin
	axi_pkt m_pkt;
	`uvm_info("DRV",$sformatf("wait for item from the sequencer"), UVM_HIGH)
	seq_item_port.get_next_item(m_pkt);
	drive_item(m_pkt);
	seq_item_port.item_done();
   end
endtask

virtual task drive_item (axi_pkt m_pkt);
	@(vif.ACLK);
	//vif.cb <= m_pkt;  
	vif.cb.AWVALID <= m_pkt.AWVALID;
	vif.cb.AWADDR  <= m_pkt.AWADDR;
	vif.cb.WVALID <= m_pkt.WVALID;
	vif.cb.WDATA  <= m_pkt.WDATA;
	vif.cb.BREADY <= m_pkt.BREADY;
	vif.cb.ARVALID <= m_pkt.ARVALID;
	vif.cb.ARADDR  <= m_pkt.ARADDR;
	vif.cb.RREADY <= m_pkt.RREADY;
	
endtask
endclass : axi_driver
`endif


  
 