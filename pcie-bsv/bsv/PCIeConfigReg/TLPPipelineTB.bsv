import TLPRxRouter::*;
import PCIeConfigRegs::*;
import PCIE::*;
import PCIeDefs::*;
import GetPut::*;
import Connectable::*;
import FIFOF::*;
import Randomizable::*;
import DefaultValue::*;
import PCIeTestTLP::*;

interface TLPDrain;
        interface Put#(TLP) in;
endinterface

(* synthesize *)
module mkTLPDrain(TLPDrain);
        FIFOF#(TLP) inpipe <- mkFIFOF;

        rule drain;
                inpipe.deq();
                $display("%t: TLPDrain %m: draining value %x", $time, inpipe.first());
        endrule

        interface in = toPut(inpipe);
endmodule


typedef enum {
	MEMORY_READ_32, MEMORY_WRITE_32, MEMORY_READ_64, MEMORY_WRITE_64, CONFIG_READ, CONFIG_WRITE, COMPLETION, MESSAGE
} RandomPacketType deriving (Bits, Eq, Bounded);

interface TLPSource;
	interface Get#(TLPData#(16)) out;
endinterface

module mkRandomTLP(TLPSource);
	Reg#(Bool) resetState <- mkReg(True);
	Reg#(Int#(10)) dataWordsRemaining <- mkReg(0);
	FIFOF#(TLPData#(16)) outpipe <- mkFIFOF;
	Randomize#(RandomPacketType) rndPacketType <- mkGenericRandomizer;
	Randomize#(Bit#(128)) rndDataWords <- mkGenericRandomizer;
	Randomize#(TLPLength) rndLength <- mkGenericRandomizer;
	Randomize#(PciId) rndReqid <- mkGenericRandomizer;
	Randomize#(TLPTag) rndTag <- mkGenericRandomizer;
	Randomize#(TLPFirstDWBE) rndFirstbe <- mkGenericRandomizer;
	Randomize#(TLPLastDWBE) rndLastbe <- mkGenericRandomizer;
	Randomize#(DWAddress64) rndAddress64 <- mkGenericRandomizer;
	Randomize#(DWAddress) rndAddress <- mkGenericRandomizer;
	Randomize#(Bit#(32)) rndData <- mkGenericRandomizer;

	rule init(resetState);
		resetState <= False;
		$dumpvars();
		rndDataWords.cntrl.init();
		rndPacketType.cntrl.init();
		rndLength.cntrl.init();
		rndReqid.cntrl.init();
		rndTag.cntrl.init();
		rndFirstbe.cntrl.init();
		rndLastbe.cntrl.init();
		rndAddress64.cntrl.init();
		rndAddress.cntrl.init();
		rndData.cntrl.init();
	endrule


	rule send;
		TLPData#(16) tlp = defaultValue;
		/* XXX: Don't support non-aligned data words */
		if (dataWordsRemaining > 0) begin
			tlp.eof = ( dataWordsRemaining < 5);
			tlp.sof = False;
			tlp.be = 16'hffff;
			tlp.data <- rndDataWords.next();
			outpipe.enq(tlp);
			$display("Random data word[%d] %x", dataWordsRemaining, tlp.data);
			dataWordsRemaining <= (dataWordsRemaining < 5) ? 0 : dataWordsRemaining-4;
		end else begin
			RandomPacketType newPktType <- rndPacketType.next();
			let newLength <- rndLength.next();
			let newReqid <- rndReqid.next();
			let newTag <- rndTag.next();
			let newFirstbe <- rndFirstbe.next();
			let newLastbe <- rndLastbe.next();
			let newAddress64 <- rndAddress64.next();
			let newAddress <- rndAddress.next();
			let newData <- rndData.next();
		case (newPktType) matches
			MEMORY_READ_32: begin
				TLPMemoryIO3DWHeader hdr = memR32tlp( newLength,
					newReqid, newTag,
					newLastbe, newFirstbe,
					newAddress );
				tlp.sof = True;
				tlp.eof = True;
				tlp.be = 16'h0fff;
				tlp.data = pack(hdr);
				outpipe.enq(tlp);
				dataWordsRemaining <= 0;
				$display("Memory read 32 len=%x, reqid=%x, tag=%x, lastbe=%x, firstbe=%x, addr=%x, tlp.data=%x", newLength, newReqid, newTag, newLastbe, newFirstbe, newAddress, tlp.data);
				end	
			MEMORY_READ_64: begin
				TLPMemory4DWHeader hdr = memR64tlp( newLength,
					newReqid, newTag,
					newLastbe, newFirstbe,
					newAddress64 );
				tlp.sof = True;
				tlp.eof = True;
				tlp.be = 16'h0fff;
				tlp.data = pack(hdr);
				outpipe.enq(tlp);
				dataWordsRemaining <= 0;
				$display("Memory read 64 len=%x, reqid=%x, tag=%x, lastbe=%x, firstbe=%x, addr=%x, tlp.data=%x", newLength, newReqid, newTag, newLastbe, newFirstbe, newAddress64, tlp.data);
				end	
			MEMORY_WRITE_32: begin
				TLPMemoryIO3DWHeader hdr = memW32tlp( newLength,
					newReqid, newTag,
					newLastbe, newFirstbe,
					newAddress, newData );
				tlp.sof = True;
				tlp.eof = (newLength < 2);
				tlp.be = 16'hffff;
				tlp.data = pack(hdr);
				outpipe.enq(tlp);
				Int#(10) len = unpack(pack(newLength));
				dataWordsRemaining <= (len == 0) ? 0 : len-1;
				$display("Memory write 32 len=%x, reqid=%x, tag=%x, lastbe=%x, firstbe=%x, addr=%x, data=%x, tlp.data=%x, dataWords=%x", newLength, newReqid, newTag, newLastbe, newFirstbe, newAddress, newData, tlp.data, dataWordsRemaining);
				end	
			MEMORY_WRITE_64: begin
				TLPMemory4DWHeader hdr = memW64tlp( newLength,
					newReqid, newTag,
					newLastbe, newFirstbe,
					newAddress64 );
				tlp.sof = True;
				tlp.eof = False;
				tlp.be = 16'hffff;
				tlp.data = pack(hdr);
				outpipe.enq(tlp);
				dataWordsRemaining <= unpack(pack(newLength));
				$display("Memory write 64 len=%x, reqid=%x, tag=%x, lastbe=%x, firstbe=%x, addr=%x, data=%x, tlp.data=%x, dataWords=%x", newLength, newReqid, newTag, newLastbe, newFirstbe, newAddress64, newData, tlp.data, dataWordsRemaining);
				end
			default: begin
				$display("Unknown packet type %x, ignoring", newPktType);
				end	
		endcase	
		end
	endrule

	interface out = toGet(outpipe);
endmodule


interface TLPPipelineTB;
endinterface

module mkTLPPipelineTBnoisepkt(TLPPipelineTB);

	TLPRxRouter router <- mkTLPRxRouter;
	PCIeConfigRegs conf <- mkPCIeConfigRegs;
	Randomize#(Bit#(81)) randomTLP <- mkGenericRandomizer;
	Reg#(Bool) resetState <- mkReg(True);

	TLPDrain drainConf <- mkTLPDrain;
	TLPDrain drainMem <- mkTLPDrain;
	TLPDrain drainAll <- mkTLPDrain;

	mkConnection(drainConf.in, router.conf);
	mkConnection(drainMem.in, router.memory);
	mkConnection(drainAll.in, router.all);
	mkConnection(conf.tlpFeed, router.conf);

	rule initialise(resetState);
		randomTLP.cntrl.init();
		resetState <= False;
	endrule

	rule fillRandom;
		let random <- randomTLP.next();
		router.in.put(unpack(random));
		$display("%x: TLPPipelineTB - pushing %x into head of pipeline", $time, random);
	endrule

        rule outboundTLPdrain;
                let tlp <- conf.tlpOut.get();
                $display("PCIe TLP output drain: tlp=%x", tlp);
        endrule

/*
	TLPDrain drainTest <- mkTLPDrain;
	rule drainTester;
		let random <- randomTLP.next();
		drainTest.in.put(unpack(random));
//		TLP testword = unpack(81'h1234567890);
//		drainTest.in.put(testword);
	endrule
*/	
endmodule


module mkTLPPipelineTB(TLPPipelineTB);

	TLPRxRouter router <- mkTLPRxRouter;
	TLPSource source <- mkRandomTLP;
	PCIeConfigRegs conf <- mkPCIeConfigRegs;
	Randomize#(Bit#(81)) randomTLP <- mkGenericRandomizer;
	Reg#(Bool) resetState <- mkReg(True);
	

	TLPDrain drainConf <- mkTLPDrain;
	TLPDrain drainMem <- mkTLPDrain;
	TLPDrain drainAll <- mkTLPDrain;

//	mkConnection(drainConf.in, router.conf);
	mkConnection(drainMem.in, router.memory);
	mkConnection(drainAll.in, router.all);
	mkConnection(conf.tlpFeed, router.conf);
        
	mkConnection(router.in, source.out);


	rule outboundTLPdrain;
                let tlp <- conf.tlpOut.get();
                $display("PCIe TLP output drain: tlp=%x", tlp);
        endrule

/*
	TLPDrain drainTest <- mkTLPDrain;
	rule drainTester;
		let random <- randomTLP.next();
		drainTest.in.put(unpack(random));
//		TLP testword = unpack(81'h1234567890);
//		drainTest.in.put(testword);
	endrule
*/	
endmodule
