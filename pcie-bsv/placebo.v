module placebo(
	input [63:0] asi_data,
	input asi_valid,
	output asi_ready,
	input asi_startofpacket,
	input asi_endofpacket,
	input asi_error,
	input clock_clk,
	input clock_rst_n,

	output [63:0] aso_data,
	output aso_valid,
	input aso_ready,
	output aso_startofpacket,
	output aso_endofpacket,
	output aso_error
);

assign aso_data = asi_data;
assign aso_valid = asi_valid;
assign asi_ready = aso_ready;
assign aso_startofpacket = asi_startofpacket;
assign aso_endofpacket = asi_endofpacket;
assign aso_error = asi_error;

endmodule