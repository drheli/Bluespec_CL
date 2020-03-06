import Reserved::*;
import DefaultValue::*;
import PCIE::*;
import FIFOF::*;
import GetPut::*;
import PCIeDefs::*;

typedef enum { None, Config, Memory, Completion, Msg, Other, Blackhole } DestinationQueue deriving(Bits, Eq);




/* Get put from the perspective of the customer, not us */

interface TLPRxRouter;
	interface Put#(TLP) in;
	interface Get#(TLP) conf;
	interface Get#(TLP) memory;
	interface Get#(TLP) all;
endinterface


module mkTLPRxRouter(TLPRxRouter);

	FIFOF#(TLP) tlpIn <- mkFIFOF;
	FIFOF#(TLP) tlpConf <- mkFIFOF;
	FIFOF#(TLP) tlpMem <- mkFIFOF;
	FIFOF#(TLP) tlpAll <- mkFIFOF;

	Reg#(DestinationQueue) destination <- mkReg(None);

	rule dispatch;

		let packet = tlpIn.first();
		tlpIn.deq();

		if (destination != Blackhole)
			tlpAll.enq(packet);
		$display("%t: TLPRxRouter mode was %x", $time, destination);

		if (packet.sof) begin
			$display("%t: TLPRxRouter Start of packet", $time);
			TLPHeader2DW header0 = unpack(packet.data);
			let newdestination = 
				case (header0.pkttype)
					MEMORY_READ_WRITE:	Memory;
					MEMORY_READ_LOCKED:	Memory;
					CONFIG_0_READ_WRITE:	Config;
					CONFIG_1_READ_WRITE:	Config;
					COMPLETION:		Completion;
					COMPLETION_LOCKED:	Completion;
					MSG_ROUTED_TO_ROOT:	Msg;
					MSG_ROUTED_BY_ADDR:	Msg;
					MSG_ROUTED_BY_ID:	Msg;
					MSG_ROOT_BROADCAST:	Msg;
					MSG_LOCAL:		Msg;
					MSG_GATHER:		Msg;
					default:		Other;
				endcase;
			destination <= newdestination;			
			case (newdestination)
				Config: tlpConf.enq(packet);
				default: tlpMem.enq(packet);
			endcase
			$display("%t: TLPRxRouter, first packet of type %x is %x", $time, newdestination, packet);
		end
		else begin
			case (destination)
				Config: begin
					tlpConf.enq(packet);
					$display("%t: TLPRxRouter, config packet %x", $time, packet);
					end
				default: begin 
					$display("%t: TLPRxRouter, %d packet %x", $time, destination, packet);
					tlpMem.enq(packet);
					end
			endcase
		end

		if (packet.eof) begin
			$display("%t: TLPRxRouter End of packet", $time);
		end
		
	endrule

	interface Put in = toPut(tlpIn);
	interface Get conf = toGet(tlpConf);
	interface Get memory = toGet(tlpMem);
	interface Get all = toGet(tlpAll);

endmodule

