
`timescale 1 ns / 1 ps

    module axi_freq_selectore_core #
    (
        parameter integer C_S_AXI_DATA_WIDTH	= 32,
        parameter integer C_S_AXI_ADDR_WIDTH	= 5
    )
    (
        // Users to add ports here
        input wire dev_clk,
        input wire dev_rst,
        input wire rd_en_ring,
        output wire [13:0] dout_mon,
        // User ports ends

        // Global Clock Signal
        input wire  S_AXI_ACLK,
        input wire  S_AXI_ARESETN,

        input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
        // Write channel Protection type. This signal indicates the
            // privilege and security level of the transaction, and whether
            // the transaction is a data access or an instruction access.
        input wire [2 : 0] S_AXI_AWPROT,
        input wire  S_AXI_AWVALID,
        output wire  S_AXI_AWREADY,
        input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
        input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
        input wire  S_AXI_WVALID,
        output wire  S_AXI_WREADY,

        output wire [1 : 0] S_AXI_BRESP,
        output wire  S_AXI_BVALID,
        input wire  S_AXI_BREADY,
        
        input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
        input wire [2 : 0] S_AXI_ARPROT,
        input wire  S_AXI_ARVALID,
        output wire  S_AXI_ARREADY,
        output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
        output wire [1 : 0] S_AXI_RRESP,
        output wire  S_AXI_RVALID,
        input wire  S_AXI_RREADY
    );

    //////////////////////////////////////////////// Signal definitions
    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
    reg                             axi_awready;
    reg                             axi_wready;
    reg [1 : 0]                     axi_bresp;
    reg                             axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
    reg                             axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
    reg [1 : 0]                     axi_rresp;
    reg                             axi_rvalid;

    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 2;

    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg0; // Used to fill the ring buffer for frequency selectors
    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg1;
    //reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg2;
    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg3;
    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg4;
    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg5;
    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg6;
    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg7;
    wire                            slv_reg_rden;
    wire                            slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0]    reg_data_out;
    integer                         byte_index;

    // Specific signals
    reg                             aw_en_org;  // Original aw_en that appears in the template
    wire                            aw_en;      // Expanded aw_en that waits user_wbusy deasserted
    wire                            user_wbusy;
    wire                            user_rbusy;

    //////////////////////////////////////////////// AXI logics
    assign S_AXI_AWREADY    = axi_awready;
    assign S_AXI_WREADY     = axi_wready;
    assign S_AXI_BRESP      = axi_bresp;
    assign S_AXI_BVALID     = axi_bvalid;
    assign S_AXI_ARREADY    = axi_arready;
    assign S_AXI_RDATA      = axi_rdata;
    assign S_AXI_RRESP      = axi_rresp;
    assign S_AXI_RVALID     = axi_rvalid;

    ////////////////////// WRITE
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_awready <= 1'b0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
                axi_awready <= 1'b1;
            else if (S_AXI_BREADY && axi_bvalid)
               axi_awready <= 1'b0;
            else
               axi_awready <= 1'b0;
        end
    end

    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            aw_en_org <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
                aw_en_org <= 1'b0;
            else if (S_AXI_BREADY && axi_bvalid)
                aw_en_org <= 1'b1;
        end
    end

    // Deactivate write transaction if the user logic is busy
    assign aw_en = aw_en_org & (~user_wbusy);

    // axi_awaddr latching
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 )
            axi_awaddr <= 0;
        else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) 
                axi_awaddr <= S_AXI_AWADDR;
        end
    end

    // axi_wready generation
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 )
            axi_wready <= 1'b0;
        else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
                axi_wready <= 1'b1;
            else
                axi_wready <= 1'b0;
        end 
    end

    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            //slv_reg2 <= 0;
            slv_reg3 <= 0;
            slv_reg4 <= 0;
            slv_reg5 <= 0;
            slv_reg6 <= 0;
            slv_reg7 <= 0;
        end else begin
            if (slv_reg_wren) begin
                case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
                3'h0:
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                        if ( S_AXI_WSTRB[byte_index] == 1 )
                            slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                3'h1:
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                        if ( S_AXI_WSTRB[byte_index] == 1 )
                            slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
//                3'h2:
//                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
//                        if ( S_AXI_WSTRB[byte_index] == 1 )
//                            slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                3'h3:
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                        if ( S_AXI_WSTRB[byte_index] == 1 )
                            slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                3'h4:
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                        if ( S_AXI_WSTRB[byte_index] == 1 )
                            slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                3'h5:
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                        if ( S_AXI_WSTRB[byte_index] == 1 )
                            slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                3'h6:
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                        if ( S_AXI_WSTRB[byte_index] == 1 )
                            slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                3'h7:
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                        if ( S_AXI_WSTRB[byte_index] == 1 )
                            slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                default : begin
                    slv_reg0 <= slv_reg0;
                    slv_reg1 <= slv_reg1;
                    //slv_reg2 <= slv_reg2;
                    slv_reg3 <= slv_reg3;
                    slv_reg4 <= slv_reg4;
                    slv_reg5 <= slv_reg5;
                    slv_reg6 <= slv_reg6;
                    slv_reg7 <= slv_reg7;
                end
                endcase
            end
        end
    end

    // write response logic generation
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_bvalid  <= 0;
            axi_bresp   <= 2'b0;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                // indicates a valid write response is available
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0; // 'OKAY' response 
            end else begin
                if (S_AXI_BREADY && axi_bvalid) 
                    axi_bvalid <= 1'b0; 
            end
        end
    end   

    ////////////////////// READ
    // axi_arready generation
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 32'b0;
        end else begin    
            if (~axi_arready && S_AXI_ARVALID && ~user_rbusy) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // axi_arvalid generation
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end else begin    
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;
            end else if (axi_rvalid && S_AXI_RREADY)
                axi_rvalid <= 1'b0;
        end
    end

    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
    always @(*) begin
        case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
            3'h0   : reg_data_out <= slv_reg0;
            3'h1   : reg_data_out <= slv_reg1;
            3'h2   : reg_data_out <= rr_data_buf;
            3'h3   : reg_data_out <= slv_reg3;
            3'h4   : reg_data_out <= slv_reg4;
            3'h5   : reg_data_out <= slv_reg5;
            3'h6   : reg_data_out <= slv_reg6;
            3'h7   : reg_data_out <= slv_reg7;
            default : reg_data_out <= 0;
        endcase
    end

    // Output register or memory read data
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 )
            axi_rdata  <= 0;
        else begin if (slv_reg_rden)
            axi_rdata <= reg_data_out;
        end
    end

    /////////////////////////////////////////////////////////////////// User logic
    wire [13:0] din_ring;
    wire [13:0] dout_ring;
    wire wr_en_ring;
    wire ready_ring;
    wire [6:0] index_ring;
    wire [6:0] rand_rd_addr;
    wire rand_rd_en;
    wire rand_rd_valid;

    wire index_busy;	
    reg index_busy_reg; // S_AXI_ACLK

    wire [OPT_MEM_ADDR_BITS:0] wch = axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
    //////////// reg0: index register
     // buffering
    wire index_written = (wch == 0) & axi_bvalid;
    wire iw_pos_edge;
    reg iw_buf_0;
    reg iw_buf_1;
    reg iw_fin;
    
    assign user_wbusy = index_busy | rr_busy;
    assign user_rbusy = index_busy | rr_busy;
    
    always @(posedge S_AXI_ACLK) begin
       if ( S_AXI_ARESETN == 1'b0 ) begin
           index_busy_reg <= 1'b0;
       end else begin
           if (index_written)
               index_busy_reg <= 1'b1;
           else if (iw_fin)
               index_busy_reg <= 1'b0;
       end
    end
    assign index_busy = (index_written) | index_busy_reg;
    
    // change detection
    always @(posedge dev_clk) begin
       if (dev_rst) begin
           iw_buf_0 <= 0;
           iw_buf_1 <= 0;
       end else begin
           iw_buf_0 <= index_written;
           iw_buf_1 <= iw_buf_0;
       end
    end

    always @(posedge dev_clk) begin
       if (dev_rst) begin
           iw_fin <= 1'b0;
       end else begin
           if (index_busy) begin
               if (iw_pos_edge) begin
                   iw_fin <= 1'b1;
               end else
                   iw_fin <= iw_fin;
           end else
               iw_fin <= 1'b0;
       end
    end

    assign iw_pos_edge = (iw_buf_0 == 1'b1) & (iw_buf_1 == 1'b0);
    assign wr_en_ring = iw_pos_edge;
    assign din_ring = slv_reg0;

    //////////// reg1: random access address
    wire rr_addr_written = (wch == 1) & axi_bvalid;
    wire rr_fin;
    wire rr_busy;
    reg rr_busy_reg;
    reg [6:0] rr_addr_buf;
    reg [2:0] rr_counter;
    reg [13:0] rr_data_buf;

    // random read busy
    always @(posedge S_AXI_ACLK) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            rr_busy_reg <= 1'b0;
        end else begin
            if (rr_addr_written)
                rr_busy_reg <= 1'b1;
            else if (rr_fin)
                rr_busy_reg <= 1'b0;
        end
    end

    assign rr_busy = rr_addr_written | rr_busy_reg;

    // random read stage
    assign rr_fin = (rr_counter == 3'd4);
    always @(posedge dev_clk) begin
        if (dev_rst) begin
            rr_counter <= 3'b0;
        end else begin
            if (rr_busy_reg) begin
                if (rr_counter != 3'd4)
                    rr_counter <= rr_counter + 3'b1;
                else
                    rr_counter <= rr_counter;
            end else
                rr_counter <= 3'b0;
        end
    end

    always @(posedge dev_clk) begin
        if (dev_rst) begin
            rr_addr_buf <= 7'b0;
        end else begin
            rr_addr_buf <= slv_reg1;
        end
    end

    assign rand_rd_addr = rr_addr_buf;

    always @(posedge dev_clk) begin
        if (dev_rst) begin
            rr_data_buf <= 14'b0;
        end else begin
            if (rr_counter == 3'd3) begin
                rr_data_buf <= dout_ring;
            end
        end
    end

    assign rand_rd_en = (rr_counter == 3'd1) | (rr_counter == 3'd2) | (rr_counter == 3'd3);

    //////////// reg2: random access data (read only)

    //////////// reg3: number of data in the ring buffer (read only)

    //////////// reg4: status


    ring_rand ring_freq(
        .clk(dev_clk),
        .rst(dev_rst),
        .din(din_ring),
        .wr_en(wr_en_ring),
        .dout(dout_ring),
        .rd_en(rd_en_ring),
        .ready(ready_ring),
        .index(index_ring),
        // random access
        .rand_rd_addr(rand_rd_addr),
        .rand_rd_en(rand_rd_en),
        .rand_rd_valid(rand_rd_valid)
    );

    // User logic ends

    endmodule
