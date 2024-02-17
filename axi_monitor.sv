class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)  
	
function new(string name="axi_monitor", uvm_component parent=null);
    super.new(name, parent);
endfunction

uvm_analysis_port#(axi_pkt) axi_monitor_analysis_port;

virtual axi_slave_if vif;

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Get handle to interface instance
        if (!uvm_config_db #(virtual axi_slave_if)::get(this, "", "KEY",vif))
        `uvm_fatal("NOAXIIF", "Could not get axi_if instance")
		axi_monitor_analysis_port = new("axi_monitor_analysis_port",this);
 endfunction


virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
	$display("message from monitor");
	
	forever
	begin
		
		@(posedge vif.ACLK);
		
		
		if((vif.AWREADY && vif.AWVALID) || (vif.WREADY && vif.WVALID) ||(vif.ARREADY && vif.ARVALID) ||(vif.RVALID && vif.RREADY)||(vif.BRESP && vif.BVALID)) 
		begin
		
		    axi_pkt item = axi_pkt::type_id::create("item");
			item.AWREADY = vif.AWREADY;
			item.AWVALID = vif.AWVALID;
			item.AWADDR = vif.AWADDR;
			item.WREADY = vif.WREADY;
			item.WVALID = vif.WVALID;
			item.WDATA = vif.WDATA;
			item.BRESP = vif.BRESP;
			item.BVALID = vif.BVALID;
			item.BREADY = vif.BREADY;
			item.ARREADY = vif.ARREADY;
			item.ARVALID = vif.ARVALID;
			item.ARADDR = vif.ARADDR;
			item.RRESP = vif.RRESP;
			item.RDATA = vif.RDATA;
			item.RVALID = vif.RVALID;
			item.RREADY = vif.RREADY;
				$display("message from monitor 1");
			`uvm_info("NOAXIIF",$sformatf("saw item %p",item),UVM_LOW)
			
			axi_monitor_analysis_port.write(item);
		end
		$display("message from monitor 1");
	end
endtask
endclass : axi_monitor
 