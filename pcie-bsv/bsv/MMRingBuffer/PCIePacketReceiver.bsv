// PCIeBuffer.bsv

import AvalonSTPCIe::*;
import AvalonMM::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;
import FIFOF::*;
import PCIE::*;

typedef Bit#(32) DataType;
typedef Bit#(8) AddressType;
typedef 0 BurstWidth;
typedef 1 ByteEnable;

interface PCIePacketReceiver;
    interface AvalonSinkExtPCIe streamSink;
    interface AvalonSlaveExt#(DataType, AddressType, BurstWidth, ByteEnable) mmSlave;
endinterface: PCIePacketReceiver

module mkPCIePacketReceiver(PCIePacketReceiver);
    AvalonSinkPCIe streamToFIFO <- mkAvalonSinkPCIe;
    AvalonSlave#(DataType, AddressType, BurstWidth, ByteEnable) slave <- mkAvalonSlave;
    Reg#(PCIeWord) currentpcieword <- mkReg(unpack(0));
    Reg#(Bool) next <- mkReg(True);
    FIFOF#(PCIeWord) rxfifo <- mkUGSizedFIFOF(64);

    rule serviceMMSlave;
        AvalonMMRequest#(DataType, AddressType, BurstWidth, ByteEnable) req <- slave.client.request.get();
        AvalonMMResponse#(DataType) response = 32'hdeadbeef;
        $display("request");
        if (req matches tagged AvalonRead { address:.address, byteenable:.be, burstcount:.burstcount})
        begin
            $display("read %x",address);
            case (address)
                0:  begin
                        response = rxfifo.first().data[31:0];
                        $display("trigger pcieword=%x", rxfifo.first()); 
                        if (rxfifo.notEmpty)
                            rxfifo.deq();
                    end
                1:  begin
                        response = rxfifo.first().data[63:32];
                    end
                2:  begin
                        response = {6'b0, pack(rxfifo.first().eof), pack(rxfifo.first().sof), rxfifo.first().be, 8'b0, 8'b0}; //rxfifo.first().parity,  rxfifo.first().bar};
                    end
                3:  begin
                        response = signExtend(pack(rxfifo.notEmpty));
                    end
            endcase
        slave.client.response.put(response);
        end

        else if (req matches tagged AvalonWrite{ writedata:.data, address:.address, byteenable:.be, burstcount:.burstcount})
            $display("write %x",address);
//        $display("address=%x", address);

    endrule

    rule fetchpcieword;
        let pciedata <- streamToFIFO.receive.get();
        //currentpcieword <= pcieword;
        if (rxfifo.notFull)
        begin
            rxfifo.enq(pciedata);
            $display("PCIe word %x arrived", pciedata);
        end else begin
            $display("junked");
        end
        next <= False;
    endrule

    rule nextprint;
        $display("next=%d, rxfifo.empty=%d",next, !rxfifo.notEmpty());
    endrule

    interface streamSink = streamToFIFO.asi;
    interface mmSlave = slave.avs;


endmodule


interface PCIePacketReceiverTB;
endinterface

//typedef Bit#(64) PCIeWord;


module mkPCIePacketReceiverTB(PCIePacketReceiverTB);
//    MMRingBufferSink tbsink <- mkMMRingBufferSink;
//    AvalonSinkPCIe sink <- mkAvalonSinkPCIe;
    PCIePacketReceiver dut <- mkPCIePacketReceiver;
    AvalonMaster#(DataType, AddressType, BurstWidth, ByteEnable) master <- mkAvalonMaster;

    //mkConnection(master.avm, dut.mmSlave);

    Reg#(Int#(32)) tick <- mkReg(0);
    Reg#(Bool) reading <- mkReg(False);
//   MMRingBufferSource source <- mkMMRingBufferSource;

/*    rule print;
        $display("Hello world\n");
    endrule
*/
    rule ticktock;
        tick <= tick + 1;
    endrule

    rule sink_in;
        PCIeWord invalue;
        invalue.data = extend(pack(tick));
        invalue.be = 8'hff;
	invalue.hit = 0;
        //invalue.parity = 0;
        //invalue.bar = 0;
        invalue.sof = True;
        invalue.eof = False; 
//        sink.asi.asi(data, False, False, False, 8'hff, 8'h00);
        dut.streamSink.asi(invalue.data, True, invalue.sof, invalue.eof, invalue.be, 0, 0); //invalue.parity, invalue.bar);

        $display("%d: asi_ready = %d", tick, dut.streamSink.asi_ready());
        if (dut.streamSink.asi_ready)
            $display("%d: Input", tick);
    endrule

    rule ready;
        Bool ready = dut.streamSink.asi_ready();
        $display("%d: Ready = %d", tick, ready);
    endrule

    rule read;
//        AvalonMMRequest#(DataType, AddressType, BurstWidth, ByteEnable) req =
//            tagged AvalonRead { address:8'h12, byteenable:1 };
        Bit#(8) address = extend(pack(tick)[5:3]);
        dut.mmSlave.avs(32'hdeadbeef, address, reading, False, 1, 0);
        reading <= !reading;
        if (reading)
            $display("%d: read request addr %x", tick,address);
    endrule

    rule readdata if (dut.mmSlave.avs_readdatavalid);
        $display("%d: read response %x", tick, dut.mmSlave.avs_readdata());
    endrule

//    rule sink_out;
//        PCIeWord out <- dut.streamSink.receive.get();
//        $display("%d: Output %x", tick, pack(out));
//    endrule

endmodule

