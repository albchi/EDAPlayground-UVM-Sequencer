/*

  A simple example of UVM creating sequences.
  
  Here is the basic UVM class hierachy:
  
     Pkt
     Testcase
        Sequence
        Environment
          Agent
             Sequencer
	     Driver

   Run log:
   
     Start of UVM - hardwired message 
     addr                         integral  32    'hdeadbeef                                         
     addr                         integral  32    'hcafefade                                         
     addr                         integral  32    'h1234                                             
     addr                         integral  32    'habcd 
     $finish called from file "/apps/vcsmx/vcs/U-2023.03-SP2//etc/uvm-1.1/src/base/uvm_root.svh", line 437.
     $finish at simulation time                 3048

*/

import uvm_pkg::*;


class Pkt extends uvm_sequence_item;
  
  
  rand reg [31:0] addr;
  rand reg [31:0] data;
  rand reg [3:0] cmd;
  rand reg rw_;
  
  `uvm_object_utils_begin(Pkt)
     `uvm_field_int(addr, UVM_DEFAULT)
     `uvm_field_int(data, UVM_DEFAULT)
     `uvm_field_int(cmd, UVM_DEFAULT)
     `uvm_field_int(rw_, UVM_DEFAULT)
  `uvm_object_utils_end

endclass



class Seq_Pkt extends uvm_sequence #(Pkt);

    `uvm_object_utils(Seq_Pkt)

    virtual task body();

          `uvm_info("XAC", "SEQ_PKT::body(), going to do uvm_do_with for the 1st time", UVM_HIGH);

	      `uvm_do_with(req, {addr == 32'hdeadbeef;})
	      `uvm_do_with(req, {addr == 32'hcafefade;})

           req = Pkt::type_id::create("req");
           start_item(req);
           req.cmd = 4;
           req.addr = 32'h1234;
           finish_item(req);

           req = Pkt::type_id::create("req");
           start_item(req);
           req.cmd = 4;
           req.addr = 32'habcd;
           finish_item(req);

    endtask

    virtual task pre_start();
       `uvm_info("XAC", "seq_pkt::pre_start", UVM_HIGH);
        if ( starting_phase != null )
            starting_phase.raise_objection( this );                               
    endtask : pre_start


    virtual task post_start();
       `uvm_info("XAC", "seq_pkt::post_start", UVM_HIGH);
        if  ( starting_phase != null )
            starting_phase.drop_objection( this );
    endtask : post_start

endclass

class Drv_pkt extends uvm_driver#(Pkt);


  `uvm_component_utils(Drv_pkt)

    function new(string n="driver", uvm_component p);
       super.new(n,p);
    endfunction 

    virtual task run_phase(uvm_phase phase);

        forever begin 
           `uvm_info("CMD Driver", "waiting for get_next_item", UVM_HIGH);
           seq_item_port.get_next_item(req);
           #1;
	   `uvm_info("CMD Driver", req.sprint(), UVM_HIGH);
	   seq_item_port.item_done();
        end // forever
    endtask // run_phase

endclass


class Agent_pkt extends uvm_agent;

  typedef uvm_sequencer#(Pkt) Seqr_Pkt;
  
  `uvm_component_utils(Agent_pkt);


   Drv_pkt drv_pkt_0;
   Seqr_Pkt seqr_pkt_0;

   function new(string n, uvm_component p);
      super.new(n,p);
   endfunction


   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      seqr_pkt_0 = Seqr_Pkt::type_id::create("seqr_pkt_0", this);
      drv_pkt_0 = Drv_pkt::type_id::create("drv_pkt_0", this);
   endfunction 


   virtual function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       // driver_simple_bus_0.seq_item_port.connect(sequencer_cmd_0.seq_item_export);
       drv_pkt_0.seq_item_port.connect(seqr_pkt_0.seq_item_export);
   endfunction
endclass

class Env extends uvm_env;

  `uvm_component_utils(Env)

    Agent_pkt agent_pkt_0;

    function new(string n, uvm_component p);
       super.new(n,p);
    endfunction 
 
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent_pkt_0=Agent_pkt::type_id::create("agent_pkt_0", this);
   endfunction 
endclass

class Testcase1 extends uvm_test;

  `uvm_component_utils(Testcase1);

	Seq_Pkt seq_pkt_0;
	Env env_0;
	integer len_of_rst = 25;


   function new(string n, uvm_component p);
      super.new(n,p);
   endfunction 


   virtual function void build_phase(uvm_phase phase);

     super.build_phase(phase);
     seq_pkt_0 = Seq_Pkt::type_id::create("seq_pkt_0", this);
     env_0 = Env::type_id::create("env_0", this);
     uvm_config_db#(int)::set(this, "*", "lor", len_of_rst);
    

   endfunction 

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      // seq_pkt_0 = env_0.agent_pkt_0.seqr_pkt_0;
   endfunction // connect_phase

   
   virtual task run_phase(uvm_phase phase);
   
      seq_pkt_0 = Seq_Pkt::type_id::create("seq_pkt_0", this);
   
   endtask

  virtual task main_phase(uvm_phase phase) ;

    uvm_objection objection;
    
    super.main_phase(phase) ;
	// seq_pkt_0.start(env_0.agent_pkt_0.seqr_pkt_0);
    phase.raise_objection(this);
 	seq_pkt_0.start(env_0.agent_pkt_0.seqr_pkt_0);
    objection=phase.get_objection();
    objection.set_drain_time(this, 3us); // $finish at simulation time 100    
    phase.drop_objection(this);

  endtask 

endclass


program main();


   import uvm_pkg::*;

   initial begin
   
     $display("Start of UVM - hardwired message \n");
     
     run_test("Testcase1"); // hard to pass +UVM_TESTNAME via EDA playground 
     						// uvm_top.run_test(); // uvm_top.run_test();

   end

endprogram
