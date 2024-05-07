`timescale 1ns / 1ps

`include "qdma_continuous_transfer.v"
`include "processor.v"
module testbench;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period in ns

    // Signals
    reg clk;
    reg rst;
    reg DMA_req;
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
    qdma_continuous_transfer uut (
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
            $display("Writing to Memory-2 Module");
            for (i=0 ; i<32 ; i=i+1)
                uut.memory2[i] = i + 1;
            $display("Done Loading into Memory-2 Module");
        end


    initial begin

        $dumpfile("test.vcd");
        $dumpvars(0,testbench);
        
        clk = 0; // Initialize clock
        rst = 1; // Reset

        #20;
        rst = 0; // Release reset

        transfer_type = 2'b00;
        src_module = 2; // For Memory 2
        dest_module = 3; // For Memory 3
        src_address = 5'd10; // Address 10 in Memory2
        dest_address = 5'd15; // Address 15 in Memory3

        #10 DMA_req = 1'b1;

        $monitor("DMA_req = %b, drq = %b, hrq = %b, dack = %b, start_transfer = %b, transfer_done = %b, memory3[15] = %d",DMA_req,drq,hrq,dack,start_transfer,transfer_done,uut.memory3[15]);

        if(transfer_done == 1'b1)
            $display("Done");

        #1000 DMA_req = 1'b0;


        $finish;
    end

endmodule
