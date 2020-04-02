`timescale 1ps / 1ps

module freq_selector#(
    parameter INPUT_WIDTH = 14
)(
    input [63:0] data_in_0,
    input [63:0] data_in_1,
    input [63:0] data_in_2,
    input [63:0] data_in_3,
    input [13:0] k,


    input clk,
    input resetn,
    input s_valid,
    
    output [63:0] data_out_0,
    output m_valid_0,
    output [63:0] data_out_1,
    output m_valid_1,
    output [63:0] data_out_2,
    output m_valid_2,
    output [63:0] data_out_3,
    output m_valid_3
);

endmodule