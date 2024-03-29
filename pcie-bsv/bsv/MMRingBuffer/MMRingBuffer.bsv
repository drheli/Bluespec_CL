//A concurrent ring buffer that supports configarable interrupts.
//Check the rules for reads and writes for interface.
//Default size is 4K.

import ConfigReg :: * ;
import Vector::*;
import GetPut::*;
import ClientServer::*;

import MEM::*;
import AvalonMM::*;
import AvalonST::*;

/* Configure Buffer Here */

typedef 4096 BufferSize;
typedef 1024 DefaultWriteLevel;
typedef 3072 DefaultReadLevel;
typedef UInt#(9) WordAddress;
typedef UInt#(12) ByteAddress;

/* End Config */

typedef Bit#(64) ControlWord;
typedef Vector#(8,Byte) DataWord;
typedef Bit#(8) Byte;
typedef Bit#(16) MaxAddress;

typedef AvalonSlaveExt#(DataWord,WordAddress,0,1) DataAvalonSlaveExt;
typedef AvalonSlave#(DataWord,WordAddress,0,1) DataAvalonSlave;
typedef AvalonSlaveExt#(ControlWord,Bit#(1),0,1) ControlAvalonSlaveExt;
typedef AvalonSlave#(ControlWord,Bit#(1),0,1) ControlAvalonSlave;

typedef enum {None, FillLevel, Manual, Error} InterruptCause //2 bits
     deriving (Eq, Bits);

typedef struct 
{
	Bool enableInterrupt;		//1  bits, 1  bits
	InterruptCause cause;		//2  bits, 3  bits
	Bit#(13) reserved;		//13 bits, 16 bits
	
	MaxAddress interruptLevel; 	//16 bits, 32 bits
 
	MaxAddress in;		//16 bits, 48 bits
	MaxAddress out;		//16 bits, 64 bits 	
	
} Ctl deriving (Bits);

function Ctl unpackDWord(ControlWord w);
	return unpack(w);
endfunction

function ByteAddress toUsed(MaxAddress width) = unpack(width[11:0]);
function MaxAddress toMax(ByteAddress width) = unpack(extend(pack(width)));
function Bit#(3) getByteEnable(ByteAddress addr) = pack(addr)[2:0];
function Vector#(8,Bool) getByteEnableHot(ByteAddress addr) = unpack(1 << getByteEnable(addr));
function WordAddress getWordAddress(ByteAddress addr) = unpack(pack(addr)[11:3]);

function ControlWord formatResponse(
Bool enable, 
InterruptCause cause,
ByteAddress level,
ByteAddress in,
ByteAddress out);
	Ctl control;
	control.enableInterrupt = enable;
	control.cause = cause;
	control.reserved = 0;
	control.interruptLevel = toMax(level);
	control.in = toMax(in);
	control.out = toMax(out);
	return pack(control);
endfunction

function ByteAddress getFill(ByteAddress in, ByteAddress out);
	return in - out;
endfunction

function ByteAddress getSpace(ByteAddress in, ByteAddress out);
	return (fromInteger(valueof(BufferSize))-1) - getFill(in,out);
endfunction

(* always_ready, always_enabled *)
interface BufferReadIfc;
	interface ReadOnly#(ByteAddress) in;
	interface Reg#(ByteAddress) out;

	method Action sendManualInterrupt;
	method Action sendErrorInterrupt;

	method Bool manualInterrupt;
	method Bool errorInterrupt;

	method Action read(WordAddress address);
	method ActionValue#(DataWord) response();
endinterface

(* always_ready, always_enabled *)
interface BufferWriteIfc;
	interface Reg#(ByteAddress) in;
	interface ReadOnly#(ByteAddress) out;

	method Action sendManualInterrupt;
	method Action sendErrorInterrupt;

	method Bool manualInterrupt;
	method Bool errorInterrupt;

	method Action write(WordAddress addr, DataWord writedata, Vector#(8,Bool) byteenable);
endinterface

(* always_ready, always_enabled *)
interface MMRingBufferCore;
	interface BufferReadIfc bufferRead;
	interface BufferWriteIfc bufferWrite;

endinterface

module mkMMRingBufferCore(MMRingBufferCore);

	MemBE#(WordAddress,DataWord) mem <- mkMemBE;
	Reg#(ByteAddress) in <- mkConfigReg(0);
	Reg#(ByteAddress) out <- mkConfigReg(0);

	PulseWire manualReadWire <- mkPulseWire;
	PulseWire errorReadWire <- mkPulseWire;
	PulseWire manualWriteWire <- mkPulseWire;
	PulseWire errorWriteWire <- mkPulseWire;

	interface BufferReadIfc bufferRead;
		interface in = regToReadOnly(in);
		interface out = asReg(out);
		method Action sendManualInterrupt() = manualWriteWire.send();
		method Action sendErrorInterrupt() = errorWriteWire.send();
		method Bool manualInterrupt = manualReadWire;
		method Bool errorInterrupt = errorReadWire;
		method Action read(WordAddress address) = mem.read.put(address);
		method ActionValue#(DataWord) response();
			let resp <- mem.read.get();
			return resp;
		endmethod
	endinterface

	interface BufferWriteIfc bufferWrite;
		interface in = asReg(in);
		interface out = regToReadOnly(out);
		method Action sendManualInterrupt() = manualReadWire.send();
		method Action sendErrorInterrupt() = errorReadWire.send();
		method Bool manualInterrupt = manualWriteWire;
		method Bool errorInterrupt = errorWriteWire;
		method Action write(WordAddress addr, DataWord writedata, Vector#(8,Bool) byteenable);
			mem.write(addr, writedata,byteenable);
		endmethod
	endinterface
endmodule

(* always_ready, always_enabled *)
interface MMReadInterfaceIfc;
	interface DataAvalonSlaveExt avs_data_out ;
	interface ControlAvalonSlaveExt avs_control_out;
	method Bool irq_read;
endinterface

module mkMMReadInterface(BufferReadIfc buffer, MMReadInterfaceIfc ifc);

	DataAvalonSlave slave_data_read <- mkAvalonSlave;
	ControlAvalonSlave slave_control_read <- mkAvalonSlave;

	Reg#(Bool) readEnable <- mkConfigReg(False);
	Reg#(InterruptCause) readInterrupt <- mkConfigReg(None);
	Reg#(ByteAddress) readLevel <- mkConfigReg(fromInteger(valueof(DefaultReadLevel)));

	rule handleInterrupt;
		//Read interrupts:
		Bool exceed = getFill(buffer.in, buffer.out) >= readLevel;

		if(!readEnable) begin
			readInterrupt <= None; end
		else begin
			if(buffer.errorInterrupt) readInterrupt <= Error;
			else if(readInterrupt == None) begin
				if(buffer.manualInterrupt)	
					readInterrupt <= Manual;
				else if(exceed) readInterrupt <= FillLevel;
			end else if(readInterrupt == FillLevel && !exceed) readInterrupt <= None;
		end
	endrule

	rule handleControl_read;
		let read_req <- slave_control_read.client.request.get();
		case (read_req) matches
			tagged AvalonRead { address: 0 } : begin //get read control
				ControlWord readResponse = formatResponse(readEnable, readInterrupt, readLevel, buffer.in, buffer.out);
				slave_control_read.client.response.put(readResponse);
			end
			tagged AvalonWrite { address: 0, writedata: .data, byteenable: .be } : begin //set read control		
				Ctl readControl = unpackDWord(data);
				if(be[7] == 1) begin
					readEnable <= readControl.enableInterrupt;
					if(readControl.cause == Manual) buffer.sendManualInterrupt();
					else if(readControl.cause == Error) buffer.sendErrorInterrupt();
				end
				if(be[5:4] == 3) begin
					if(readControl.interruptLevel != (fromInteger(valueof(BufferSize)-1))) begin
						readLevel <= toUsed(readControl.interruptLevel); end
				end
				if(be[1:0] == 3) begin
					buffer.out <= toUsed(readControl.out);
				end
			end
		endcase
	endrule

	rule handleData_read;
		let req <- slave_data_read.client.request().get();
		case (req) matches
			tagged AvalonRead {address: .addr} : begin
				buffer.read(addr);
			end
		endcase
	endrule

	rule handleData_read_response;
		let resp <- buffer.response();
		slave_data_read.client.response.put(resp);
	endrule

	interface avs_data_out = slave_data_read.avs;
	interface avs_control_out = slave_control_read.avs;
	method Bool irq_read = readInterrupt != None;
endmodule

(* always_ready, always_enabled *)
interface MMWriteInterfaceIfc;
	interface DataAvalonSlaveExt avs_data_in;
	interface ControlAvalonSlaveExt avs_control_in;
	method Bool irq_write;
endinterface

module  mkMMWriteInterface(BufferWriteIfc buffer,MMWriteInterfaceIfc ifc);

	DataAvalonSlave slave_data_write <- mkAvalonSlave;
	ControlAvalonSlave slave_control_write <- mkAvalonSlave;

	Reg#(Bool) writeEnable <- mkConfigReg(False);
	Reg#(InterruptCause) writeInterrupt <- mkConfigReg(None);
	Reg#(ByteAddress) writeLevel <- mkConfigReg(fromInteger(valueof(DefaultWriteLevel)));
	
	rule handleInterrupt;
		//Write interrupts:
		Bool lower = getFill(buffer.in, buffer.out) <= writeLevel;
		if (!writeEnable) begin
			writeInterrupt <= None; end
		else begin
			if(buffer.errorInterrupt)
				writeInterrupt <= Error;
			else if(writeInterrupt == None) begin
				if(buffer.manualInterrupt) writeInterrupt <= Manual;
				else if(lower) writeInterrupt <= FillLevel;
			end else if(writeInterrupt == FillLevel && !lower) writeInterrupt <= None;
		end
	endrule

	rule handleControl_write;
		let write_req <- slave_control_write.client.request.get();
		case (write_req) matches
      		tagged AvalonRead { address: 0 } : begin //get write control
				ControlWord writeReponse = formatResponse(writeEnable, writeInterrupt, writeLevel, buffer.in, buffer.out);
				slave_control_write.client.response.put(writeReponse);
			end
			tagged AvalonWrite { address: 0, writedata: .data, byteenable: .be } : begin //set write control
				Ctl writeControl = unpackDWord(data);
				if(be[7] == 1) begin
					writeEnable <= writeControl.enableInterrupt;
					if(writeControl.cause == Manual) buffer.sendManualInterrupt();
					else if(writeControl.cause == Error) buffer.sendErrorInterrupt();
				end
				if(be[5:4] == 3) begin
					if(writeControl.interruptLevel != 0) begin
					writeLevel <= toUsed(writeControl.interruptLevel); end
				end
				if(be[3:2] == 3) begin
					buffer.in <= toUsed(writeControl.in);
				end						
			end
		endcase	
	endrule

	rule handleData_write;
		let req <- slave_data_write.client.request().get();
		case (req) matches
			tagged AvalonWrite { address: .addr, writedata: .data, byteenable: .be } : begin
        			buffer.write(addr, unpack(pack(data)), toChunks(be));
			end
			tagged AvalonRead {address: .addr} : begin
				slave_data_write.client.response.put(unpack(?));
			end
		endcase
	endrule
	
	method irq_write = writeInterrupt != None;
	interface avs_data_in = slave_data_write.avs;
	interface avs_control_in = slave_control_write.avs;
endmodule

(* always_ready, always_enabled *)
interface MMRingBuffer;

	interface DataAvalonSlaveExt avs_data_out;
	interface DataAvalonSlaveExt avs_data_in;

	interface ControlAvalonSlaveExt avs_control_out;
	interface ControlAvalonSlaveExt avs_control_in;

	interface Bool irq_read;
	interface Bool irq_write;
endinterface

(* synthesize, reset_prefix = "csi_reset_n", clock_prefix = "csi_clk" *)
module mkMMRingBuffer(MMRingBuffer);
	
	MMRingBufferCore core <- mkMMRingBufferCore;

	MMWriteInterfaceIfc writeI <- mkMMWriteInterface(core.bufferWrite);
	MMReadInterfaceIfc readI <- mkMMReadInterface(core.bufferRead);

	interface avs_data_out = readI.avs_data_out;
	interface avs_control_out = readI.avs_control_out;
	interface avs_data_in = writeI.avs_data_in;
	interface avs_control_in = writeI.avs_control_in;
	interface irq_write = writeI.irq_write;
	interface irq_read = readI.irq_read;
endmodule

(* always_ready, always_enabled *)
interface MMRingBufferSink;

	interface AvalonSinkExt#(DataWord) asi;

	interface DataAvalonSlaveExt avs_data_out;
	interface ControlAvalonSlaveExt avs_control_out;

	interface Bool irq_read;
endinterface

(* synthesize, reset_prefix = "csi_reset_n", clock_prefix = "csi_clk" *)
module mkMMRingBufferSink(MMRingBufferSink);

	MMRingBufferCore core <- mkMMRingBufferCore;
	MMReadInterfaceIfc readI <- mkMMReadInterface(core.bufferRead);
	BufferWriteIfc writeI = core.bufferWrite;
	AvalonSink#(DataWord) sink <- mkAvalonSink;

	rule drainSink(writeI.in + 1 != writeI.out);
		DataWord dataVec = newVector;
		Vector#(8, Bool) be = replicate(True);
		dataVec <- sink.receive.get();
//		dataVec[getByteEnable(writeI.in)] <- sink.receive.get();
//		writeI.write(getWordAddress(writeI.in),dataVec,getByteEnableHot(writeI.in));
		writeI.write(getWordAddress(writeI.in),dataVec,be);
		writeI.in <= writeI.in + 8;
	endrule

	interface avs_data_out = readI.avs_data_out;
	interface avs_control_out = readI.avs_control_out;
	interface irq_read = readI.irq_read;
	interface asi = sink.asi;
endmodule

(* always_ready, always_enabled *)
interface MMRingBufferSource;

	interface AvalonSourceExt#(DataWord) aso;

	interface DataAvalonSlaveExt avs_data_in;
	interface ControlAvalonSlaveExt avs_control_in;

	interface Bool irq_write;
endinterface

(* synthesize, reset_prefix = "csi_reset_n", clock_prefix = "csi_clk" *)
module mkMMRingBufferSource(MMRingBufferSource);
	
	MMRingBufferCore core <- mkMMRingBufferCore;
	MMWriteInterfaceIfc writeI <- mkMMWriteInterface(core.bufferWrite);
	BufferReadIfc readI = core.bufferRead;
	AvalonSource#(DataWord) source <- mkAvalonSource;

	Reg#(Bool) init <- mkReg(True);

	rule start(init);
		readI.read(0);
		init <= False;
	endrule

	rule fillSource(!init && (readI.in != readI.out));
		let next = readI.out + 1;
		readI.out <= next;
		readI.read(getWordAddress(next));

		DataWord dataVec <- readI.response();
//		source.send.put(dataVec[getByteEnable(readI.out)]);
		source.send.put(dataVec);
	endrule

	interface avs_data_in = writeI.avs_data_in;
	interface avs_control_in = writeI.avs_control_in;
	interface irq_write = writeI.irq_write;
	interface aso = source.aso;

endmodule
