`ifndef DRV
`define DRV
class driver extends uvm_driver #(pkt);
  `uvm_component_utils(driver)

  // pkt class handle
  pkt pkt_handler;

  // virtual interface
  virtual i2c_ifc vif;


// analysis port
  uvm_analysis_port #(pkt) port;

// number of transactions
  int numofPackets = 1;

/////////////////////////////////////////
// NEW
/////////////////////////////////////////
  function new(string name = "driver", uvm_component parent = null);
	  super.new(name, parent);
  endfunction : new



/////////////////////////////////////////
// BUILD_PHASE
/////////////////////////////////////////
  function void build_phase(uvm_phase phase);
	  super.build_phase(phase);

	  port = new("port", this);

	  if((~uvm_config_db #(virtual i2c_ifc) ::get(this, "", "KEY", vif))
		  `uvm_error(get_type_name(), "Failed to get config db")
	  else
		  `uvm_info(get_type_name(), "Success while fetching config db", UVM_HIGH)

	  if(~(uvm_config_db #(int) ::get(this, "", "PKT", numofPackets)) )
		  `uvm_error(get_type_name(), "Failed to get numofPacket")
	  else
		  `uvm_info(get_type_name(), $sformatf("Recvd pkts :: setting pkt value to %0d", numofPackets), UVM_LOW)
  endfunction : build_phase


/////////////////////////////////////////
// tasks and functions
/////////////////////////////////////////
  extern task send_tr();


/////////////////////////////////////////
// RUN PHASE
/////////////////////////////////////////
  task run_phase (uvm_phase phase);
	  super.run_phase(phase);
	  seq_item_port.get_next_item(pkt_handler);

	  send_tr();

	  seq_item_port.item_done();
  endtask : run_phase
endclass : driver

// send_tr
  task driver :: send_tr();
	  $display(" Initiatin transaction...");
  endtask : send_tr


`endif
