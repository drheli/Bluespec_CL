# TCL File Generated by Component Editor 15.0
# Fri Jun 05 21:11:35 BST 2015
# DO NOT MODIFY


# 
# RingBufferSource "RingBufferSource" v1.0
#  2015.06.05.21:11:35
# 
# 

# 
# request TCL package from ACDS 15.0
# 
package require -exact qsys 15.0


# 
# module RingBufferSource
# 
set_module_property DESCRIPTION ""
set_module_property NAME RingBufferSource
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME RingBufferSource
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL mkMMRingBufferSource
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file mkMMRingBufferSource.v VERILOG PATH mkMMRingBufferSource.v TOP_LEVEL_FILE


# 
# parameters
# 


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock csi_clk clk Input 1


# 
# connection point clock_reset
# 
add_interface clock_reset reset end
set_interface_property clock_reset associatedClock clock
set_interface_property clock_reset synchronousEdges DEASSERT
set_interface_property clock_reset ENABLED true
set_interface_property clock_reset EXPORT_OF ""
set_interface_property clock_reset PORT_NAME_MAP ""
set_interface_property clock_reset CMSIS_SVD_VARIABLES ""
set_interface_property clock_reset SVD_ADDRESS_GROUP ""

add_interface_port clock_reset csi_reset_n reset_n Input 1


# 
# connection point aso
# 
add_interface aso avalon_streaming start
set_interface_property aso associatedClock clock
set_interface_property aso associatedReset clock_reset
set_interface_property aso dataBitsPerSymbol 64
set_interface_property aso errorDescriptor ""
set_interface_property aso firstSymbolInHighOrderBits true
set_interface_property aso maxChannel 0
set_interface_property aso readyLatency 0
set_interface_property aso ENABLED true
set_interface_property aso EXPORT_OF ""
set_interface_property aso PORT_NAME_MAP ""
set_interface_property aso CMSIS_SVD_VARIABLES ""
set_interface_property aso SVD_ADDRESS_GROUP ""

add_interface_port aso aso_aso_ready ready Input 1
add_interface_port aso aso_aso_data data Output 64
add_interface_port aso aso_aso_valid valid Output 1
add_interface_port aso aso_aso_eop endofpacket Output 1
add_interface_port aso aso_aso_sop startofpacket Output 1


# 
# connection point data_in_avs
# 
add_interface data_in_avs avalon end
set_interface_property data_in_avs addressUnits WORDS
set_interface_property data_in_avs associatedClock clock
set_interface_property data_in_avs associatedReset clock_reset
set_interface_property data_in_avs bitsPerSymbol 8
set_interface_property data_in_avs burstOnBurstBoundariesOnly false
set_interface_property data_in_avs burstcountUnits WORDS
set_interface_property data_in_avs explicitAddressSpan 0
set_interface_property data_in_avs holdTime 0
set_interface_property data_in_avs linewrapBursts false
set_interface_property data_in_avs maximumPendingReadTransactions 1
set_interface_property data_in_avs maximumPendingWriteTransactions 0
set_interface_property data_in_avs readLatency 0
set_interface_property data_in_avs readWaitTime 1
set_interface_property data_in_avs setupTime 0
set_interface_property data_in_avs timingUnits Cycles
set_interface_property data_in_avs writeWaitTime 0
set_interface_property data_in_avs ENABLED true
set_interface_property data_in_avs EXPORT_OF ""
set_interface_property data_in_avs PORT_NAME_MAP ""
set_interface_property data_in_avs CMSIS_SVD_VARIABLES ""
set_interface_property data_in_avs SVD_ADDRESS_GROUP ""

add_interface_port data_in_avs avs_data_in_avs_readdata readdata Output 64
add_interface_port data_in_avs avs_data_in_avs_readdatavalid readdatavalid Output 1
add_interface_port data_in_avs avs_data_in_avs_waitrequest waitrequest Output 1
add_interface_port data_in_avs avs_data_in_avs_writedata writedata Input 64
add_interface_port data_in_avs avs_data_in_avs_address address Input 9
add_interface_port data_in_avs avs_data_in_avs_read read Input 1
add_interface_port data_in_avs avs_data_in_avs_write write Input 1
add_interface_port data_in_avs avs_data_in_avs_byteenable byteenable Input 8
set_interface_assignment data_in_avs embeddedsw.configuration.isFlash 0
set_interface_assignment data_in_avs embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment data_in_avs embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment data_in_avs embeddedsw.configuration.isPrintableDevice 0


# 
# connection point control_in_avs
# 
add_interface control_in_avs avalon end
set_interface_property control_in_avs addressUnits WORDS
set_interface_property control_in_avs associatedClock clock
set_interface_property control_in_avs associatedReset clock_reset
set_interface_property control_in_avs bitsPerSymbol 8
set_interface_property control_in_avs burstOnBurstBoundariesOnly false
set_interface_property control_in_avs burstcountUnits WORDS
set_interface_property control_in_avs explicitAddressSpan 0
set_interface_property control_in_avs holdTime 0
set_interface_property control_in_avs linewrapBursts false
set_interface_property control_in_avs maximumPendingReadTransactions 1
set_interface_property control_in_avs maximumPendingWriteTransactions 0
set_interface_property control_in_avs readLatency 0
set_interface_property control_in_avs readWaitTime 1
set_interface_property control_in_avs setupTime 0
set_interface_property control_in_avs timingUnits Cycles
set_interface_property control_in_avs writeWaitTime 0
set_interface_property control_in_avs ENABLED true
set_interface_property control_in_avs EXPORT_OF ""
set_interface_property control_in_avs PORT_NAME_MAP ""
set_interface_property control_in_avs CMSIS_SVD_VARIABLES ""
set_interface_property control_in_avs SVD_ADDRESS_GROUP ""

add_interface_port control_in_avs avs_control_in_avs_readdata readdata Output 64
add_interface_port control_in_avs avs_control_in_avs_readdatavalid readdatavalid Output 1
add_interface_port control_in_avs avs_control_in_avs_waitrequest waitrequest Output 1
add_interface_port control_in_avs avs_control_in_avs_writedata writedata Input 64
add_interface_port control_in_avs avs_control_in_avs_address address Input 1
add_interface_port control_in_avs avs_control_in_avs_read read Input 1
add_interface_port control_in_avs avs_control_in_avs_write write Input 1
add_interface_port control_in_avs avs_control_in_avs_byteenable byteenable Input 8
set_interface_assignment control_in_avs embeddedsw.configuration.isFlash 0
set_interface_assignment control_in_avs embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment control_in_avs embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment control_in_avs embeddedsw.configuration.isPrintableDevice 0


# 
# connection point interrupt_sender
# 
add_interface interrupt_sender interrupt end
set_interface_property interrupt_sender associatedAddressablePoint ""
set_interface_property interrupt_sender associatedClock clock
set_interface_property interrupt_sender associatedReset clock_reset
set_interface_property interrupt_sender bridgedReceiverOffset ""
set_interface_property interrupt_sender bridgesToReceiver ""
set_interface_property interrupt_sender ENABLED true
set_interface_property interrupt_sender EXPORT_OF ""
set_interface_property interrupt_sender PORT_NAME_MAP ""
set_interface_property interrupt_sender CMSIS_SVD_VARIABLES ""
set_interface_property interrupt_sender SVD_ADDRESS_GROUP ""

add_interface_port interrupt_sender irq_write irq Output 1

