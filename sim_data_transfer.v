`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/02 17:26:36
// Design Name: 
// Module Name: sim_data_store
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


module sim_data_transfer(

    );
    
    reg clk;
    reg rst;
    reg [63:0] data_in;
    reg [6:0] index;
    reg valid;
    
    wire rd_en;
    wire [11:0] rd_addr;
    wire [63:0] data_mem;
    wire [63:0] data_out;
    wire [6:0] assert_index;
    wire [6:0] data_index;
    wire [3:0] data_count;
    wire assert;
    wire assert_msb;
    wire data_valid;
    
    
    data_store ds_core(
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .index(index),
        .valid(valid),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .data_out(data_mem),
        .assert(assert),
        .assert_msb(assert_msb),
        .assert_index(assert_index)
        );

    data_transfer dt_core(
        .clk(clk),
        .rst(rst),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .data_mem(data_mem),
        .assert(assert),
        .assert_msb(assert_msb),
        .assert_index(assert_index),
        .data_out(data_out),
        .data_count(data_count),
        .data_index(data_index),
        .data_valid(data_valid)
    );
       
    parameter CLK = 4000; // ps
    initial begin
        clk = 1'b1;
    end

    always #(CLK/2) begin
        clk  <= ~clk;
    end
    
    // Write
    reg write_fin;
    reg read_fin;
    reg write_start;
    integer i;

    initial begin
        rst = 1'b0;
        data_in = 0;
        index = 0;
        valid = 0;
        
        write_fin = 1'b0;
        read_fin = 1'b0;
        write_start = 1'b0;

        #(CLK*10);
        rst = 1'b1;
        #(CLK*10);
        rst = 1'b0;
        #(CLK*20);
        write_start = 1'b1;
    end
    
    reg [63:0] d_cnt = 0;
    wire w_fin_cond = (d_cnt == 8196);
     
    
    always @(posedge clk) begin
        if (write_start & ~w_fin_cond) begin
            valid <= 1'b1;
            data_in <= d_cnt;
            index <= d_cnt % 128;
            d_cnt <= d_cnt + 1;
        end else if (w_fin_cond) begin
            write_fin <= 1'b1;
            valid <= 1'b0;
        end
    end
    
    reg [1:0] read_stage = 0;
    reg [5:0] wait_counter = 0;
    reg [63:0] r_cnt = 0;
    wire r_fin_cond = (r_cnt == 8196);
    
    always @(posedge clk) begin
        if (write_fin) begin
            case (read_stage)
            0: begin
                if (wait_counter == 5'b11111)
                    read_stage <= 1;
                else
                    wait_counter <= wait_counter + 1;
            end
            1: begin
                // rd_en <= 1'b1;
                if (~r_fin_cond) begin
                    //rd_addr <= r_cnt;
                    r_cnt <= r_cnt + 1;
                end else begin
                    read_stage <= 2;
                end
            end
            2: begin
                if (~read_fin) begin
                end 
                if (wait_counter == 6'b111111)
                    read_stage <= 3;
                else
                    wait_counter <= wait_counter + 1;
            end
            3: $finish;
            default:;
            endcase
        end
    end

endmodule


