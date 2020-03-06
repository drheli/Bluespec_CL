import PCIE::*;
import DefaultValue::*;
import PCIeDefs::*;

//module mkPCITestTLP(PCITestTLP);
function TLPMemory4DWHeader memR64tlp(TLPLength length, PciId reqid,
			TLPTag tag, TLPLastDWBE lastbe,
			TLPFirstDWBE firstbe, DWAddress64 address
		);
	TLPMemory4DWHeader myMem = defaultValue;
	myMem.format = MEM_READ_4DW_NO_DATA;
	myMem.pkttype = MEMORY_READ_WRITE;
	myMem.length =  length;
	myMem.reqid = reqid;
	myMem.tag = tag;
	myMem.lastbe = lastbe;
	myMem.firstbe = firstbe;
	myMem.addr = address;
	return myMem;
endfunction

function TLPMemoryIO3DWHeader memR32tlp(TLPLength length, PciId reqid,
			TLPTag tag, TLPLastDWBE lastbe,
			TLPFirstDWBE firstbe, DWAddress address
		);
	TLPMemoryIO3DWHeader myMem = defaultValue;
	myMem.format = MEM_READ_3DW_NO_DATA;
	myMem.pkttype = MEMORY_READ_WRITE;
	myMem.length =  length;
	myMem.reqid = reqid;
	myMem.tag = tag;
	myMem.lastbe = lastbe;
	myMem.firstbe = firstbe;
	myMem.addr = address;
	return myMem;
endfunction

function TLPMemory4DWHeader memW64tlp(TLPLength length, PciId reqid,
			TLPTag tag, TLPLastDWBE lastbe,
			TLPFirstDWBE firstbe, DWAddress64 address
		);
	TLPMemory4DWHeader myMem = defaultValue;
	myMem.format = MEM_WRITE_4DW_DATA;
	myMem.pkttype = MEMORY_READ_WRITE;
	myMem.length =  length;
	myMem.reqid = reqid;
	myMem.tag = tag;
	myMem.lastbe = lastbe;
	myMem.firstbe = firstbe;
	myMem.addr = address;
	return myMem;
endfunction



function TLPMemoryIO3DWHeader memW32tlp(TLPLength length, PciId reqid,
			TLPTag tag, TLPLastDWBE lastbe,
			TLPFirstDWBE firstbe, DWAddress address,
			Bit#(32) data
		);
	TLPMemoryIO3DWHeader myMem = defaultValue;
	myMem.format = MEM_WRITE_3DW_DATA;
	myMem.pkttype = MEMORY_READ_WRITE;
	myMem.length =  length;
	myMem.reqid = reqid;
	myMem.tag = tag;
	myMem.lastbe = lastbe;
	myMem.firstbe = firstbe;
	myMem.addr = address;
	myMem.data = data;
	return myMem;
endfunction

function TLPCompletionHeader compltlp(
			TLPCompletionStatus status,
			PciId cmplid, PciId reqid,
			TLPTag tag,
			TLPByteCount bytecount, TLPByteCountModified bcm,
			TLPLowerAddr loweraddr
		);
	TLPCompletionHeader myCompl = defaultValue; 
	myCompl.cstatus = status;
	myCompl.cmplid = cmplid;
	myCompl.reqid = reqid;
	myCompl.tag = tag;
	myCompl.bytecount = bytecount;
	myCompl.bcm = bcm;
	myCompl.loweraddr = loweraddr;
	return myCompl;
endfunction

function TLPMSIHeader msitlp(
			TLPLength length, PciId reqid,
			TLPTag tag, TLPMessageCode msgcode,
			DWAddress64 address
		);
	TLPMSIHeader mymsi = defaultValue;
	mymsi.length = length;
	mymsi.reqid = reqid;
	mymsi.tag = tag;
	mymsi.msgcode = msgcode;
	mymsi.address = address;
	return mymsi;
endfunction

function TLPConfig3DWHeader configtlp(
			TLPLength length, PciId reqid, TLPTag tag,
			TLPLastDWBE lastbe, TLPFirstDWBE firstbe,
			BusNumber bus, DevNumber dev, FuncNumber func,
			TLPRegNum regNumber
		);
	TLPConfig3DWHeader myconf = defaultValue;
	myconf.length = length;
	myconf.tag = tag;
	myconf.reqid = reqid;
	myconf.lastbe = lastbe;
	myconf.firstbe = firstbe;
	myconf.bus = bus;
	myconf.dev = dev;
	myconf.func = func;
	myconf.regNumber = regNumber;	
	return myconf;
endfunction


