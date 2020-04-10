`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/09 15:24:37
// Design Name: 
// Module Name: data_transfer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module data_transfer #(
    parameter DATA_WIDTH = 64,
    parameter N_FREQ = 128,
    parameter DEPTH = 32,
    parameter ASSERT = 2
    )(
    input clk,
    input rst,
    
    output rd_en,
    output [$clog2(N_FREQ)+$clog2(DEPTH)-1:0] rd_addr,
    input [DATA_WIDTH-1:0] data_mem,
    
    input assert,
    input [$clog2(ASSERT)-1:0] assert_msb,
    input [$clog2(N_FREQ)-1:0] assert_index,
    
    output [DATA_WIDTH-1:0] data_out,
    output [$clog2(DEPTH)-$clog2(ASSERT)-1:0] data_count,
    output [$clog2(N_FREQ)-1:0] data_index,
    output data_valid
    );
    localparam COUNTER_MAX = (DEPTH/ASSERT) - 1;
    // ASSERT FIFO
    wire [$clog2(ASSERT)+$clog2(N_FREQ)-1:0] assert_info_in;
    wire [$clog2(ASSERT)+$clog2(N_FREQ)-1:0] assert_info_out;
    wire fifo_rd_en;
    wire fifo_wr_en;
    wire fifo_full;
    wire fifo_empty;
    
    // READ LOGIC
    wire read_busy;
    reg rb_buf_0;
    reg rb_buf_1;
    reg [$clog2(DEPTH)-$clog2(ASSERT)-1:0] read_counter;
    reg [$clog2(DEPTH)-$clog2(ASSERT)-1:0] rc_buf_0;
    reg [$clog2(DEPTH)-$clog2(ASSERT)-1:0] rc_buf_1;
    reg [$clog2(N_FREQ)-1:0] di_buf_0;
    reg [$clog2(N_FREQ)-1:0] di_buf_1;
        
        
    // assert fifo 
    assign assert_info_in = {assert_msb, assert_index};  
    assign fifo_wr_en = assert;
    fifo_assert fifo_assert_inst (
      .clk(clk),                  // input wire clk
      .srst(rst),                // input wire srst
      .din(assert_info_in),                  // input wire [7 : 0] din
      .wr_en(fifo_wr_en),              // input wire wr_en
      .rd_en(fifo_rd_en),              // input wire rd_en
      .dout(assert_info_out),                // output wire [7 : 0] dout
      .full(fifo_full),                // output wire full
      .empty(fifo_empty),              // output wire empty
      .wr_rst_busy(),  // output wire wr_rst_busy
      .rd_rst_busy()  // output wire rd_rst_busy
    );  

    // read logic
    assign read_busy = ~fifo_empty;
    assign fifo_rd_en = (read_counter == COUNTER_MAX);
    assign rd_en = 1'b1;
    assign rd_addr = {assert_info_out[$clog2(ASSERT)+$clog2(N_FREQ)-1:$clog2(N_FREQ)],
                      read_counter,
                      assert_info_out[$clog2(N_FREQ)-1:0]};
    
    always @(posedge clk) begin
        if (rst) begin
            read_counter <= 0;
        end else begin
            if (read_busy) begin
                read_counter <= read_counter + 1; 
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            rb_buf_0 <= 0;
            rb_buf_1 <= 0;
        end else begin
            rb_buf_0 <= read_busy;
            rb_buf_1 <= rb_buf_0;
        end
    end
    
    assign data_valid = rb_buf_1;
    assign data_out = data_mem;
    
    always @(posedge clk) begin
        if (rst) begin
            di_buf_0 <= 0;
            di_buf_1 <= 0;
        end else begin
            di_buf_0 <= assert_info_out[$clog2(N_FREQ)-1:0];
            di_buf_1 <= di_buf_0;
        end
    end
    assign data_index = di_buf_1;
    
    always @(posedge clk) begin
        if (rst) begin
            rc_buf_0 <= 0;
            rc_buf_1 <= 0;
        end else begin
            rc_buf_0 <= read_counter;
            rc_buf_1 <= rc_buf_0;
        end
    end
    assign data_count = rc_buf_1;
endmodule
