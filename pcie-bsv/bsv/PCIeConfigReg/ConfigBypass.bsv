import Reserved::*;
import ConfigRegMem::*;
import PCIE::*;

typedef enum {
	Gen1=1, Gen2=2, Gen3=3
} PCIeSpeed deriving(Bits, Eq);

typedef enum {
	PM_Enter_L1=0, PM_Enter_L2L3=1, PM_AS_Request_L1=3, PM_Request_Ack=4
} PM_DLLP_Type deriving(Bits, Eq);

// outputs from the Stratix V PCIe Hard IP in config bypass mode

typedef struct {
	Bit#(8)		lane_err;
	Bool		link_equiz_req;
	Bool		equiz_complete;
	Bool		phase_3_successful;
	Bool		phase_2_successful;
	Bool		phase_1_successful;
	Bool		current_deemph;
	PCIeSpeed	current_speed;
	Bool		link_up;
	Bool		link_train;
	Bool		l0state;
	Bool		l0sstate;
	Bool		rx_val_pm;
	PM_DLLP_Type	rx_typ_pm;
	Bool		tx_ack_pm;
	Bit#(2)		ack_phypm;
	Bool		vc_status;
	Bool		rxfc_max;
	Bool		txfc_max;
	Bool		txbuf_emp;
	Bool		rpbuf_emp;
	Bool		dll_req;
	Bool		link_auto_bdw_status;
	Bool		link_bdw_mng_status;
	Bool		rst_tx_margin_field;
	Bool		rst_enter_comp_bit;
	Bit#(3)		rx_st_ecrcerr;
	Bool		err_uncorr_internal;
	Bool		err_corr_internal;
	Bool		err_tlrcvovf;
	Bool		txfc_err;
	Bool		err_tlmalf;
	Bool		err_surpdwn_dll;
	Bool		err_dllrcv;
	Bool		err_dll_repnum;
	Bool		err_dllreptim;
	Bool		err_dllp_baddllp;
	Bool		err_dll_badtlp;
	Bool		err_phy_tng;
	Bool		err_phy_rcv;
	Bool		root_err_reg_stat;
	Bool		corr_err_reg_sts;
	Bool		unc_err_reg_sts;
} S5PCIeCfgBpToApp deriving (Bits, Eq);


// inputs to Stratix V PCIe Hard IP from application, when in config bypass mode
typedef struct {
	Bit#(13)	link2csr;
	Bool		comclk_reg;
	Bool		extsy_reg;
	Bit#(3)		max_pload;
	Bool		tx_ecrcgen;
	Bool		rx_ecrchk;
	Bit#(8)		secbus;
	Bool		linkcsr_bit0;
	Bool		tx_req_pm;
	Bit#(3)		tx_typ_pm;
	Bit#(4)		req_phypm;
	Bit#(4)		req_phycfg;
	Bit#(6)		vc0_tcmap_pld;	// bits [7:1], 'traffic class 0 always maps to virtual channel 0' (ie bit 0 is implied set)
	Bool		inh_dllp;
	Bool		inh_tx_tlp;
	Bool		req_wake;
	Bit#(2)		link3_ctl;
} S5PCIeAppToCfgBp deriving(Bits, Eq);


// PCIe Express configuration registers Link Control and Link Status
// glued together to make a 32 bit word
typedef struct {
	ReservedZero#(4)	r1;
	Bool			link_abw_irq_en;
	Bool			link_bwm_irq_en;
	Bool			hw_awidth_dis;
	Bool			clk_pm;
	Bool			extsy_reg;
	Bool			comclk_reg;
	Bool			retrain;
	Bool			link_dis;
	Bool			read_compl_boundary;
	ReservedZero#(1)	r2;
	Bit#(2)			active_state_pm_ctrl;
} PCIeCfgLnkCon deriving(Bits, Eq);	// Link Control

typedef struct {
	Bool			link_auto_bdw_status;
	Bool			link_bdw_mng_status;
	Bool			dll_active;
	Bool			slot_clk;
	Bool			link_train;
	ReservedZero#(1)	r1;
	Bit#(6)			link_width;
	Bit#(4)			link_speed;
} PCIeCfgLnkSts deriving(Bits, Eq);	// Link Status

typedef struct {
	PCIeCfgLnkSts	status;
	PCIeCfgLnkCon	ctrl;
} PCIeCfgLnkConSts deriving(Bits, Eq);	// Link Status & Control in a 32 bit word


// Link Control 2 and Link Status 2
typedef struct {
	ReservedZero#(3)	r1;
	Bool		compliance_deemph;
	Bool		compliance_sos;
	Bool		modified_compliance;
	Bit#(3)		tx_margin;
	Bool		new_deemph;
	Bool		autonomous_speed_disable;
	Bool		enter_compliance;
	Bit#(4)		target_speed;
} PCIeCfgLnkCon2 deriving(Bits, Eq);	// Link Control 2

typedef struct {
	ReservedZero#(10)	r1;
	Bool		link_equiz_req;
	Bool		phase_3_successful;
	Bool		phase_2_successful;
	Bool		phase_1_successful;
	Bool		equiz_complete;
	Bool		current_deemph;
} PCIeCfgLnkSts2 deriving(Bits, Eq);	// Link Status 2

typedef struct {
	PCIeCfgLnkSts2	status;
	PCIeCfgLnkCon2	ctrl;
} PCIeCfgLnkConSts2 deriving(Bits, Eq);


typedef struct {
	ReservedZero#(16)	r1;
	Bit#(16)	lane_error_status;
} PCIeCfgLnErrSts deriving(Bits, Eq);	// Lane Error Status Register

typedef enum {
	BusNumber			= 12'h018, // Primary, Secondary, Subordinate
	DeviceControl			= 12'h098,
	LinkControlStatus		= 12'h0A0,
	LinkControlStatus2		= 12'h0C0,
	AdvancedErrorCapandControl	= 12'h160,

	LinkControl3			= 12'h254,
	LaneErrorStatus			= 12'h258,
	Pad4Size			= 12'hfff
} ConfigSpaceRegisters deriving(Bits, Eq);


function ConfigSpaceRegisters pcieCfgAddrWord2Byte(Bit#(10) word);
	Bit#(12) byt;
	byt = {word, 2'b0};
	ConfigSpaceRegisters cfgadr = unpack(byt);
	return cfgadr;
endfunction



// look at outgoing PCIe config requests, change any bits we need to supply from the hard IP
function PCIeConfigRegTxn outboundConfigFilter(PCIeConfigRegTxn txn_in, S5PCIeCfgBpToApp cfgbp);
	DataT data = txn_in.data;

	case (pcieCfgAddrWord2Byte(txn_in.address))
		LinkControlStatus: begin // Link Status Register
			PCIeCfgLnkConSts statctrl = unpack(txn_in.data);
			statctrl.status.link_speed = zeroExtend(pack(cfgbp.current_speed));
			statctrl.status.link_train = cfgbp.link_train;
			statctrl.status.link_auto_bdw_status = cfgbp.link_auto_bdw_status;
			statctrl.status.link_bdw_mng_status = cfgbp.link_bdw_mng_status;
			
			data = pack(statctrl);
			end

		LinkControlStatus2: begin	// Link Status 2 Register
			PCIeCfgLnkConSts2 statctrl = unpack(txn_in.data);
			statctrl.status.link_equiz_req = cfgbp.link_equiz_req;
			statctrl.status.phase_3_successful = cfgbp.phase_3_successful;
			statctrl.status.phase_2_successful = cfgbp.phase_2_successful;
			statctrl.status.current_deemph = cfgbp.current_deemph;
			statctrl.status.equiz_complete = cfgbp.equiz_complete;
			if (cfgbp.rst_tx_margin_field)
				statctrl.ctrl.tx_margin = 3'b0;
			if (cfgbp.rst_enter_comp_bit)
				statctrl.ctrl.enter_compliance = False;
			data = pack(statctrl);
			end

		LaneErrorStatus: begin	// Lane Error Status Register
			PCIeCfgLnErrSts status = unpack(txn_in.data);
			status.lane_error_status = {8'b0, cfgbp.lane_err};
			data = pack(status);
			end
	endcase

	PCIeConfigRegTxn txn;
	txn.address = txn_in.address;
	txn.tag = txn_in.tag;
	txn.id = txn_in.id;
	txn.data = data;
	return txn;
endfunction

// look at incoming memory writes, filter off any bits we need to present to the hard IP
function S5PCIeAppToCfgBp inboundConfigFilter(PCIeConfigRegTxn txn_in, S5PCIeAppToCfgBp cfgbp_in);
	DataT data = txn_in.data;
	S5PCIeAppToCfgBp cfgbp = cfgbp_in;

	case (pcieCfgAddrWord2Byte(txn_in.address))
		BusNumber: begin
			cfgbp.secbus = data[15:8];	// Secondary Bus
			end

		DeviceControl: begin
			cfgbp.max_pload = data[7:5];	// Max Payload Size
			end

		LinkControlStatus: begin
			PCIeCfgLnkConSts statctrl = unpack(data);
			cfgbp.comclk_reg = statctrl.ctrl.comclk_reg;
			cfgbp.extsy_reg = statctrl.ctrl.extsy_reg;
			cfgbp.linkcsr_bit0 = unpack(statctrl.ctrl.active_state_pm_ctrl[0]);
			end

		LinkControlStatus2: begin // Link Status 2/Control 2 register
			PCIeCfgLnkConSts2 statctrl = unpack(data);
			cfgbp.link2csr = data[12:0];
			end

		AdvancedErrorCapandControl: begin
			cfgbp.tx_ecrcgen = unpack(data[6]);
			cfgbp.rx_ecrchk = unpack(data[9]);
			end

		LinkControl3: begin
			cfgbp.link3_ctl[1] = data[1]; // Link Equalisation Request Interrupt Enable
			cfgbp.link3_ctl[0] = data[0]; // Perform Equalisation
			end
	endcase

	return cfgbp;
endfunction

