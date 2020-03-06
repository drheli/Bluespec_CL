import PCIeConfigRegs::*;
import StmtFSM::*;
import AvalonMM::*;
import ClientServer::*;
import GetPut::*;



interface PCIeConfigRegsTB_if;
endinterface

function Action doWrite(AvalonMaster#(Bit#(32), Bit#(10), 4, 1) master, Bit#(10) address, Bit#(32) data);
	let result = action
			AvalonMMRequest#(Bit#(32), Bit#(10), 4, 1) request;
			request = tagged AvalonWrite {writedata: data, address: address, byteenable: 4'b1111, burstcount: 1};
			master.server.request.put(request);
			$display("mem[%x] <- %x", address, data);
		endaction;
	return result;
endfunction

function Action doRead(AvalonMaster#(Bit#(32), Bit#(10), 4, 1) master, Bit#(10) address);
	let result = action
				AvalonMMRequest#(Bit#(32), Bit#(10), 4, 1) request;
				request = tagged AvalonRead {address: address, byteenable: 4'b1111, burstcount: 1};
				master.server.request.put(request);
			$display("Read mem[%x]", address);
		endaction;
	return result;
endfunction

function Action checkReadResponse(AvalonMaster#(Bit#(32), Bit#(10), 4, 1) master, Bit#(32) expected);
	let result = action
			let response <- master.server.response.get();
			$display("Read response %x", response);
			if (response == expected)
				$display("PASS");
			else
				$display("FAIL: expected %x, got %x", expected, response);
			//return response;
		endaction;
	return result;
endfunction




module mkPCIeConfigRegsTB(PCIeConfigRegsTB_if);

	PCIeConfigRegs cfg <- mkPCIeConfigRegs;
	AvalonMaster#(Bit#(32), Bit#(10), 4, 1) master <- mkAvalonMaster;
	Reg#(Bool) first <- mkReg(True);

	rule startdump(first);
		$dumpvars;
		first <= False;
	endrule

	rule cfgbp_in;
		cfg.bypassInCfgbp(unpack(0));
	endrule

	Stmt t1 =
		seq
		
			doWrite(master, 10'h13, 32'h12345678);
			doWrite(master, 10'h22, 32'hdeadbeef);
			doWrite(master, 10'h55, 32'hc0ffeefe);
			doRead(master, 10'h22);
			checkReadResponse(master, 32'hdeadbeef);
			doRead(master, 10'h13);
			checkReadResponse(master, 32'h12345678);
			doRead(master, 10'h55);
			checkReadResponse(master, 32'hc0ffeefe);
			$display("Done");
		endseq;

	mkAutoFSM(t1);



	rule connectout;
		cfg.avs.avs(master.avm.avm_writedata, master.avm.avm_address, master.avm.avm_read, master.avm.avm_write, master.avm.avm_byteenable, master.avm.avm_burstcount);
	endrule

	rule connectin;
		master.avm.avm(cfg.avs.avs_readdata, cfg.avs.avs_readdatavalid, cfg.avs.avs_waitrequest);
	endrule

	rule outboundTLPdrain;
		let tlp <- cfg.tlpOut.get();
		$display("PCIe TLP output drain: tlp=%x", tlp);
	endrule

endmodule
