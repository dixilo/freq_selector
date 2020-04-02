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


module ring_simple(
    input clk,
    input rst,

    input [13:0] din,
    input wr_en,    

    output [13:0] dout,
    input rd_en,
    output ready
    );
    
    wire [6:0] bram_wr_addr;
    wire [6:0] bram_rd_addr;
    wire bram_wr_en;
    wire bram_rd_en;
    wire [13:0] bram_dout;
    wire [13:0] bram_din;
    reg bram_valid;
    wire updated;
    wire next;
    reg next_buf_0;
    reg next_buf_1;
    reg [1:0] bram_cnt;
    
    reg [7:0] ring_counter;
    reg [7:0] ring_counter_buf;
    reg [6:0] read_counter;
    
    reg [13:0] buf_0; // front
    reg [13:0] buf_1; // middle
    reg [13:0] buf_2; // back
    reg [3:0] buf_cnt;
    reg [3:0] buf_state;
    wire buf_next;
    
    blk_mem_gen_0 fifo_bram (
        .clka(clk),    // input wire clka
        .ena(bram_wr_en),      // input wire ena
        .wea(bram_wr_en),      // input wire [0 : 0] wea
        .addra(bram_wr_addr),  // input wire [6 : 0] addra
        .dina(bram_din),    // input wire [13 : 0] dina
        .clkb(clk),    // input wire clkb
        .enb(bram_rd_en),      // input wire enb
        .addrb(bram_rd_addr),  // input wire [6 : 0] addrb
        .doutb(bram_dout)  // output wire [13 : 0] doutb
    );
    
    // Ring counter
    always @(posedge clk) begin
        if (rst) begin
            ring_counter <= 7'b000000;
        end else begin
            if (bram_wr_en) begin
                ring_counter <= ring_counter + 1;
            end
        end
    end
    
    // Ring counter buf
    always @(posedge clk) begin
        ring_counter_buf <= ring_counter;
    end
    
    assign updated = (ring_counter != ring_counter_buf);
    
    // write logic
    assign bram_wr_en = wr_en;
    assign bram_din = din;
    assign bram_wr_addr = ring_counter;

    always @(posedge clk) begin
        if (rst | updated) begin
            buf_state <= 0;
            buf_0 <= 0;
            buf_1 <= 0;
            buf_2 <= 0;
            buf_cnt <= 0;
        end else begin
            case (buf_state)
                4'b0000: begin // init
                    buf_0 <= buf_1;
                    buf_1 <= buf_2;
                    buf_2 <= bram_dout;
                    buf_cnt <= buf_cnt + 1;
                    if (buf_cnt == 4) begin
                        buf_state <= 4'b1111;
                    end
                end
                4'b1111: begin // full
                    if (rd_en) begin
                        buf_0 <= buf_1;
                        buf_1 <= buf_2;
                        buf_2 <= bram_dout;
                        buf_state <= 4'b1110;
                     end
                end
                4'b1110: begin // buf_2 empty
                    if (rd_en) begin
                        buf_0 <= buf_1;
                        buf_1 <= buf_2;
                        if (bram_valid) begin
                            buf_2 <= bram_dout;
                            buf_state <= 4'b1110;
                        end else
                            buf_state <= 4'b1100;
                    end else begin
                        if (bram_valid) begin
                            buf_state <= 4'b1111;
                        end
                    end
                end
                4'b1100: begin // buf_1 empty
                    if (rd_en) begin
                        buf_0 <= buf_1;
                        if (bram_valid) begin
                            buf_1 <= bram_dout;
                            buf_state <= 4'b1100;
                        end else
                            buf_state <= 4'b1000;
                    end else begin
                        if (bram_valid) begin
                            buf_2 <= bram_dout;
                            buf_state <= 4'b1110; 
                        end
                    end
                end
                4'b1000: begin // buf_0 empty
                    if (rd_en) begin
                        buf_0 <= bram_dout;
                    end else begin
                        buf_1 <= bram_dout;
                        buf_state <= 4'b1100;
                    end
                end
                default: begin
                    buf_state <= 0;
                    buf_0 <= 0;
                    buf_1 <= 0;
                    buf_2 <= 0;
                    buf_cnt <= 0;
                end
            endcase
        end
    end
    
    assign buf_next = (buf_cnt < 3);
    assign ready = buf_state == 4'b0000;
    
    // output selector
    assign dout = buf_0;
    
    // read_counter
    always @(posedge clk) begin
        if (rst | updated) begin
            read_counter <= 6'b000000;
        end else begin
            if (next) begin
                read_counter <= (read_counter == (ring_counter - 1))? 0: (read_counter + 1);
            end
        end
    end
    assign bram_rd_addr = read_counter;
    
    // next
    assign next = rd_en? 1'b1: buf_next;
    always @(posedge clk) begin
        next_buf_0 <= next;
        next_buf_1 <= next_buf_0;
    end

    always @(posedge clk)
        bram_valid <= next_buf_1;
    
    // bram_rd_en
    assign bram_rd_en = 1'b1;

endmodule
