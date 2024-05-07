`timescale 1ns / 1ps

`include "qdma_block_transfer.v"
`include "processor.v"
module testbench;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period in ns

    // Signals
    reg clk;
    reg rst;
    reg DMA_req;
    reg [4:0] words;
    wire drq;
    wire hrq;
    wire start_transfer;
    wire dack;
    wire transfer_done;
    reg [1:0] transfer_type;
    reg [2:0] src_module;
    reg [2:0] dest_module;
    reg [4:0] src_address;
    reg [4:0] dest_address;
    
    integer i;
    // Instantiate modules
    qdma_block_transfer uut (
        .clk(clk),
        .rst(rst),
        .drq(drq),
        .hrq(hrq),
        .start_transfer(start_transfer),
        .dack(dack),
        .transfer_type(transfer_type),
        .src_module(src_module),
        .dest_module(dest_module),
        .src_address(src_address),
        .dest_address(dest_address),
        .words(words),
        .transfer_done(transfer_done)
    );

    processor cpu (
        .clk(clk),
        .rst(rst),
        .DMA_req(DMA_req),
        .drq(drq),
        .hrq(hrq),
        .start_transfer(start_transfer),
        .dack(dack),
        .transfer_done(transfer_done)
    );

    // Clock generation
    always #CLK_PERIOD clk = ~clk;

    // Initializations
    initial
        begin
            $display("Writing to Peripheral-1 Module");
            for (i=0 ; i<15 ; i=i+1)
                uut.peripheral1[i+10] = i + 10;
            $display("Done Loading into Peripheral-1 Module");
        end


    initial begin

        $dumpfile("test.vcd");
        $dumpvars(0,testbench);
        
        clk = 0; // Initialize clock
        rst = 1; // Reset

        #20;
        rst = 0; // Release reset

        transfer_type = 2'b01;
        src_module = 1; // For Peripheral 1
        dest_module = 0; // For Memory 0
        src_address = 5'd10; // Address 10 in Peripheral 1
        dest_address = 5'd15; // Address 15 in Memory 0
        words = 15;

        #10 DMA_req = 1'b1;

        $monitor("DMA_req = %b, drq = %b, hrq = %b, dack = %b, start_transfer = %b, transfer_done = %b, words to be transferred = %d, fifo count = %d",DMA_req,drq,hrq,dack,start_transfer,transfer_done,uut.words_to_be_transferred,uut.fifo_count);
        
        #10000 DMA_req = 1'b0;

        for(i=0; i<10; i=i+1)
            $display("Address = %d, Value = %d",dest_address+i,uut.memory0[dest_address+i]);

        $finish;
    end

endmodule
