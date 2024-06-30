import uvm_pkg::*;


class Pkt extends uvm_sequence_item;
  
  
  rand reg [31:0] saddr;
  rand reg [31:0] daddr;
  rand reg [31:0] data;
  rand reg [3:0] cmd;
  rand reg rw_;
  rand integer hold_len;
  
  `uvm_object_utils_begin(Pkt)
    `uvm_field_int(saddr, UVM_DEFAULT)
    `uvm_field_int(daddr, UVM_DEFAULT)
 	`uvm_field_int(data, UVM_DEFAULT)
  `uvm_object_utils_end
  constraint cons_basic {
  	saddr > 32'h0;
    saddr < 32'h7999;
    daddr > 32'h8000;
    daddr < 32'hFFFF;
  }
endclass

class Pkt2 extends Pkt;
  rand reg [3:0] prio;
  `uvm_object_utils_begin(Pkt2)
  	`uvm_field_int(prio, UVM_DEFAULT)
  `uvm_object_utils_end
  constraint cons_lower_band {
  	saddr > 32'h0000;
    saddr < 32'h0FFF;
    daddr > 32'h8000;
    daddr < 32'h8FFF;
  }

endclass

class Pkt3 extends Pkt2;
  rand reg [15:0] channel;
  `uvm_object_utils_begin(Pkt3)
  	`uvm_field_int(channel, UVM_DEFAULT)
  `uvm_object_utils_end
  constraint cons_mid_band {
  	saddr > 32'h4000;
    saddr < 32'h4FFF;
    daddr > 32'hA000;
    daddr < 32'hAFFF;
  }

endclass

class Seq_Pkt extends uvm_sequence #(Pkt);


  `uvm_object_utils(Seq_Pkt)

    virtual task body();

          `uvm_info("XAC", "SEQ_PKT::body(), going to do uvm_do_with for the 1st time", UVM_HIGH);

	      `uvm_do_with(req, {cmd == 4'h0; hold_len < 5; saddr == 32'hdeadbeef; rw_== 0;})
    	  `uvm_do_with(req, {cmd == 4'h1; hold_len > 5; hold_len < 8; saddr == 32'hcafefade; rw_== 0;})

	      `uvm_do_with(req, {cmd == 4'h2; saddr == 32'hb00bd00d; daddr == 888; rw_== 0;})
    	  `uvm_do_with(req, {cmd == 4'h3; saddr == 32'hac00001; daddr == 888; rw_== 1;})       

          `uvm_info("XAC", "in sequence body, after 1st uvm_do_with ", UVM_HIGH);

	      `uvm_do_with(req, {cmd == 4'h4; saddr == 32'h2222; daddr == 32'hcafe;})
    	  `uvm_do_with(req, {cmd == 4'h5; saddr == 32'h3333; daddr == 32'hbeef;})
	      `uvm_do_with(req, {cmd == 4'h6; saddr == 32'h4444; daddr == 32'hfeed;})
	      `uvm_do_with(req, {cmd == 4'h7; saddr == 32'h5555; daddr == 32'hfade;})

           req = Pkt::type_id::create("req");
           start_item(req);
           req.cmd = 4;
           req.daddr = 32'haaaa;
           req.saddr = 4;
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
            seq_item_port.get_next_item(req);
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
   
     env_0 = Env::type_id::create("env_0", this);
     uvm_config_db#(int)::set(this, "*", "lor", len_of_rst);
    

   endfunction 

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
   endfunction // connect_phase

   
   virtual task run_phase(uvm_phase phase);
   
      seq_pkt_0 = Seq_Pkt::type_id::create("seq_pkt_0", this);
   
   endtask

  virtual task main_phase(uvm_phase phase) ;

    uvm_objection objection;
    
    super.main_phase(phase) ;
	seq_pkt_0.start(env_0.agent_pkt_0.seqr_pkt_0);
    phase.raise_objection(this);
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
