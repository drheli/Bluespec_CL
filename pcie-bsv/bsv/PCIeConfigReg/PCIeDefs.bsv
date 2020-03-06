//package PCIeDefs;

import Reserved::*;
import PCIE::*;
import DefaultValue::*;

typedef TLPData#(8) TLP;


typedef struct {
   ReservedZero#(1)        r1;		// TLP Prefix bit
   TLPPacketFormat         format;
   TLPPacketType           pkttype;
   ReservedZero#(1)        r2;		// reserved
   TLPTrafficClass         tclass;
   ReservedZero#(4)        r3;		// R, attr[2], R, TLPProcessingHints
   TLPDigest               digest;
   TLPPoison               poison;
   TLPAttrRelaxedOrdering  relaxed;
   TLPAttrNoSnoop          nosnoop;
   ReservedZero#(2)        r4;		// AT bits
   TLPLength               length;
   PciId                   reqid;
   TLPTag                  tag;
   TLPLastDWBE             lastbe;
   TLPFirstDWBE            firstbe;
   } TLPHeader2DW deriving (Bits, Eq);


typedef struct {
   ReservedZero#(1)        r1;
   TLPPacketFormat         format;
   TLPPacketType           pkttype;
   ReservedZero#(1)        r2;
   TLPTrafficClass         tclass;
   ReservedZero#(4)        r3;
   TLPDigest               digest;
   TLPPoison               poison;
   TLPAttrRelaxedOrdering  relaxed;
   TLPAttrNoSnoop          nosnoop;
   ReservedZero#(2)        r4;
   TLPLength               length;
   PciId                   reqid;
   TLPTag                  tag;
   TLPLastDWBE             lastbe;
   TLPFirstDWBE            firstbe;
   BusNumber               bus;
   DevNumber               dev;
   FuncNumber              func;
   ReservedZero#(4)        r5;
   TLPRegNum               regNumber;
   ReservedZero#(2)        r6;
   } TLPConfig3DWHeader deriving (Bits, Eq);


instance DefaultValue#(TLPConfig3DWHeader);
   defaultValue =
   TLPConfig3DWHeader {
      r1:      unpack(0),
      format:  MEM_WRITE_3DW_DATA,
      pkttype: MEMORY_READ_WRITE,
      r2:      unpack(0),
      tclass:  TRAFFIC_CLASS_0,
      r3:      unpack(0),
      digest:  NO_DIGEST_PRESENT,
      poison:  NOT_POISONED,
      relaxed: STRICT_ORDERING,
      nosnoop: NO_SNOOPING_REQD,
      r4:      unpack(0),
      length:  0,
      reqid:   defaultValue,
      tag:     0,
      lastbe:  0,
      firstbe: 0,
      bus:     0,
      dev:     0,
      func:    0,
      regNumber:    unpack(0),
      r5:      unpack(0),
      r6:      unpack(0)
      };
endinstance


typedef SizeOf#(TLPConfig3DWHeader) SizeOfTLPConfig3DWHeader;

typedef struct {
	TLPConfig3DWHeader header;
	Bit#(32)           data;
  } TLPConfigWrite deriving (Bits, Eq);
