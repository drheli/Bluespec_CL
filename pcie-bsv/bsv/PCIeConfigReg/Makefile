BSC=bsc
LIBS=../../
BSCFLAGS=-keep-fires -cross-info -aggressive-conditions -p +:$(LIBS):../MMRingBuffer
VERILOGDEST=../qsys_ip/ConfigRegs

all: $(VERILOGDEST) $(VERILOGDEST)/mkConfigRegMem.v

$(VERILOGDEST):
	mkdir -p $(VERILOGDEST)
	cp *.tcl $(VERILOGDEST)

$(VERILOGDEST)/mkConfigRegMem.v: ConfigRegMem.bsv
	$(BSC) $(BSCFLAGS) -vdir $(VERILOGDEST) -u -verilog -g mkConfigRegMem ConfigRegMem.bsv

# -check-assert
sim:
	$(BSC) $(BSCFLAGS) -u -sim -g mkTLPRxRouterTB TLPRxRouterTB.bsv
#	$(BSC) $(BSCFLAGS) -e mkTLPRxRouterTB -sim -o mkTLPRxRouterTB -g mkTLPRxRouterTB 
	$(BSC) $(BSCFLAGS) -u -sim -g mkTLPPipelineTB TLPPipelineTB.bsv
	$(BSC) $(BSCFLAGS) -e mkTLPPipelineTB -sim -o mkTLPPipelineTB -g mkTLPPipelineTB 
	$(BSC) $(BSCFLAGS) -u -sim -g mkConfigRegMemTB ConfigRegMemTB.bsv
#	$(BSC) $(BSCFLAGS) -e mkConfigRegMemTB -sim -o mkConfigRegMemTB -g mkConfigRegMemTB 
	$(BSC) $(BSCFLAGS) -u -sim -g mkPCIeConfigRegsTB PCIeConfigRegsTB.bsv
#	$(BSC) $(BSCFLAGS) -e mkPCIeConfigRegsTB -sim -o mkPCIeConfigRegsTB -g mkPCIeConfigRegsTB 
	./mkTLPPipelineTB
#	./mkConfigRegMemTB
#	./mkPCIeConfigRegsTB
#	./mkTLPRxRouterTB

sttest:
	$(BSC) $(BSCFLAGS) -u -sim -g mkAvalonSinkTB AvalonSTTB.bsv
	$(BSC) $(BSCFLAGS) -e mkAvalonSinkTB -sim -o mkAvalonSinkTB -g mkAvalonSinkTB 
	$(BSC) $(BSCFLAGS) -u -sim -g mkAvalonSourceTB AvalonSTTB.bsv
	$(BSC) $(BSCFLAGS) -e mkAvalonSourceTB -sim -o mkAvalonSourceTB -g mkAvalonSourceTB 


mkConfigRegMemTB: ConfigRegMemTB.bsv ConfigRegMem.bsv
	$(BSC) $(BSCFLAGS) -u -sim -g mkConfigRegMemTB ConfigRegMemTB.bsv
	$(BSC) $(BSCFLAGS) -e mkConfigRegMemTB -sim -o mkConfigRegMemTB -g mkConfigRegMemTB 
	./mkConfigRegMemTB

mkPCIeConfigRegsTB: PCIeConfigRegsTB.bsv PCIeConfigRegs.bsv
	$(BSC) $(BSCFLAGS) -u -sim -g mkPCIeConfigRegsTB PCIeConfigRegsTB.bsv
	$(BSC) $(BSCFLAGS) -e mkPCIeConfigRegsTB -sim -o mkPCIeConfigRegsTB -g mkPCIeConfigRegsTB 
	./mkPCIeConfigRegsTB

mkAvalonSTTB: AvalonSTTB.bsv AvalonSTPCIe.bsv
	$(BSC) $(BSCFLAGS) -u -sim -g mkAvalonSTTB AvalonSTTB.bsv
	$(BSC) $(BSCFLAGS) -e mkAvaonSTTB -sim -o mkAvalonSTTB -g mkAvalonSTTB 
	./mkAvalonSTTB

.PHONY: clean
clean:
	rm -f  *.cxx *.bi *.bo *.ba *.info *.sched *.h *.o *.so $(VERILOGDEST)/mk*.v *~  >/dev/null
	rm -rf $(VERILOGDEST)
