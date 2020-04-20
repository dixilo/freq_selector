`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: KU HEP
// Engineer: Junya SUZUKI
// 
// Create Date: 2020/03/31 17:02:13
// Design Name: ring_simple
// Module Name: ring_simple
// Project Name: freq_selector
// Target Devices: KCU105
// Tool Versions: Vivado 2018.3
// Description: Test of a simple ring buffer
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module second_fft#(
    parameter DATA_WIDTH = 64,
    parameter N_FREQ = 128,
    parameter DEPTH = 32,
    parameter ASSERT = 2
    )(
        input clk,
        input rst,

        input [DATA_WIDTH-1:0] data_in,
        input [$clog2(DEPTH)-$clog2(ASSERT)-1:0] data_count,
        input [$clog2(N_FREQ)-1:0] data_index_in,
        input data_valid,
        output ready,
        
        output [79:0] data_out,
        output m_valid,
        output m_last,
        output [$clog2(N_FREQ)-1:0] data_index_out,
        output [$clog2(DEPTH)-$clog2(ASSERT)-1:0] k,
        input m_ready,
        
        output dbg_conf_ready
    );
    
    localparam COUNTER_MAX = (DEPTH/ASSERT) - 1;
    // FFT
    wire last;
    wire [79:0] fft_result;
    wire fft_valid;
    wire fft_ready;
    wire fft_last;
    wire [7:0] fft_index;
    
    // FIFO
    wire fifo_full;
    wire fifo_empty;
    wire wr_rst_busy;
    wire rd_rst_busy;

    
    assign data_out = fft_result;
    assign m_valid = fft_valid;
    assign m_last = fft_last;
    assign fft_ready = m_ready;
    assign k = fft_index[$clog2(DEPTH)-$clog2(ASSERT)-1:0];
    
    assign last = (data_count == COUNTER_MAX);
    
    xfft_second fft_inst (
      .aclk(clk),
      .s_axis_config_tdata(8'b0),
      .s_axis_config_tvalid(1'b0),
      .s_axis_config_tready(dbg_conf_ready),
      .s_axis_data_tdata(data_in),
      .s_axis_data_tvalid(data_valid),
      .s_axis_data_tready(ready),
      .s_axis_data_tlast(last),
      .m_axis_data_tdata(fft_result),
      .m_axis_data_tuser(fft_index),
      .m_axis_data_tvalid(fft_valid),
      .m_axis_data_tready(fft_ready),
      .m_axis_data_tlast(fft_last)
    );
    
    fifo_second_index fifo_index (
      .clk(clk),
      .srst(rst),
      .din(data_index_in),
      .wr_en(data_valid),
      .rd_en(fft_valid),
      .dout(data_index_out),
      .full(fifo_full),
      .empty(fifo_empty),
      .wr_rst_busy(wr_rst_busy),
      .rd_rst_busy(rd_rst_busy)
    );
    
endmodule