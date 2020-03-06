import TLPRxRouter::*;
import Randomizable::*;
import DefaultValue::*;
import PCIE::*;
import GetPut::*;
import PCIeDefs::*;

interface TLPRxRouterTB;
endinterface

//typedef enum { Start, Middle, End } PacketState deriving(Bits, Eq);
Integer packetWords = 8;
Integer tlpDataWidth = 8*8;

module mkTLPRxRouterTB(TLPRxRouterTB);
	TLPRxRouter router <- mkTLPRxRouter;
//	Reg#(PacketState) state <- mkReg(Start);
//	Reg#(TLP) tlp <- mkReg(defaultValue);
	Reg#(Bit#(8)) wordcount <- mkReg(0);
	Randomize#(Bit#(64)) randomData <- mkGenericRandomizer;

	rule newTLP;
		if (wordcount == fromInteger(packetWords))
			wordcount <= 0;
		else
			wordcount <= wordcount + 1;
		TLP newtlp = defaultValue;
		newtlp.eof = (wordcount == fromInteger(packetWords));	
		newtlp.sof = (wordcount == 0);
		let random = 9; //<- randomData.next();
		newtlp.data = random;
		router.in.put(newtlp);
		$display("%t: Put TLP %x into router", $time, newtlp);
	endrule

	rule configDrain;
		TLP tlp <- router.conf.get();
		$display("%t: config TLP received %x", $time, tlp);
	endrule

	rule memDrain;
		TLP tlp <- router.memory.get();
		$display("%t: memory TLP received %x", $time, tlp);
	endrule

	rule allDrain;
		TLP tlp <- router.all.get();
		$display("%t: copy TLP received %x", $time, tlp);
	endrule



endmodule
