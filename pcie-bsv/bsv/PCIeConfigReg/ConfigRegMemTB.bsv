import PCIE::*;
import ConfigRegMem::*;
import StmtFSM::*;

interface ConfigRegMemTB;
endinterface

module mkConfigRegMemTB(ConfigRegMemTB);

	ConfigRegMem mem <- mkConfigRegMem;
	Reg#(PCIeConfigRegTxn) txn <- mkReg(unpack(0));

	Stmt test1 = seq
		mem.writeAvalon(0, 32'h12345678);
		mem.writeAvalon(1, 32'h34);
		mem.writeAvalon(2, 32'h45);
		mem.readAvalon(1);

		action
			let resp <- mem.readresponseAvalon();
			if (resp != 32'h34)
				$display("Expecting read(1) = 0x34, found %x: FAIL", resp);
			else
				$display("Read(1) PASS");
		endaction
		mem.readAvalon(0);
		txn.address <= 0;
		txn.data <= ?;
		txn.tag <= 98;
		txn.id <= unpack(123);
		mem.readPCIe(txn);
		txn.address <= 2;
		txn.tag <= 55;
		mem.readPCIe(txn);
		action
			let resp <- mem.readresponseAvalon();
			if (resp != 32'h12345678)
				$display("Expecting read(2) = 0x12345678, found %x: FAIL", resp);
			else
				$display("Read(2) PASS");
			endaction
		mem.readAvalon(2);
		action
			let resp <- mem.readresponseAvalon();
			if (resp != 32'h45)
				$display("Expecting read(1) = 0x45, found %x: FAIL", resp);
			else
				$display("Read(3) PASS");
		endaction
		action
			let resp <- mem.readresponsePCIe();
				if (resp.data != 32'h12345678 || resp.tag != 98)
				$display("Expecting read(2) = 0x12345678, found data=%x, address=%x, tag=%x: FAIL", resp.data, resp.address, resp.tag);
			else
				$display("PCIe read(4) PASS");
			endaction
		mem.readAvalon(2);
		action
			let resp <- mem.readresponsePCIe();
			if (resp.data != 32'h45 || resp.tag != 55)
				$display("Expecting read(1) = 0x45, found data=%x, address=%x, tag=%x: FAIL", resp.data, resp.address, resp.tag);
			else
				$display("PCIe read(5) PASS");
		endaction

	endseq;


	rule response;
		//$display("Read response received %x", mem.readresponseAvalon());
	endrule

	mkAutoFSM(test1);
endmodule

