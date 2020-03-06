import AvalonMM::*;
import PCIE::*;
import ConfigRegMem::*;
import ClientServer::*;
import GetPut::*;
import FIFOF::*;
import PCIeDefs::*;
import Assert::*;
import Connectable::*;
import ConfigBypass::*;
import DefaultValue::*;

typedef Bit#(32) PCIeConfigRegT;
typedef Bit#(10) PCIeConfigAddressT;

interface PCIeConfigRegs;
	interface AvalonSlaveExt#(PCIeConfigRegT, PCIeConfigAddressT, 4, 1) avs;
//	interface FIFOF#(TLP) tlpFeed;
	interface Put#(TLP) tlpFeed;
	interface Get#(TLP) tlpOut;
	method Action bypassInCfgbp(S5PCIeCfgBpToApp cfgIn);
	method S5PCIeAppToCfgBp bypassOutCfgbp;
endinterface

/* XXX: this assumes responses are correctly ordered (which is necessary for Avalon since there is no response tagging */

(* descending_urgency = "serviceTLP, serviceAvalon" *)
module mkPCIeConfigRegs(PCIeConfigRegs);
	AvalonSlave#(PCIeConfigRegT, PCIeConfigAddressT, 4, 1) avalon <- mkAvalonSlave;
	ConfigRegMem configmem <- mkConfigRegMem;
	FIFOF#(TLP) tlpInput <- mkFIFOF;
	FIFOF#(TLPData#(16)) tlpDoubled <- mkFIFOF;
//	Reg#(Bit#(1)) tlpPortionId<- mkReg(0);
//	Reg#(Vector#(2, TLPData#(8))) tlpHalf <- mkReg;
//	Reg#(TLPData#(8)) tlpHalf1 <- mkReg;
//	FIFOF#(TLPTag) tagQ <- mkSizedFIFOF(32);
	Reg#(S5PCIeCfgBpToApp) cfgbpIn <- mkReg(unpack(0));
	Reg#(S5PCIeAppToCfgBp) cfgbpOut <- mkReg(unpack(0));
	FIFOF#(TLP) tlpOutput <- mkFIFOF;
	FIFOF#(TLPData#(16)) tlpOutWide <- mkFIFOF;

	// receive a feed of packets in 64 bit words.  Double them to 128 bit so we have enough info to decode
	mkConnection(toGet(tlpInput), toPut(tlpDoubled));
	// similiarly down-convert the output stream
	mkConnection(toGet(tlpOutWide), toPut(tlpOutput));

	rule serviceAvalon;
		AvalonMMRequest#(PCIeConfigRegT, PCIeConfigAddressT, 4, 1) request <- avalon.client.request.get();
		$display("%t: PCIeConfigRegs.serviceAvalon request = %x", $time, request);
		case (request) matches
			tagged AvalonWrite { writedata: .d, address: .a, byteenable: .be, burstcount: .bc } : begin
				configmem.writeAvalon(a, d);
				PCIeConfigRegTxn txn = PCIeConfigRegTxn { address: a, data: d, tag: ?, id: ? };
				cfgbpOut <= inboundConfigFilter(txn, cfgbpOut);
			end
			tagged AvalonRead { address: .a, byteenable: .be, burstcount: .bc } : begin
				configmem.readAvalon(a);
			end
		endcase
	endrule

	rule avalonResponses;
		let data <- configmem.readresponseAvalon();
		AvalonMMResponse#(PCIeConfigRegT) response = pack(data);
		avalon.client.response.put(response);
	endrule	
/*
	rule doubleTLPdrain;
		let doubleTLP = tlpDoubled.first();
		tlpDoubled.deq();
		$display("%t: 128 bit TLP = %x", $time, doubleTLP);
	endrule

	rule singleTLPdrain;
		let singleTLP = tlpInput.first();
		tlpInput.deq();
		$display("%t: 64 bit TLP = %x", $time, singleTLP);
	endrule
*/
/*
	rule doubleTLPs;
		let tlpInput = tlpFeed.first();
		tlpFeed.deq();
		tlpHalf[tlpPortion] <= tlpInput;
		tlpPortion <= tlpPortion+1;
		if (tlpPortionId == 0) begin
			TLPData#(16) tlpDoubleWidth;
			tlpDoubleWidth.sof = tlpHalf[0].sof;
			tlpDoubleWidth.eof = tlpHalf[1].eof;
			tlpDoubleWidth.hit = tlpHalf[0].hit;
			tlpDoubleWidth.be = {tlpHalf[0].be, tlpHalf[1].be};
			tlpDoubleWidth.data = {tlpHalf[0].data, tlpHalf[1].data};
		end
*/			

	rule serviceTLP;
		let tlp = tlpDoubled.first();
		tlpDoubled.deq();
		Bit#(96) threeDW = truncateLSB(tlp.data);
		TLPConfig3DWHeader tlpHeader = unpack(threeDW);
		TLPConfigWrite tlpConfigWrite = unpack(tlp.data);
		if (tlpHeader.pkttype == CONFIG_0_READ_WRITE) begin
			dynamicAssert((tlpHeader.format == MEM_READ_3DW_NO_DATA) || (tlpHeader.format == MEM_WRITE_3DW_DATA), "Unrecognised TLP format for Configuration Requests");
			dynamicAssert(tlpHeader.length != 1, "Configuration Request length must be 1");

			case (tlpHeader.format) matches
				MEM_WRITE_4DW_DATA: begin
					PCIeConfigRegTxn txn;
					txn.address = tlpConfigWrite.header.regNumber;
					txn.data = tlpConfigWrite.data;
					txn.tag = tlpConfigWrite.header.tag;
					txn.id = tlpConfigWrite.header.reqid;
					configmem.writePCIe(txn);
					cfgbpOut <= inboundConfigFilter(txn, cfgbpOut);
					$display("%t: serviceTLP MEM_WRITE_4DW reg %x data %x tag %x", $time, tlpConfigWrite.header.regNumber, tlpConfigWrite.data, tlpConfigWrite.header.tag);
				end
				MEM_READ_3DW_NO_DATA: begin
					PCIeConfigRegTxn txn;
					txn.address = tlpHeader.regNumber;
					txn.tag = tlpHeader.tag;
					txn.data = ?;
					txn.id = tlpHeader.reqid;
					configmem.readPCIe(txn);
					//tagQ.enq(tlpHeader.tag);
					$display("%t: serviceTLP MEM_READ_3DW_DATA reg %x, tag %x", $time, txn.address, txn.tag);
				end
			endcase
		end
		$display("%t: PCIeConfigRegs serviceTLP in = %x, threeDW = %x, truncated = %x, %d bits", $time, tlp.data, threeDW, pack(tlpHeader), valueOf(SizeOfTLPConfig3DWHeader));
	endrule

	
	rule responseTLP;	// the BRAM had a response for us, so generate a completion TLP
		let resp <- configmem.readresponsePCIe();
		// mux in the 'config bypass' pins provided by the Stratix V hard core that need to appear in the right places in the config registers
		let cfgbp_resp = outboundConfigFilter(resp, cfgbpIn);
		$display("%t: PCIeConfigRegs responseTLP rx addr=%x, data=%x, tag=%x, id=%x", $time, resp.address, resp.data, resp.data, resp.id);

		// build a completion packet
		TLPCompletionHeader compl = defaultValue;
		compl.tag = cfgbp_resp.tag;
		compl.reqid = cfgbp_resp.id;
		compl.cstatus = SUCCESSFUL_COMPLETION;
		compl.bytecount = 4;
		compl.data = cfgbp_resp.data;
		// ...then wrap it in the metadata structure
		TLPData#(16) tlpCompl;
		tlpCompl.data = pack(compl);
		tlpCompl.sof = True;
		tlpCompl.eof = True;
		tlpCompl.be = 16'hffff;
		tlpCompl.hit = 7'b0; // not sure what this is for, a Xilinx-ism?
		// send the completion TLP
		tlpOutWide.enq(tlpCompl);
		$display("%t: PCIeConfigRegs responseTLP cfgbp_resp=%x compl=%x tlpCompl=%x", $time, cfgbp_resp, compl, tlpCompl);
	endrule


	method Action bypassInCfgbp(S5PCIeCfgBpToApp cfgIn);
		cfgbpIn <= cfgIn;
	endmethod

	method S5PCIeAppToCfgBp bypassOutCfgbp = cfgbpOut;

	interface avs = avalon.avs;
	interface tlpFeed = toPut(tlpInput);
	interface tlpOut = toGet(tlpOutput);
endmodule
