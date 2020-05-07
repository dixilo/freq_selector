`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;


module test_axi(

    );
    
    parameter STEP_SYS = 100;
    
    reg clk_100MHz;
    reg reset;
    wire dout_mon;
    reg rd_en_first;
    reg rd_en_second;
    design_1_wrapper dut(.*);
    
    design_1_axi_vip_0_0_mst_t  vip_agent;
    
    
    task clk_gen();
        clk_100MHz = 0;
        forever #(STEP_SYS/2) clk_100MHz = ~clk_100MHz;
    endtask
    
    task rst_gen();
        reset = 1;
        rd_en_first = 0;
        rd_en_second = 0;
        #(STEP_SYS*10);
        reset = 0;
    endtask
    
    axi_transaction wr_transaction;
    axi_transaction rd_transaction;
    

    
    initial begin : START_design_1_axi_vip_0_0_MASTER
        fork
            clk_gen();
            rst_gen();
        join_none
        
        #(STEP_SYS*100);
    
        vip_agent = new("my VIP master", test_axi.dut.design_1_i.axi_vip_0.inst.IF);
        vip_agent.start_master();
        #(STEP_SYS*100);
        wr_transaction = vip_agent.wr_driver.create_transaction("write transaction");
        
        for (int i=0; i < 32; i++) begin
            wr_transaction.set_write_cmd(0, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
            wr_transaction.set_data_block({i[3:0] , 2'b0, i[13:0]});
            vip_agent.wr_driver.send(wr_transaction);
        end

        wr_transaction.set_write_cmd(4, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
        wr_transaction.set_data_block(32'd1);
        vip_agent.wr_driver.send(wr_transaction);
        
        #(STEP_SYS*500);
        
        // read transaction
        rd_transaction   = vip_agent.rd_driver.create_transaction("read transaction");
        rd_transaction.set_read_cmd(12, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
        vip_agent.rd_driver.send(rd_transaction);

        rd_en_first <= 1;
        rd_en_second <= 1;
        
        #(STEP_SYS*500);
        
        rd_en_first <= 0;
        rd_en_second <= 0;
        
        #(STEP_SYS*100);

        wr_transaction.set_write_cmd(16, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
        wr_transaction.set_data_block(32'd1);
        vip_agent.wr_driver.send(wr_transaction);

        for (int i=0; i < 32; i++) begin
            wr_transaction.set_write_cmd(0, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
            wr_transaction.set_data_block({i[3:0] , 2'b0, i[13:0]});
            vip_agent.wr_driver.send(wr_transaction);
        end

        #(STEP_SYS*200)
        
        rd_en_first <= 1;
        rd_en_second <= 1;

        #(STEP_SYS*100);
        
        rd_en_first <= 0;
        rd_en_second <= 0;

        #(STEP_SYS*10);

        wr_transaction.set_write_cmd(16, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
        wr_transaction.set_data_block(32'd2);
        vip_agent.wr_driver.send(wr_transaction);

        #(STEP_SYS*10);
        
        rd_transaction.set_read_cmd(16, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
        vip_agent.rd_driver.send(rd_transaction);

        #(STEP_SYS*100);
        $finish;
    end
endmodule
