// ============================================================================
// Copyright (c) 2013 by Terasic Technologies Inc.
// ============================================================================
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// ============================================================================
//           
//  Terasic Technologies Inc
//  9F., No.176, Sec.2, Gongdao 5th Rd, East Dist, Hsinchu City, 30070. Taiwan
//
//
//
//                     web: http://www.terasic.com/   
//                     email: support@terasic.com
//
// ============================================================================
//Date:  Tue Mar  6 16:17:38 2012
// ============================================================================

//`define X4


module PCIe_Fundamental(

							///////////BUTTON/////////////
							BUTTON,

							/////////FAN/////////
							FAN_CTRL,

							/////////LED/////////
							LED,

							/////////OSC/////////
							OSC_50_B3B,
							OSC_50_B3D,
							OSC_50_B4A,
							OSC_50_B4D,
							OSC_50_B7A,
							OSC_50_B7D,
							OSC_50_B8A,
							OSC_50_B8D,

							/////////PCIE/////////
							PCIE_PERST_n,
							PCIE_REFCLK_p,
							PCIE_RX_p,
							PCIE_SMBCLK,
							PCIE_SMBDAT,
							PCIE_TX_p,
							PCIE_WAKE_n
);

//=======================================================
//  PORT declarations
//=======================================================

							///////////BUTTON/////////////

input							[3:0]							BUTTON;

///////// FAN /////////
inout															FAN_CTRL;

///////// LED /////////
output						[3:0]							LED;

///////// OSC /////////
input															OSC_50_B3B;
input															OSC_50_B3D;
input															OSC_50_B4A;
input															OSC_50_B4D;
input															OSC_50_B7A;
input															OSC_50_B7D;
input															OSC_50_B8A;
input															OSC_50_B8D;

///////// PCIE /////////
input															PCIE_PERST_n;
input															PCIE_REFCLK_p;
input															PCIE_SMBCLK;
inout															PCIE_SMBDAT;
output														PCIE_WAKE_n;
`ifdef X4
input							[3:0]							PCIE_RX_p;
output						[3:0]							PCIE_TX_p;
`else
input							[0:0]							PCIE_RX_p;
output							[0:0]							PCIE_TX_p;
`endif
//=======================================================
//  REG/WIRE declarations
//=======================================================



wire clk_out_buf;

reg   sc_rd_dval;
wire 	[11:0]sc_rd_addr;
reg 	[31:0]sc_rd_data;
wire  sc_rd_read;
wire 	[11:0]sc_wr_addr;
wire 	[31:0]sc_wr_data;
wire	sc_wr_write;


wire	[31:0]dmard_addr;
wire	dmard_read;
wire	dmard_rdvalid;
wire	[127:0]dmard_data;

wire	dmawr_write;
wire	[31:0]dmawr_addr;
wire	[127:0]dmawr_data;
wire	[15:0]dmawr_be;

wire	user_int_ack;
wire	fifo_mem_sel;

wire  local_rstn;
reg 	[3:0]LED;
assign local_rstn = BUTTON[0];

//=======================================================
//  Structural coding
//=======================================================
/*
pcie_de_gen1_x8_ast128 pcie_de_gen1_x8_ast128_inst(
                         .clk_clk(OSC_50_B3B),     // reconfig_xcvr_clk.clk
								 .reset_reset_n(1'b1),
		                   .refclk_clk(PCIE_REFCLK_p),                //            refclk.clk
		                   .hip_ctrl_test_in(),          //          hip_ctrl.test_in
		                   .hip_ctrl_simu_mode_pipe(1'b0),   //                  .simu_mode_pipe
		                   .hip_serial_rx_in0(PCIE_RX_p[0]),         //        hip_serial.rx_in0
		                   .hip_serial_rx_in1(PCIE_RX_p[1]),         //                  .rx_in1
		                   .hip_serial_rx_in2(PCIE_RX_p[2]),         //                  .rx_in2
		                   .hip_serial_rx_in3(PCIE_RX_p[3]),         //                  .rx_in3
								 .hip_serial_rx_in4(PCIE_RX_p[4]),         //        hip_serial.rx_in0
		                   .hip_serial_rx_in5(PCIE_RX_p[5]),         //                  .rx_in1
		                   .hip_serial_rx_in6(PCIE_RX_p[6]),         //                  .rx_in2
		                   .hip_serial_rx_in7(PCIE_RX_p[7]),         //                  .rx_in3
		                   .hip_serial_tx_out0(PCIE_TX_p[0]),        //                  .tx_out0
		                   .hip_serial_tx_out1(PCIE_TX_p[1]),        //                  .tx_out1
		                   .hip_serial_tx_out2(PCIE_TX_p[2]),        //                  .tx_out2
		                   .hip_serial_tx_out3(PCIE_TX_p[3]),        //                  .tx_out3
								 .hip_serial_tx_out4(PCIE_TX_p[4]),        //                  .tx_out0
		                   .hip_serial_tx_out5(PCIE_TX_p[5]),        //                  .tx_out1
		                   .hip_serial_tx_out6(PCIE_TX_p[6]),        //                  .tx_out2
		                   .hip_serial_tx_out7(PCIE_TX_p[7]),        //                  .tx_out3
	                      .pcie_rstn_npor(1'b1),            //         pcie_rstn.npor
		                   .pcie_rstn_pin_perst(PCIE_PERST_n),        //                  .pin_perst
								 .dut_coreclkout_hip_clk(clk_out_buf),

//								 .hip_ctrl_test_in(),
								 
								 //Single Cycle Memory or Register R/W Local Interface
								 .sc_rd_addr       (sc_rd_addr),
								 .sc_rd_data       (sc_rd_data),
								 .sc_rd_read       (sc_rd_read),
								 .sc_rd_dval 		 (sc_rd_dval),
								
								 .sc_wr_addr       (sc_wr_addr),
								 .sc_wr_data       (sc_wr_data),
								 .sc_wr_write		 (sc_wr_write),
						
								 // DMA Read 
								 .oDMARD_FRAME(dmard_frame),
								 .oDMARD_ADDR(dmard_addr),
								 .oDMARD_READ(dmard_read),
								 .oDMARD_RDVALID(dmard_rdvalid),
								 .iDMARD_DATA(dmard_data),
						
								 // DMA Write
								 .oDMAWR_WRITE(dmawr_write),
								 .oDMAWR_ADDR(dmawr_addr),
								 .oDMAWR_DATA(dmawr_data),
								 .oDMAWR_BE(dmawr_be),
						
								 .oINT_ACK(int_ack),
								 .iINT_STS(int_sts),
								 .oUSER_INT_ACK(user_int_ack),
								
								 .iCLK_50(OSC_50_B3D),
								 .oFIFO_MEM_SEL(fifo_mem_sel),				// 0--> memory, 1--> fifo		

	);

reg  [4095:0]   regdata[31:0];
	//	Address Decode for Controlling LED
	always@(posedge clk_out_buf)
		begin
			if ( (sc_wr_write) & ( sc_wr_addr == 32'h4 ) )
				LED <= ~sc_wr_data[7:0];
			else if(sc_wr_write)
			   regdata[sc_wr_addr] <= sc_wr_data;
				   
		end
	
	//	Address Decode for Button Status Monitor
	always@(posedge clk_out_buf)
		begin
			if ( ( sc_rd_read ) & ( sc_rd_addr == 32'h4 ) )
				begin
					sc_rd_dval <= 1;
					sc_rd_data <= { 28'h0, BUTTON[3:0]};
				end
			else if( sc_rd_read )
				begin
					sc_rd_dval <= 1;
					sc_rd_data <= regdata[sc_wr_addr];
				end
			else
				begin
					sc_rd_data <= 0;
					sc_rd_dval <= 0;
				end
		end
		
	
	//	Memory or FIFO Bus Selection
	wire	ram_read;
	wire	fifo_read;
	assign	ram_read  = (~fifo_mem_sel)? dmard_read 	: 0;
	assign	fifo_read = ( fifo_mem_sel)? dmard_rdvalid 	: 0;
	
	wire	ram_write;
	wire	fifo_write;
	assign	ram_write = (~fifo_mem_sel)? dmawr_write 	: 0;
	assign	fifo_write= ( fifo_mem_sel)? dmawr_write 	: 0;	
	
	wire	[127:0]ram_dataout;	
	wire	[127:0]fifo_dataout;	
	assign	dmard_data= (~fifo_mem_sel)? ram_dataout : 	fifo_dataout;
	
	// Internal RAM 	
	INT_RAM RAM1(
		.aclr(1'b0),//~CPU_RESET_n
		.clock(clk_out_buf),
		.data(dmawr_data),
		.rdaddress(dmard_addr),
		.rden(ram_read),
		.wraddress(dmawr_addr),
		.wren(ram_write),
		.q(ram_dataout)
		);
	
	
	// FIFO
	FIFO1 F0(
	
		.clock(clk_out_buf),
		.data(dmawr_data),
		.rdreq(fifo_read),
		.sclr(1'b0),//~CPU_RESET_n
		.wrreq(fifo_write),
		.q(fifo_dataout),
		
			);
*/
assign	FAN_CTRL = 1'b1;	
assign   PCIE_WAKE_n = 1'b0;	

`ifdef AVMM
   ep_g2x4 u0 (

        .pcie_sv_hip_avmm_0_hip_ctrl_test_in                    (),                    //            pcie_sv_hip_avmm_0_hip_ctrl.test_in
        .pcie_sv_hip_avmm_0_hip_ctrl_simu_mode_pipe             (1'b0),             //                                       .simu_mode_pipe
/*        .pcie_sv_hip_avmm_0_hip_pipe_sim_pipe_pclk_in           (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_sim_pipe_pclk_in>),           //            pcie_sv_hip_avmm_0_hip_pipe.sim_pipe_pclk_in
        .pcie_sv_hip_avmm_0_hip_pipe_sim_pipe_rate              (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_sim_pipe_rate>),              //                                       .sim_pipe_rate
        .pcie_sv_hip_avmm_0_hip_pipe_sim_ltssmstate             (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_sim_ltssmstate>),             //                                       .sim_ltssmstate
        .pcie_sv_hip_avmm_0_hip_pipe_eidleinfersel0             (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_eidleinfersel0>),             //                                       .eidleinfersel0
        .pcie_sv_hip_avmm_0_hip_pipe_eidleinfersel1             (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_eidleinfersel1>),             //                                       .eidleinfersel1
        .pcie_sv_hip_avmm_0_hip_pipe_eidleinfersel2             (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_eidleinfersel2>),             //                                       .eidleinfersel2
        .pcie_sv_hip_avmm_0_hip_pipe_eidleinfersel3             (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_eidleinfersel3>),             //                                       .eidleinfersel3
        .pcie_sv_hip_avmm_0_hip_pipe_powerdown0                 (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_powerdown0>),                 //                                       .powerdown0
        .pcie_sv_hip_avmm_0_hip_pipe_powerdown1                 (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_powerdown1>),                 //                                       .powerdown1
        .pcie_sv_hip_avmm_0_hip_pipe_powerdown2                 (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_powerdown2>),                 //                                       .powerdown2
        .pcie_sv_hip_avmm_0_hip_pipe_powerdown3                 (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_powerdown3>),                 //                                       .powerdown3
        .pcie_sv_hip_avmm_0_hip_pipe_rxpolarity0                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxpolarity0>),                //                                       .rxpolarity0
        .pcie_sv_hip_avmm_0_hip_pipe_rxpolarity1                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxpolarity1>),                //                                       .rxpolarity1
        .pcie_sv_hip_avmm_0_hip_pipe_rxpolarity2                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxpolarity2>),                //                                       .rxpolarity2
        .pcie_sv_hip_avmm_0_hip_pipe_rxpolarity3                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxpolarity3>),                //                                       .rxpolarity3
        .pcie_sv_hip_avmm_0_hip_pipe_txcompl0                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txcompl0>),                   //                                       .txcompl0
        .pcie_sv_hip_avmm_0_hip_pipe_txcompl1                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txcompl1>),                   //                                       .txcompl1
        .pcie_sv_hip_avmm_0_hip_pipe_txcompl2                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txcompl2>),                   //                                       .txcompl2
        .pcie_sv_hip_avmm_0_hip_pipe_txcompl3                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txcompl3>),                   //                                       .txcompl3
        .pcie_sv_hip_avmm_0_hip_pipe_txdata0                    (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdata0>),                    //                                       .txdata0
        .pcie_sv_hip_avmm_0_hip_pipe_txdata1                    (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdata1>),                    //                                       .txdata1
        .pcie_sv_hip_avmm_0_hip_pipe_txdata2                    (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdata2>),                    //                                       .txdata2
        .pcie_sv_hip_avmm_0_hip_pipe_txdata3                    (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdata3>),                    //                                       .txdata3
        .pcie_sv_hip_avmm_0_hip_pipe_txdatak0                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdatak0>),                   //                                       .txdatak0
        .pcie_sv_hip_avmm_0_hip_pipe_txdatak1                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdatak1>),                   //                                       .txdatak1
        .pcie_sv_hip_avmm_0_hip_pipe_txdatak2                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdatak2>),                   //                                       .txdatak2
        .pcie_sv_hip_avmm_0_hip_pipe_txdatak3                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdatak3>),                   //                                       .txdatak3
        .pcie_sv_hip_avmm_0_hip_pipe_txdetectrx0                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdetectrx0>),                //                                       .txdetectrx0
        .pcie_sv_hip_avmm_0_hip_pipe_txdetectrx1                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdetectrx1>),                //                                       .txdetectrx1
        .pcie_sv_hip_avmm_0_hip_pipe_txdetectrx2                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdetectrx2>),                //                                       .txdetectrx2
        .pcie_sv_hip_avmm_0_hip_pipe_txdetectrx3                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdetectrx3>),                //                                       .txdetectrx3
        .pcie_sv_hip_avmm_0_hip_pipe_txelecidle0                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txelecidle0>),                //                                       .txelecidle0
        .pcie_sv_hip_avmm_0_hip_pipe_txelecidle1                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txelecidle1>),                //                                       .txelecidle1
        .pcie_sv_hip_avmm_0_hip_pipe_txelecidle2                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txelecidle2>),                //                                       .txelecidle2
        .pcie_sv_hip_avmm_0_hip_pipe_txelecidle3                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txelecidle3>),                //                                       .txelecidle3
        .pcie_sv_hip_avmm_0_hip_pipe_txdeemph0                  (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdeemph0>),                  //                                       .txdeemph0
        .pcie_sv_hip_avmm_0_hip_pipe_txdeemph1                  (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdeemph1>),                  //                                       .txdeemph1
        .pcie_sv_hip_avmm_0_hip_pipe_txdeemph2                  (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdeemph2>),                  //                                       .txdeemph2
        .pcie_sv_hip_avmm_0_hip_pipe_txdeemph3                  (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txdeemph3>),                  //                                       .txdeemph3
        .pcie_sv_hip_avmm_0_hip_pipe_txmargin0                  (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txmargin0>),                  //                                       .txmargin0
        .pcie_sv_hip_avmm_0_hip_pipe_txmargin1                  (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txmargin1>),                  //                                       .txmargin1
        .pcie_sv_hip_avmm_0_hip_pipe_txmargin2                  (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txmargin2>),                  //                                       .txmargin2
        .pcie_sv_hip_avmm_0_hip_pipe_txmargin3                  (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txmargin3>),                  //                                       .txmargin3
        .pcie_sv_hip_avmm_0_hip_pipe_txswing0                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txswing0>),                   //                                       .txswing0
        .pcie_sv_hip_avmm_0_hip_pipe_txswing1                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txswing1>),                   //                                       .txswing1
        .pcie_sv_hip_avmm_0_hip_pipe_txswing2                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txswing2>),                   //                                       .txswing2
        .pcie_sv_hip_avmm_0_hip_pipe_txswing3                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_txswing3>),                   //                                       .txswing3
        .pcie_sv_hip_avmm_0_hip_pipe_phystatus0                 (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_phystatus0>),                 //                                       .phystatus0
        .pcie_sv_hip_avmm_0_hip_pipe_phystatus1                 (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_phystatus1>),                 //                                       .phystatus1
        .pcie_sv_hip_avmm_0_hip_pipe_phystatus2                 (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_phystatus2>),                 //                                       .phystatus2
        .pcie_sv_hip_avmm_0_hip_pipe_phystatus3                 (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_phystatus3>),                 //                                       .phystatus3
        .pcie_sv_hip_avmm_0_hip_pipe_rxdata0                    (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxdata0>),                    //                                       .rxdata0
        .pcie_sv_hip_avmm_0_hip_pipe_rxdata1                    (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxdata1>),                    //                                       .rxdata1
        .pcie_sv_hip_avmm_0_hip_pipe_rxdata2                    (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxdata2>),                    //                                       .rxdata2
        .pcie_sv_hip_avmm_0_hip_pipe_rxdata3                    (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxdata3>),                    //                                       .rxdata3
        .pcie_sv_hip_avmm_0_hip_pipe_rxdatak0                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxdatak0>),                   //                                       .rxdatak0
        .pcie_sv_hip_avmm_0_hip_pipe_rxdatak1                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxdatak1>),                   //                                       .rxdatak1
        .pcie_sv_hip_avmm_0_hip_pipe_rxdatak2                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxdatak2>),                   //                                       .rxdatak2
        .pcie_sv_hip_avmm_0_hip_pipe_rxdatak3                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxdatak3>),                   //                                       .rxdatak3
        .pcie_sv_hip_avmm_0_hip_pipe_rxelecidle0                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxelecidle0>),                //                                       .rxelecidle0
        .pcie_sv_hip_avmm_0_hip_pipe_rxelecidle1                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxelecidle1>),                //                                       .rxelecidle1
        .pcie_sv_hip_avmm_0_hip_pipe_rxelecidle2                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxelecidle2>),                //                                       .rxelecidle2
        .pcie_sv_hip_avmm_0_hip_pipe_rxelecidle3                (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxelecidle3>),                //                                       .rxelecidle3
        .pcie_sv_hip_avmm_0_hip_pipe_rxstatus0                  (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxstatus0>),                  //                                       .rxstatus0
        .pcie_sv_hip_avmm_0_hip_pipe_rxstatus1                  (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxstatus1>),                  //                                       .rxstatus1
        .pcie_sv_hip_avmm_0_hip_pipe_rxstatus2                  (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxstatus2>),                  //                                       .rxstatus2
        .pcie_sv_hip_avmm_0_hip_pipe_rxstatus3                  (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxstatus3>),                  //                                       .rxstatus3
        .pcie_sv_hip_avmm_0_hip_pipe_rxvalid0                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxvalid0>),                   //                                       .rxvalid0
        .pcie_sv_hip_avmm_0_hip_pipe_rxvalid1                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxvalid1>),                   //                                       .rxvalid1
        .pcie_sv_hip_avmm_0_hip_pipe_rxvalid2                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxvalid2>),                   //                                       .rxvalid2
        .pcie_sv_hip_avmm_0_hip_pipe_rxvalid3                   (<connected-to-pcie_sv_hip_avmm_0_hip_pipe_rxvalid3>),                   //                                       .rxvalid3
*/
        .pcie_sv_hip_avmm_0_hip_serial_rx_in0                   (PCIE_RX_p[0]),                   //          pcie_sv_hip_avmm_0_hip_serial.rx_in0
/*        .pcie_sv_hip_avmm_0_hip_serial_rx_in1                   (PCIE_RX_p[1]),                   //                                       .rx_in1
        .pcie_sv_hip_avmm_0_hip_serial_rx_in2                   (PCIE_RX_p[2]),                   //                                       .rx_in2
        .pcie_sv_hip_avmm_0_hip_serial_rx_in3                   (PCIE_RX_p[3]),                   //                                       .rx_in3
*/        .pcie_sv_hip_avmm_0_hip_serial_tx_out0                  (PCIE_TX_p[0]),                  //                                       .tx_out0
/*        .pcie_sv_hip_avmm_0_hip_serial_tx_out1                  (PCIE_TX_p[1]),                  //                                       .tx_out1
        .pcie_sv_hip_avmm_0_hip_serial_tx_out2                  (PCIE_TX_p[2]),                  //                                       .tx_out2
        .pcie_sv_hip_avmm_0_hip_serial_tx_out3                  (PCIE_TX_p[3]),                  //                                       .tx_out3
*/        .pcie_sv_hip_avmm_0_npor_npor                           (1'b1),                           //                pcie_sv_hip_avmm_0_npor.npor
        .pcie_sv_hip_avmm_0_npor_pin_perst                      (PCIE_PERST_n),                      //                                       .pin_perst
//        .pcie_sv_hip_avmm_0_reconfig_clk_locked_fixedclk_locked (<connected-to-pcie_sv_hip_avmm_0_reconfig_clk_locked_fixedclk_locked>), // pcie_sv_hip_avmm_0_reconfig_clk_locked.fixedclk_locked
        .pcie_sv_hip_avmm_0_refclk_clk                          (PCIE_REFCLK_p),                          //              pcie_sv_hip_avmm_0_refclk.clk
        .reconfig_xcvr_clk_clk                                  (OSC_50_B3B),                                  //                      reconfig_xcvr_clk.clk
        .reconfig_xcvr_reset_reset_n                            (PCIE_PERST_n)                             //                    reconfig_xcvr_reset.reset_n
    );
`endif


    pcie_de_gen1_x4_ast64 u0 (
        .clk_sys_clk                   (OSC_50_B3B),                   //        clk.clk
        .hip_ctrl_test_in          (32'hA8),          //   hip_ctrl.test_in
        .hip_ctrl_simu_mode_pipe   (1'b0),   //           .simu_mode_pipe
/*        .hip_pipe_sim_pipe_pclk_in (<connected-to-hip_pipe_sim_pipe_pclk_in>), //   hip_pipe.sim_pipe_pclk_in
        .hip_pipe_sim_pipe_rate    (<connected-to-hip_pipe_sim_pipe_rate>),    //           .sim_pipe_rate
        .hip_pipe_sim_ltssmstate   (<connected-to-hip_pipe_sim_ltssmstate>),   //           .sim_ltssmstate
        .hip_pipe_eidleinfersel0   (<connected-to-hip_pipe_eidleinfersel0>),   //           .eidleinfersel0
        .hip_pipe_eidleinfersel1   (<connected-to-hip_pipe_eidleinfersel1>),   //           .eidleinfersel1
        .hip_pipe_eidleinfersel2   (<connected-to-hip_pipe_eidleinfersel2>),   //           .eidleinfersel2
        .hip_pipe_eidleinfersel3   (<connected-to-hip_pipe_eidleinfersel3>),   //           .eidleinfersel3
        .hip_pipe_powerdown0       (<connected-to-hip_pipe_powerdown0>),       //           .powerdown0
        .hip_pipe_powerdown1       (<connected-to-hip_pipe_powerdown1>),       //           .powerdown1
        .hip_pipe_powerdown2       (<connected-to-hip_pipe_powerdown2>),       //           .powerdown2
        .hip_pipe_powerdown3       (<connected-to-hip_pipe_powerdown3>),       //           .powerdown3
        .hip_pipe_rxpolarity0      (<connected-to-hip_pipe_rxpolarity0>),      //           .rxpolarity0
        .hip_pipe_rxpolarity1      (<connected-to-hip_pipe_rxpolarity1>),      //           .rxpolarity1
        .hip_pipe_rxpolarity2      (<connected-to-hip_pipe_rxpolarity2>),      //           .rxpolarity2
        .hip_pipe_rxpolarity3      (<connected-to-hip_pipe_rxpolarity3>),      //           .rxpolarity3
        .hip_pipe_txcompl0         (<connected-to-hip_pipe_txcompl0>),         //           .txcompl0
        .hip_pipe_txcompl1         (<connected-to-hip_pipe_txcompl1>),         //           .txcompl1
        .hip_pipe_txcompl2         (<connected-to-hip_pipe_txcompl2>),         //           .txcompl2
        .hip_pipe_txcompl3         (<connected-to-hip_pipe_txcompl3>),         //           .txcompl3
        .hip_pipe_txdata0          (<connected-to-hip_pipe_txdata0>),          //           .txdata0
        .hip_pipe_txdata1          (<connected-to-hip_pipe_txdata1>),          //           .txdata1
        .hip_pipe_txdata2          (<connected-to-hip_pipe_txdata2>),          //           .txdata2
        .hip_pipe_txdata3          (<connected-to-hip_pipe_txdata3>),          //           .txdata3
        .hip_pipe_txdatak0         (<connected-to-hip_pipe_txdatak0>),         //           .txdatak0
        .hip_pipe_txdatak1         (<connected-to-hip_pipe_txdatak1>),         //           .txdatak1
        .hip_pipe_txdatak2         (<connected-to-hip_pipe_txdatak2>),         //           .txdatak2
        .hip_pipe_txdatak3         (<connected-to-hip_pipe_txdatak3>),         //           .txdatak3
        .hip_pipe_txdetectrx0      (<connected-to-hip_pipe_txdetectrx0>),      //           .txdetectrx0
        .hip_pipe_txdetectrx1      (<connected-to-hip_pipe_txdetectrx1>),      //           .txdetectrx1
        .hip_pipe_txdetectrx2      (<connected-to-hip_pipe_txdetectrx2>),      //           .txdetectrx2
        .hip_pipe_txdetectrx3      (<connected-to-hip_pipe_txdetectrx3>),      //           .txdetectrx3
        .hip_pipe_txelecidle0      (<connected-to-hip_pipe_txelecidle0>),      //           .txelecidle0
        .hip_pipe_txelecidle1      (<connected-to-hip_pipe_txelecidle1>),      //           .txelecidle1
        .hip_pipe_txelecidle2      (<connected-to-hip_pipe_txelecidle2>),      //           .txelecidle2
        .hip_pipe_txelecidle3      (<connected-to-hip_pipe_txelecidle3>),      //           .txelecidle3
        .hip_pipe_txdeemph0        (<connected-to-hip_pipe_txdeemph0>),        //           .txdeemph0
        .hip_pipe_txdeemph1        (<connected-to-hip_pipe_txdeemph1>),        //           .txdeemph1
        .hip_pipe_txdeemph2        (<connected-to-hip_pipe_txdeemph2>),        //           .txdeemph2
        .hip_pipe_txdeemph3        (<connected-to-hip_pipe_txdeemph3>),        //           .txdeemph3
        .hip_pipe_txmargin0        (<connected-to-hip_pipe_txmargin0>),        //           .txmargin0
        .hip_pipe_txmargin1        (<connected-to-hip_pipe_txmargin1>),        //           .txmargin1
        .hip_pipe_txmargin2        (<connected-to-hip_pipe_txmargin2>),        //           .txmargin2
        .hip_pipe_txmargin3        (<connected-to-hip_pipe_txmargin3>),        //           .txmargin3
        .hip_pipe_txswing0         (<connected-to-hip_pipe_txswing0>),         //           .txswing0
        .hip_pipe_txswing1         (<connected-to-hip_pipe_txswing1>),         //           .txswing1
        .hip_pipe_txswing2         (<connected-to-hip_pipe_txswing2>),         //           .txswing2
        .hip_pipe_txswing3         (<connected-to-hip_pipe_txswing3>),         //           .txswing3
        .hip_pipe_phystatus0       (<connected-to-hip_pipe_phystatus0>),       //           .phystatus0
        .hip_pipe_phystatus1       (<connected-to-hip_pipe_phystatus1>),       //           .phystatus1
        .hip_pipe_phystatus2       (<connected-to-hip_pipe_phystatus2>),       //           .phystatus2
        .hip_pipe_phystatus3       (<connected-to-hip_pipe_phystatus3>),       //           .phystatus3
        .hip_pipe_rxdata0          (<connected-to-hip_pipe_rxdata0>),          //           .rxdata0
        .hip_pipe_rxdata1          (<connected-to-hip_pipe_rxdata1>),          //           .rxdata1
        .hip_pipe_rxdata2          (<connected-to-hip_pipe_rxdata2>),          //           .rxdata2
        .hip_pipe_rxdata3          (<connected-to-hip_pipe_rxdata3>),          //           .rxdata3
        .hip_pipe_rxdatak0         (<connected-to-hip_pipe_rxdatak0>),         //           .rxdatak0
        .hip_pipe_rxdatak1         (<connected-to-hip_pipe_rxdatak1>),         //           .rxdatak1
        .hip_pipe_rxdatak2         (<connected-to-hip_pipe_rxdatak2>),         //           .rxdatak2
        .hip_pipe_rxdatak3         (<connected-to-hip_pipe_rxdatak3>),         //           .rxdatak3
        .hip_pipe_rxelecidle0      (<connected-to-hip_pipe_rxelecidle0>),      //           .rxelecidle0
        .hip_pipe_rxelecidle1      (<connected-to-hip_pipe_rxelecidle1>),      //           .rxelecidle1
        .hip_pipe_rxelecidle2      (<connected-to-hip_pipe_rxelecidle2>),      //           .rxelecidle2
        .hip_pipe_rxelecidle3      (<connected-to-hip_pipe_rxelecidle3>),      //           .rxelecidle3
        .hip_pipe_rxstatus0        (<connected-to-hip_pipe_rxstatus0>),        //           .rxstatus0
        .hip_pipe_rxstatus1        (<connected-to-hip_pipe_rxstatus1>),        //           .rxstatus1
        .hip_pipe_rxstatus2        (<connected-to-hip_pipe_rxstatus2>),        //           .rxstatus2
        .hip_pipe_rxstatus3        (<connected-to-hip_pipe_rxstatus3>),        //           .rxstatus3
        .hip_pipe_rxvalid0         (<connected-to-hip_pipe_rxvalid0>),         //           .rxvalid0
        .hip_pipe_rxvalid1         (<connected-to-hip_pipe_rxvalid1>),         //           .rxvalid1
        .hip_pipe_rxvalid2         (<connected-to-hip_pipe_rxvalid2>),         //           .rxvalid2
        .hip_pipe_rxvalid3         (<connected-to-hip_pipe_rxvalid3>),         //           .rxvalid3
*/
/*
        .dut_config_tl_hpg_ctrler                      (<connected-to-dut_config_tl_hpg_ctrler>),                      //                          dut_config_tl.hpg_ctrler
        .dut_config_tl_tl_cfg_add                      (<connected-to-dut_config_tl_tl_cfg_add>),                      //                                       .tl_cfg_add
        .dut_config_tl_tl_cfg_ctl                      (<connected-to-dut_config_tl_tl_cfg_ctl>),                      //                                       .tl_cfg_ctl
        .dut_config_tl_tl_cfg_sts                      (<connected-to-dut_config_tl_tl_cfg_sts>),                      //                                       .tl_cfg_sts
*/
//        .dut_config_tl_cpl_err                         (6'h0),                         //                                       .cpl_err
//        .dut_config_tl_cpl_pending                     (0),                     //                                       .cpl_pending
/*        .dut_lmi_lmi_addr                              (<connected-to-dut_lmi_lmi_addr>),                              //                                dut_lmi.lmi_addr
        .dut_lmi_lmi_din                               (<connected-to-dut_lmi_lmi_din>),                               //                                       .lmi_din
        .dut_lmi_lmi_rden                              (<connected-to-dut_lmi_lmi_rden>),                              //                                       .lmi_rden
        .dut_lmi_lmi_wren                              (<connected-to-dut_lmi_lmi_wren>),                              //                                       .lmi_wren
        .dut_lmi_lmi_ack                               (<connected-to-dut_lmi_lmi_ack>),                               //                                       .lmi_ack
        .dut_lmi_lmi_dout                              (<connected-to-dut_lmi_lmi_dout>)                               //                                       .lmi_dout
		  */


        .hip_serial_rx_in0         (PCIE_RX_p[0]),         // hip_serial.rx_in0
`ifdef X4
        .hip_serial_rx_in1         (PCIE_RX_p[1]),         //           .rx_in1
        .hip_serial_rx_in2         (PCIE_RX_p[2]),         //           .rx_in2
        .hip_serial_rx_in3         (PCIE_RX_p[3]),         //           .rx_in3
`endif
        .hip_serial_tx_out0        (PCIE_TX_p[0]),        //           .tx_out0
`ifdef X4
        .hip_serial_tx_out1        (PCIE_TX_p[1]),        //           .tx_out1
        .hip_serial_tx_out2        (PCIE_TX_p[2]),        //           .tx_out2
        .hip_serial_tx_out3        (PCIE_TX_p[3]),        //           .tx_out3
`endif
        .pcie_rstn_npor            (local_rstn),            //  pcie_rstn.npor
        .pcie_rstn_pin_perst       (PCIE_PERST_n),       //           .pin_perst
        .refclk_clk                (PCIE_REFCLK_p),                //     refclk.clk
        //.perst_reset_n             (PCIE_PERST_n),              //      reset.reset_n
		  .reset_sys_reset_n                 (local_rstn)
    );


endmodule
