import MMRingBuffer::*;
import AvalonST::*;

interface MMRingBufferTB;
endinterface

module mkMMRingBufferTB(MMRingBufferTB);
    MMRingBufferSink tbsink <- mkMMRingBufferSink;
//   MMRingBufferSource source <- mkMMRingBufferSource;

    rule print;
        $display("Hello world\n");
    endrule

    rule sink_in;
        DataWord data = unpack(64'hdeadbeefcafebabe); 
        tbsink.asi.asi(data, False, False, False, 8'hff, 8'h00);
        //$display("asi_ready = %d", tbsink.sink.asi_ready());
    endrule

endmodule
