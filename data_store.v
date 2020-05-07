`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/02 17:08:37
// Design Name: 
// Module Name: data_store
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


module data_store #(
    parameter DATA_WIDTH = 64,
    parameter N_FREQ = 128,
    parameter DEPTH = 32,
    parameter ASSERT = 2
    )(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] data_in,
    input [$clog2(N_FREQ)-1:0] index,
    input valid,
    input rd_en,
    input [$clog2(N_FREQ)+$clog2(DEPTH)-1:0] rd_addr,
    output [DATA_WIDTH-1:0] data_out,
    
    output assert,
    output [$clog2(ASSERT)-1:0] assert_msb,
    output [$clog2(N_FREQ)-1:0] assert_index
    );
    
    localparam logN = $clog2(N_FREQ);
    localparam logD = $clog2(DEPTH);
    // counter
    wire cm_w_valid;
    wire cm_r_valid;
    reg cm_rv_buf_0;
    reg cm_rv_buf_1;
    reg [logN-1:0] index_buf_0;
    reg [logN-1:0] index_buf_1;
    wire [logN-1:0] w_index;
    wire [logD-1:0] cm_dout;
    wire [logD-1:0] cm_din;
    
    // Data storage
    wire [logD+logN-1:0] cur_addr = {cm_dout, w_index};
    integer i;
    reg [DATA_WIDTH-1:0] din_buf_0;
    reg [DATA_WIDTH-1:0] din_buf_1;
    wire [DATA_WIDTH-1:0] dm_din;
    
    always @(posedge clk) begin
        if (rst) begin
            din_buf_0 <= 0;
            din_buf_1 <= 0;
        end else begin
            din_buf_0 <= data_in;
            din_buf_1 <= din_buf_0;
        end
    end
    assign dm_din = din_buf_1;
    
    
    blk_mem_data data_mem (
      .clka(clk),    // input wire clka
      .ena(cm_w_valid),      // input wire ena
      .wea(cm_w_valid),      // input wire [0 : 0] wea
      .addra(cur_addr),  // input wire [11 : 0] addra
      .dina(dm_din),    // input wire [63 : 0] dina
      .clkb(clk),    // input wire clkb
      .enb(rd_en),      // input wire enb
      .addrb(rd_addr),  // input wire [11 : 0] addrb
      .doutb(data_out)  // output wire [63 : 0] doutb
    );
    
    
    // Counter memory
    assign cm_r_valid = valid | cm_rv_buf_0 | cm_rv_buf_1;
    assign cm_w_valid = cm_rv_buf_1;
    
    // valid buffering
    always @(posedge clk) begin
        if (rst) begin
            cm_rv_buf_0 <= 0;
            cm_rv_buf_1 <= 0;
        end else begin
            cm_rv_buf_0 <= valid;
            cm_rv_buf_1 <= cm_rv_buf_0;
        end
    end
    
    // index buffering
    always @(posedge clk) begin
        if (rst) begin
            index_buf_0 <= 0;
            index_buf_1 <= 0;
        end else begin
            index_buf_0 <= index;
            index_buf_1 <= index_buf_0;
        end
    end
    assign w_index = index_buf_1;
    assign cm_din = cm_dout + 1;
    
    blk_mem_counter counter_mem (
      .clka(clk),    // input wire clka
      .ena(cm_w_valid),      // input wire ena
      .wea(cm_w_valid),      // input wire [0 : 0] wea
      .addra(w_index),  // input wire [6 : 0] addra
      .dina(cm_din),    // input wire [4 : 0] dina
      .clkb(clk),    // input wire clkb
      .enb(cm_r_valid),      // input wire enb
      .addrb(index),  // input wire [6 : 0] addrb
      .doutb(cm_dout)  // output wire [4 : 0] doutb
    );
    
    // assert
    assign assert = (cm_din[logD-1:logD-$clog2(ASSERT)] != cm_dout[logD-1:logD-$clog2(ASSERT)]) && (cm_w_valid);
    assign assert_msb = cm_dout[logD-1:logD-$clog2(ASSERT)];
    assign assert_index = w_index;
endmodule
