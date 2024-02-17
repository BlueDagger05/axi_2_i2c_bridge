`ifndef BSEQ
`define BSEQ	
class axi_base_sequence extends uvm_sequence #(axi_pkt);
	`uvm_object_utils(axi_base_sequence)

function new(string name = "axi_base_sequence");
	super.new(name);
endfunction

virtual task body();
        // Define your transaction here
        axi_pkt m_pkt;
        //to write a  transaction
		
        m_pkt = new();
		start_item(m_pkt);
        m_pkt.AWADDR = 32'h1234;
        m_pkt.WDATA = 32'hABCD;
		m_pkt.AWVALID = 1'b1;
		finish_item(m_pkt);
        
    endtask

endclass: axi_base_sequence
`endif
  
  

