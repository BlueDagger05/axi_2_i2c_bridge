`ifndef AGT
`define AGT
class agent extends uvm_agent;
   `uvm_component_utils(agent)


   // class instancesa
   sequencer sqr;
   driver    drv;
   
   // monitor   mon;

/////////////////////////////////////////
// NEW
/////////////////////////////////////////
   function new(string name = "agent", uvm_component parent = null);
	   super.new(name, parent);
   endfunction : new

   
/////////////////////////////////////////
// BUILD_PHASE
/////////////////////////////////////////
   function void build_phase (uvm_phase phase);
	   super.build_phase(phase);
	   if(get_is_active == UVM_ACTIVE)
	   begin
	   drv = driver::type_id::create("drv", this);
	   sqr = sequencer::type_id::create("sqr", this);

   end
   endfunction : build_phase

   




endclass : agent
`endif
