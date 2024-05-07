module processor (
    input wire clk,
    input wire rst,
    input wire DMA_req,         // DMA Request signal to Outside
    output reg drq,             // DMA Request Signal From CPU to controller
    input wire hrq,             // Hold Request Signal from DMA to CPU
    output reg start_transfer,  // Hold Acknowledgement Signal/Start Transferring Signal from CPU
    input wire dack,            // DMA Acknowledgement Signal
    input wire transfer_done   // Transfer Completion Signal
);

reg [1:0] state;
parameter NORMAL = 2'b00, HOLD_REQ = 2'b01, HOLD = 2'b10;


always @(posedge clk ) begin
    if(rst) begin
        drq <= 0;
        start_transfer <=0;
        state <= NORMAL;
    end
    else begin
        case (state)
            // The CPU is normal computation State occupying the Memory buses
            NORMAL: begin
                if(DMA_req == 1'b1 && transfer_done == 1'b0) begin
                    // If CPU gets any external DMA request signal, then it send drq signal to DMA
                    drq <= 1'b1;
                    state <= HOLD_REQ;
                end 
                else begin
                    drq <= 1'b0;
                    state <= NORMAL;
                end
            end 

            HOLD_REQ: begin
                if(hrq == 1'b1) begin
                    // When CPU gets Hold Request signal from DMA, it transitions to HOLD state, by releasing the memory buses.
                    // And Provides Hold Acknowledgement Signal.
                    start_transfer <= 1'b1;
                    state <= HOLD;
                end
            end

            HOLD: begin
                // Till when the transfer is going on, CPU will be in HOLD State without any memory operations.
                // and will wait for Transfer done signal
                if(dack == 1'b1 && transfer_done == 1'b0) begin
                    state <= HOLD;
                end
                else if(transfer_done == 1'b1)
                    // if the transfer is done, then it will go to NORMAL State.
                    state <= NORMAL;
            end

            default: state <= NORMAL;
        endcase
    end
end
    
endmodule