import ClientServer::*;
import GetPut::*;
import BRAM::*;
import PCIE::*;
import FIFOF::*;

Integer memSize = 1024;
typedef Bit#(32) DataT;
typedef Bit#(10) AddressT; 

typedef struct {
        AddressT        address;
        DataT           data;
        PciId           id;
        TLPTag          tag;
} PCIeConfigRegTxn deriving(Bits, Eq);


interface ConfigRegMem;
	method Action writeAvalon(AddressT address, DataT data);
	method Action readAvalon(AddressT address);
	method ActionValue#(DataT) readresponseAvalon;
	method Action writePCIe(PCIeConfigRegTxn txn);
	method Action readPCIe(PCIeConfigRegTxn txn);
	method ActionValue#(PCIeConfigRegTxn) readresponsePCIe;
endinterface

module mkConfigRegMem(ConfigRegMem);
	BRAM2Port#(AddressT, DataT) blockram <- mkBRAM2Server(defaultValue);
	FIFOF#(PCIeConfigRegTxn) txnQ <- mkSizedFIFOF(64);

	method Action writeAvalon(AddressT address, DataT data);
		action
			blockram.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: address, datain: data});
			$display("%t: ConfigRegMem avalon write mem[%x] = %x", $time, address, data);
		endaction
	endmethod

	method Action readAvalon(AddressT address);
		action
			blockram.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: address, datain: ?});
			$display("%t: ConfigRegMem avalon read mem[%x]", $time, address);
		endaction
	endmethod

	method ActionValue#(DataT) readresponseAvalon;
		actionvalue
			let data <- blockram.portA.response.get();
			$display("%t: ConfigRegMem avalon read response = %x", $time, data);
			return data;
		endactionvalue
	endmethod

	method Action writePCIe(PCIeConfigRegTxn txn);
		action
			blockram.portB.request.put(BRAMRequest{write: True, responseOnWrite: False, address: txn.address, datain: txn.data});
			$display("%t: ConfigRegMem pcie write mem[%x] = %x", $time, txn.address, txn.data);
		endaction
	endmethod

	method Action readPCIe(PCIeConfigRegTxn txn);
		action
			blockram.portB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: txn.address, datain: ?});
			txnQ.enq(txn);
			$display("%t: ConfigRegMem pcie read mem[%x]", $time, txn.address);
		endaction
	endmethod

	method ActionValue#(PCIeConfigRegTxn) readresponsePCIe;
		actionvalue
			let data <- blockram.portB.response.get();
			let txn = txnQ.first();
			txnQ.deq();
			$display("%t: ConfigRegMem pcie read response = %x, address=%x, tag=%x", $time, data,txn.address, txn.tag);
			txn.data = data;
			return txn;
		endactionvalue
	endmethod

endmodule

