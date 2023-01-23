//-----------------------------------------------------------------------------
// Company     : 
// Engineer    : 
//
// Create Date : Sun Oct 03 11:41:45 EDT 2021
//
// Project     : RNIC
// VLNV        : tmdt:core:axis_mux3:1.0
// Revision    : 0.01 - File Created
//
// Comments    :
//
//-----------------------------------------------------------------------------

module axis_mux3_rr (
		//  AXI System Synchronization slave
		aclk       ,
		//  AXI System Synchronous reset slave
		aresetn    ,
		//  AXI-Streaming bus slave
		s0_tready  ,
		s0_tvalid  ,
		s0_tdata   ,
		s0_tkeep   ,
		s0_tlast   ,
		s0_tuser   ,
		//  AXI-Streaming bus master
		m0_tready  ,
		m0_tvalid  ,
		m0_tdata   ,
		m0_tkeep   ,
		m0_tlast   ,
		m0_tuser   ,
		//  AXI-Streaming bus slave
		s1_tready  ,
		s1_tvalid  ,
		s1_tdata   ,
		s1_tkeep   ,
		s1_tlast   ,
		s1_tuser   ,
		//  AXI-Streaming bus slave request suppress
		s0_disable ,
		s1_disable ,
		//  AXI-Streaming bus slave
		s2_tready  ,
		s2_tvalid  ,
		s2_tdata   ,
		s2_tkeep   ,
		s2_tlast   ,
		s2_tuser   ,
		//  AXI-Streaming bus slave request suppress
		s2_disable 
		);

	// port declarations
	//  AXI System Synchronization slave
	input  logic         aclk       ;
	//  AXI System Synchronous reset slave
	input  logic         aresetn    ;
	//  AXI-Streaming bus slave
	output logic         s0_tready  ;
	input  logic         s0_tvalid  ;
	input  logic [511:0] s0_tdata   ;
	input  logic [ 63:0] s0_tkeep   ;
	input  logic         s0_tlast   ;
	input  logic [  0:0] s0_tuser   ;
	//  AXI-Streaming bus master
	input  logic         m0_tready  ;
	output logic         m0_tvalid  ;
	output logic [511:0] m0_tdata   ;
	output logic [ 63:0] m0_tkeep   ;
	output logic         m0_tlast   ;
	output logic [  0:0] m0_tuser   ;
	//  AXI-Streaming bus slave
	output logic         s1_tready  ;
	input  logic         s1_tvalid  ;
	input  logic [511:0] s1_tdata   ;
	input  logic [ 63:0] s1_tkeep   ;
	input  logic         s1_tlast   ;
	input  logic [  0:0] s1_tuser   ;
	//  AXI-Streaming bus slave request suppress
	input  logic         s0_disable ;
	input  logic         s1_disable ;
	//  AXI-Streaming bus slave
	output logic         s2_tready  ;
	input  logic         s2_tvalid  ;
	input  logic [511:0] s2_tdata   ;
	input  logic [ 63:0] s2_tkeep   ;
	input  logic         s2_tlast   ;
	input  logic [  0:0] s2_tuser   ;
	//  AXI-Streaming bus slave request suppress
	input  logic         s2_disable ;
	
	logic s0_trn;
	logic s0_sop;
	logic s0_eop;
	logic s0_pkt;
	logic s0_bsy;

	axis_state_base x0(
			.aclk	(aclk),
			.aresetn(aresetn),
	
			.ready	(s0_tready),
			.valid	(s0_tvalid),
			.last	(s0_tlast),

			.trn	(s0_trn),
			.sop	(s0_sop),
			.eop	(s0_eop),
			.pkt	(s0_pkt),
			.bsy	(s0_bsy)    
		);

	logic s1_trn;
	logic s1_sop;
	logic s1_eop;
	logic s1_pkt;
	logic s1_bsy;

	axis_state_base x1(
			.aclk	(aclk),
			.aresetn(aresetn),
	
			.ready	(s1_tready),
			.valid	(s1_tvalid),
			.last	(s1_tlast),

			.trn	(s1_trn),
			.sop	(s1_sop),
			.eop	(s1_eop),
			.pkt	(s1_pkt),
			.bsy	(s1_bsy)    
		);
	
	logic s2_trn;
	logic s2_sop;
	logic s2_eop;
	logic s2_pkt;
	logic s2_bsy;

	axis_state_base x2(
			.aclk	(aclk),
			.aresetn(aresetn),
	
			.ready	(s2_tready),
			.valid	(s2_tvalid),
			.last	(s2_tlast),

			.trn	(s2_trn),
			.sop	(s2_sop),
			.eop	(s2_eop),
			.pkt	(s2_pkt),
			.bsy	(s2_bsy)    
		);

	logic m_trn;
	logic m_sop;
	logic m_eop;
	logic m_pkt;
	logic m_bsy;

	axis_state_base xm(
			.aclk	(aclk),
			.aresetn(aresetn),
	
			.ready	(m0_tready),
			.valid	(m0_tvalid),
			.last	(m0_tlast),

			.trn	(m_trn),
			.sop	(m_sop),
			.eop	(m_eop),
			.pkt	(m_pkt),
			.bsy	(m_bsy)    
		);
	
	logic s0_start;
	logic s1_start;
	logic s2_start;
	
	enum logic [2: 0]{
		FIRST_CHANNEL 	= 3'b001,
		SECOND_CHANNEL 	= 3'b010,
		THIRD_CHANNEL 	= 3'b100
	} channels;
	
	logic [2: 0] current_channel;
	logic [2: 0] next_channel;
	
	always_ff @(posedge aclk) current_channel <= next_channel;
	
	always_comb
	begin
		if(~aresetn) next_channel = FIRST_CHANNEL;
		else if(s0_tvalid | s1_tvalid | s2_tvalid)
			case(current_channel) 		
				FIRST_CHANNEL : if(s0_trn & s0_eop) begin
									if (s1_tvalid & ~s1_bsy) 
										next_channel[2:0] = SECOND_CHANNEL; 
									else if (s2_tvalid & ~s2_bsy)
										next_channel[2:0] = THIRD_CHANNEL;
								end else if (~s0_pkt) begin
									if (s1_tvalid & ~s1_bsy) 
										next_channel[2:0] = SECOND_CHANNEL; 
									else if (s2_tvalid & ~s2_bsy)
										next_channel[2:0] = THIRD_CHANNEL;
								end		
				SECOND_CHANNEL : if(s1_trn & s1_eop) begin
									if (s2_tvalid & ~s2_bsy) 
										next_channel[2:0] = THIRD_CHANNEL; 
									else if (s0_tvalid  & ~s0_bsy)
										next_channel[2:0] = FIRST_CHANNEL;
								end else if (~s1_pkt)begin
									if (s2_tvalid & ~s2_bsy) 
										next_channel[2:0] = THIRD_CHANNEL; 
									else if (s0_tvalid  & ~s0_bsy)
										next_channel[2:0] = FIRST_CHANNEL;
								end
				THIRD_CHANNEL : if(s2_trn & s2_eop) begin
									if (s0_tvalid & ~s0_bsy) 
										next_channel[2:0] = FIRST_CHANNEL; 
									else if (s1_tvalid & ~s1_bsy) 
										next_channel[2:0] = SECOND_CHANNEL;						
								end else if (~s2_pkt)begin
									if (s0_tvalid & ~s0_bsy) 
										next_channel[2:0] = FIRST_CHANNEL; 
									else if (s1_tvalid & ~s1_bsy) 
										next_channel[2:0] = SECOND_CHANNEL;
								end
			endcase
	end

	assign s0_start = ~s1_pkt & ~s2_pkt & s0_tvalid &  current_channel[0];
	assign s1_start = ~s0_pkt & ~s2_pkt & s1_tvalid &  current_channel[1];
	assign s2_start = ~s0_pkt & ~s1_pkt & s2_tvalid &  current_channel[2];

	assign s0_pkt = s0_start | s0_bsy;
	assign s1_pkt = s1_start | s1_bsy;
	assign s2_pkt = s2_start | s2_bsy;
	
	assign s0_tready = current_channel[0] & m0_tready ;
	assign s1_tready = current_channel[1] & m0_tready ;
	assign s2_tready = current_channel[2] & m0_tready ;

	assign m0_tvalid = ~s2_pkt ? (~s1_pkt ? s0_tvalid 	: s1_tvalid)	:	s2_tvalid 	;
	assign m0_tdata  = ~s2_pkt ? (~s1_pkt ? s0_tdata  	: s1_tdata)		:	s2_tdata	;
	assign m0_tkeep  = ~s2_pkt ? (~s1_pkt ? s0_tkeep  	: s1_tkeep) 	:	s2_tkeep 	;
	assign m0_tlast  = ~s2_pkt ? (~s1_pkt ? s0_tlast 	: s1_tlast)  	:	s2_tlast  	;
	assign m0_tuser  = ~s2_pkt ? (~s1_pkt ? s0_tuser 	: s1_tuser)  	:	s2_tuser 	;
	
endmodule : axis_mux3_rr
