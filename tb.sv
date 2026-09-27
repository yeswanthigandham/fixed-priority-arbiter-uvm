// Code your testbench here
// or browse Examples
package tb_top;


  import uvm_pkg::*;
  `include "uvm_macros.svh"

class seq_item extends uvm_sequence_item;
  `uvm_object_utils(seq_item)
  rand bit [3:0]req;
  bit [3:0]gnt;
  function new(string name="seq_item");
    super.new(name);
  endfunction
               
  constraint req_gen{
    req inside {[0:15]};  
  }
endclass

class seq extends uvm_sequence#(seq_item);  
  `uvm_object_utils(seq)
   seq_item seq_item1;
  function new(string name="seq");
    super.new(name);
  endfunction
  rand int rep;
  constraint num{
    rep inside {[10:50]};
  }
  virtual task body();
    this.randomize();
   
    repeat(rep) begin
      seq_item1=seq_item::type_id::create("seq_item1");
      start_item(seq_item1);
      assert(seq_item1.randomize());
      finish_item(seq_item1);
                                          
    end
  endtask
endclass

class seqr extends uvm_sequencer#(seq_item);
  `uvm_component_utils(seqr)
  function new(string name="seqr",uvm_component parent);
    super.new(name,parent);
  endfunction

endclass

class driver extends uvm_driver#(seq_item);
  `uvm_component_utils(driver)
  virtual intf vif;
  function new(string name="driver",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual intf)::get(this,"","vif",vif))
      `uvm_fatal("driver","failed to get virtual intf");
  endfunction
  
  task run_phase(uvm_phase phase);
    seq_item seq_item1;
    wait(!vif.rst);
    @(posedge vif.clk);
    
    forever begin//{
      
      
      seq_item_port.get_next_item(seq_item1);
      
      //@(posedge vif.clk);
      vif.req<=seq_item1.req;
      @(posedge vif.clk);
      seq_item_port.item_done();
      
    end //}
  endtask

endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  virtual intf vif;
  uvm_analysis_port#(seq_item) a_port;
  function new(string name="monitor",uvm_component parent);
    super.new(name,parent);
    a_port=new("a_port",this);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual intf)::get(this,"","vif",vif))
      `uvm_fatal("MONITOR","Failed to get virtual intf");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    seq_item seq_item1;
    wait(!vif.rst);
    forever begin
      seq_item1=seq_item::type_id::create("seq_item1");
      @(posedge vif.clk);
      if(!vif.rst) begin
      seq_item1.req=vif.req;
      seq_item1.gnt=vif.gnt;
       // @(posedge vif.clk);
        
      a_port.write(seq_item1);
      end
    end
  endtask
endclass
  
class agent extends uvm_agent;
  `uvm_component_utils(agent)
  seqr seqr1;
  driver driver1;
  monitor monitor1;
  function new(string name="agent",uvm_component parent);
    super.new(name,parent);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(get_is_active()==UVM_ACTIVE)
      begin
        seqr1=seqr::type_id::create("seqr1",this);
        driver1=driver::type_id::create("driver1",this);
      end
    monitor1=monitor::type_id::create("monitor1",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active()==UVM_ACTIVE)
      begin
        driver1.seq_item_port.connect(seqr1.seq_item_export);
      end
    
  endfunction
  
endclass

class scbd extends uvm_scoreboard;
  `uvm_component_utils(scbd)
  uvm_analysis_imp#(seq_item,scbd) a_imp;
  bit [3:0]expected_gnt,prev_req;
  
  function new(string name="scbd",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a_imp=new("a_imp",this);
  endfunction
  

  
  virtual function void write(seq_item seq_item1);
    
    
    // Clear previous expected value
    expected_gnt = 4'b0000;
    //expected_gnt = expected_next_gnt;
        // req[0] has highest priority
    for (int i = 0; i < 4; i++) begin
      if (prev_req[i]) begin
        expected_gnt[i] = 1'b1;
        break;
      end
    end

    if (expected_gnt == seq_item1.gnt) begin
      `uvm_info("SCOREBOARD", $sformatf( "PASS: req=%04b expected=%04b actual=%04b",seq_item1.req,expected_gnt,seq_item1.gnt), UVM_LOW)
    end
    else begin
      `uvm_error( "SCOREBOARD", $sformatf( "FAIL: req=%04b expected=%04b actual=%04b", seq_item1.req,  expected_gnt, seq_item1.gnt) )
    end
    prev_req=seq_item1.req;
    
  endfunction
endclass

//coverage check

class coverage extends uvm_subscriber#(seq_item);
  `uvm_component_utils(coverage)
  seq_item seq_item1;
  
  covergroup cg;
    //coverpoint seq_item1.rst;
    req_cp: coverpoint seq_item1.req;
    gnt_cp: coverpoint seq_item1.gnt {
      bins nognt = {4'b0};
      bins gnt0 = {4'b1};
      bins gnt1 = {4'b10};
      bins gnt2 = {4'b100};
      bins gnt3 = {4'b1000};
    }
  endgroup

    function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  // Required write implementation
  virtual function void write(seq_item s1);
    seq_item1 = s1;
    cg.sample();
  endfunction
  
  function void report_phase(uvm_phase phase);
  super.report_phase(phase);

  `uvm_info("COVERAGE",
            $sformatf("Overall Functional Coverage = %0.2f%%",
              cg.get_coverage()),
    UVM_NONE)
    
    
  `uvm_info("COVERAGE",
            $sformatf("Req Functional Coverage = %0.2f%%",
              cg.req_cp.get_coverage()),
    UVM_NONE)
    
    
  `uvm_info("COVERAGE",
            $sformatf("Gnt Functional Coverage = %0.2f%%",
              cg.gnt_cp.get_coverage()),
    UVM_NONE)
endfunction
  
endclass
    
class env extends uvm_env;
  `uvm_component_utils(env)
  scbd scbd1;
  agent agent1;
  coverage coverage1;
  function new(string name="env",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scbd1=scbd::type_id::create("scbd1",this);
    agent1=agent::type_id::create("agent1",this);
    coverage1=coverage::type_id::create("coverage1",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent1.monitor1.a_port.connect(scbd1.a_imp);
    agent1.monitor1.a_port.connect(coverage1.analysis_export);
  endfunction
  
endclass

class basic_test extends uvm_test;
  `uvm_component_utils(basic_test)
  env env1;
  seq seq1;
  function new(string name="basic_test",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env1=env::type_id::create("env1",this);
  endfunction
  
  task run_phase(uvm_phase phase);
    seq seq1;
    
    phase.raise_objection(this);
    seq1=seq::type_id::create("seq1");
    seq1.start(env1.agent1.seqr1);
    phase.drop_objection(this);
  endtask
  
endclass

endpackage

module top;
 logic clk;

  // ACTUAL interface instance
  intf vif(clk);


  fixed_priority_arb dut_inst (.clk(clk), .rst(vif.rst), .req(vif.req), .gnt(vif.gnt) );
 initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
 initial begin

    vif.rst = 1;
    vif.req = 4'b0000;

   repeat (3)
      @(posedge clk);

    vif.rst = 0;

  end
  
  bind fixed_priority_arb assertion_chk assert_inst ( .clk(clk), .rst(rst), .req(req),.gnt(gnt) );

  initial begin
    //set virtual intf in config_db
    uvm_config_db#(virtual intf)::set(null,"*","vif",vif);
    //run_test()
    run_test("basic_test");
  end
  
  initial begin
  $dumpfile("dump.vcd");
  $dumpvars(0, top);
end
  
endmodule
