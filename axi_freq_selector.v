`timescale 1 ns / 1 ps

    module axi_freq_selector #
    (
        parameter integer C_S00_AXI_DATA_WIDTH = 32,
        parameter integer C_S00_AXI_ADDR_WIDTH = 5
    )
    (
        input wire dev_clk,
        input wire dev_rst,
        input wire [63:0] data_in,
        input wire [13:0] k_in,
        input wire valid_in,
        input wire last_in,

        output wire [79:0] data_out,
        output wire [6:0] index_out,
        output wire valid_out,

      // AXI stream output
        output wire [79:0] m_axis_tdata,
        output wire        m_axis_tvalid,
        input  wire        m_axis_tready,
        output wire [20:0] m_axis_tuser,
        output wire        m_axis_tlast,

        // Is there one or more tones in this Ch?
        output wire en,

        // Ports of Axi Slave Bus Interface S00_AXI
        input wire  s00_axi_aclk,
        input wire  s00_axi_aresetn,
        input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
        input wire [2 : 0] s00_axi_awprot,
        input wire  s00_axi_awvalid,
        output wire  s00_axi_awready,
        input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
        input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
        input wire  s00_axi_wvalid,
        output wire  s00_axi_wready,
        output wire [1 : 0] s00_axi_bresp,
        output wire  s00_axi_bvalid,
        input wire  s00_axi_bready,
        input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
        input wire [2 : 0] s00_axi_arprot,
        input wire  s00_axi_arvalid,
        output wire  s00_axi_arready,
        output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
        output wire [1 : 0] s00_axi_rresp,
        output wire  s00_axi_rvalid,
        input wire  s00_axi_rready
    );

    wire rd_en_first;
    wire rd_en_second;
    wire [6:0] index_first;
    wire [6:0] index_second;
    wire [13:0] k_first;
    wire [3:0] k_second;
    wire bypass_second;

    wire valid_first;
    wire rd_en_ds;
    wire [11:0] rd_addr_ds;
    wire [63:0] data_out_ds;
    wire [63:0] data_out_dt;
    wire assert_ds;
    wire assert_msb;
    wire [6:0] assert_index;

    wire [3:0] data_count_dt;
    wire [6:0] data_index_dt;
    wire data_valid_dt;

    wire ready_sfft;
    wire [79:0] data_sfft_out;
    wire data_sfft_valid;
    wire data_sfft_last;
    wire data_sfft_ready;
    wire [6:0] data_sfft_index;
    wire [3:0] k_sfft;
    wire valid_second;

    wire last_first;
    wire last_second;

    axi_freq_selector_core # ( 
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) axi_freq_selector_core_inst (
        .dev_clk(dev_clk),
        .dev_rst(dev_rst),
        .rd_en_first(rd_en_first),
        .rd_en_second(rd_en_second),
        .index_first(index_first),
        .index_second(index_second),
        .k_first(k_first),
        .k_second(k_second),
        .bypass_second(bypass_second),
        .dout_mon(dout_mon),
        .last_first(last_first),
        .last_second(last_second),
        .en(en),

        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

    assign valid_first = (k_in == k_first) && valid_in;
    assign rd_en_first = valid_first;

    data_store ds_core(
        .clk(dev_clk),
        .rst(dev_rst),
        .data_in(data_in),
        .index(index_first),
        .valid(valid_first),
        .rd_en(rd_en_ds),
        .rd_addr(rd_addr_ds),
        .data_out(data_out_ds),

        .assert(assert_ds),
        .assert_msb(assert_msb),
        .assert_index(assert_index)
    );

    data_transfer dt_core(
        .clk(dev_clk),
        .rst(dev_rst),
        .rd_en(rd_en_ds),
        .rd_addr(rd_addr_ds),
        .data_mem(data_out_ds),
        .assert(assert_ds),
        .assert_msb(assert_msb),
        .assert_index(assert_index),
        .data_out(data_out_dt),
        .data_count(data_count_dt),
        .data_index(data_index_dt),
        .data_valid(data_valid_dt)
    );

    second_fft sf_core(
        .clk(dev_clk),
        .rst(dev_rst),
        .data_in(data_out_dt),
        .data_count(data_count_dt),
        .data_index_in(data_index_dt),
        .data_valid(data_valid_dt),
        .ready(ready_sfft),
        .data_out(data_sfft_out),
        .m_valid(data_sfft_valid),
        .m_last(data_sfft_last),
        .m_ready(data_sfft_ready),
        .data_index_out(data_sfft_index),
        .k(k_sfft)
    );

    assign rd_en_second = data_sfft_last;
    assign valid_second = (k_second == k_sfft) && data_sfft_valid;

    assign data_out = bypass_second ? data_in : data_sfft_out;
    assign valid_out = bypass_second ? valid_first : valid_second;
    assign index_out = bypass_second ? index_first : data_sfft_index;


    assign data_sfft_ready = 1'b1;

    assign m_axis_tdata  = bypass_second ? data_in                : data_sfft_out;
    assign m_axis_tvalid = bypass_second ? (valid_first & en)     : (valid_second & en);
    assign m_axis_tuser  = bypass_second ? {index_first, k_first} : {data_sfft_index, k_first};
    assign m_axis_tlast  = bypass_second ? last_in                : last_second;

endmodule
