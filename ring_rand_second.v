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


module ring_rand_second(
    input clk,
    input rst,

    input [3:0] din,
    input wr_en,    

    output [3:0] dout,
    input rd_en,
    output ready,
    output [6:0] index,
    output [7:0] count,

    // random access
    input [6:0] rand_rd_addr,
    input rand_rd_en,
    output rand_rd_valid
    );


    // BRAM
    wire [6:0] bram_wr_addr;
    wire [6:0] bram_rd_addr;
    wire bram_wr_en;
    wire bram_rd_en;
    wire [3:0] bram_dout;
    wire [3:0] bram_din;
    reg bram_valid;
    
    // Random access
    reg rand_busy;
    reg [1:0] rand_cnt;
    reg [6:0] rand_addr_buf;

    wire ring_en;
    reg ring_busy;
    wire updated;
    wire next;
    reg next_buf_0;
    reg next_buf_1;
    reg [1:0] bram_cnt;
    
    reg [7:0] ring_counter;
    reg [7:0] ring_counter_buf;
    reg [6:0] read_counter;
    
    reg [3:0] buf_0; // front
    reg [3:0] buf_1; // middle
    reg [3:0] buf_2; // back
    reg [3:0] buf_cnt;
    reg [3:0] buf_state;
    wire buf_next;

    assign count = ring_counter;

    // indexing
    wire [6:0] read_counter_1;
    wire [6:0] read_counter_2;
    wire [6:0] read_counter_3;

    bram_ring_second brs_inst (
      .clka(clk),
      .ena(bram_wr_en),
      .wea(bram_wr_en),
      .addra(bram_wr_addr),
      .dina(bram_din),
      .clkb(clk),
      .enb(bram_rd_en),
      .addrb(bram_rd_addr),
      .doutb(bram_dout)
    );
    
    // rand_busy, rand_cnt
    always @(posedge clk) begin
        if (rst) begin
            rand_busy <= 1'b0;
            rand_cnt <= 2'b00;
        end else begin
            if (rand_busy) begin
                if (rand_cnt == 2'b11) begin
                    rand_busy <= 1'b0;
                    rand_cnt <= 2'b00;
                end else begin
                    rand_cnt <= rand_cnt + 2'b01;
                end
            end else if (~ring_busy & rand_rd_en) begin
                rand_busy <= 1'b1;
                rand_cnt <= 2'b01;
                rand_addr_buf <= rand_rd_addr;
            end
        end
    end
    // rand_rd_valid
    assign rand_rd_valid = (rand_cnt == 2'b11);


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
    
    // Ring write logic
    assign bram_wr_en = wr_en;
    assign bram_din = din;
    assign bram_wr_addr = ring_counter;

    // Ring enable signal
    assign ring_en = rand_busy? 1'b0:rd_en;

    // Ring buffering
    always @(posedge clk) begin
        if (rst | updated) begin
            buf_state <= 0;
            buf_0 <= 0;
            buf_1 <= 0;
            buf_2 <= 0;
            buf_cnt <= 0;
            ring_busy <= 1'b1;
        end else begin
            case (buf_state)
                4'b0000: begin // init
                    ring_busy <= 1'b1;
                    buf_0 <= buf_1;
                    buf_1 <= buf_2;
                    buf_2 <= bram_dout;
                    buf_cnt <= buf_cnt + 1;
                    if (buf_cnt == 4) begin
                        buf_state <= 4'b1111;
                    end
                end
                4'b1111: begin // full
                    if (ring_en) begin
                        ring_busy <= 1'b1;
                        buf_0 <= buf_1;
                        buf_1 <= buf_2;
                        buf_2 <= bram_dout;
                        buf_state <= 4'b1110;
                     end else begin
                        ring_busy <= 1'b0;
                     end
                end
                4'b1110: begin // buf_2 empty
                    if (ring_en) begin
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
                    if (ring_en) begin
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
                    if (ring_en) begin
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
    assign ready = rand_busy? 1'b0: (buf_state != 4'b0000);
    
    // output selector
    assign dout = (rand_cnt == 2'b11)? bram_dout : buf_0;
    
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

    // bram read address
    assign bram_rd_addr = (rand_cnt == 2'b01)? rand_addr_buf : read_counter;
    
    // next
    assign next = ring_en? 1'b1: buf_next;
    always @(posedge clk) begin
        next_buf_0 <= next;
        next_buf_1 <= next_buf_0;
    end

    always @(posedge clk)
        bram_valid <= next_buf_1;
    
    // bram_rd_en
    assign bram_rd_en = 1'b1;
    
    // indexing
    assign read_counter_1 = (read_counter == 0)?(ring_counter - 1):(read_counter - 1);
    assign read_counter_2 = (read_counter_1 == 0)?(ring_counter - 1):(read_counter_1 - 1);
    assign read_counter_3 = (read_counter_2 == 0)?(ring_counter - 1):(read_counter_2 - 1);
    assign index = read_counter_3;

endmodule
