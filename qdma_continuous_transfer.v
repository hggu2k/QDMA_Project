module qdma_continuous_transfer (
    input wire clk,                            
    input wire rst,                            
    input wire drq,                // DMA Request signal for data transferring from CPU
    output reg hrq,                // Hold Request Signal fed to CPU
    input wire start_transfer,     // Hold Acknowledgement Signal from signal enabling transfer from CPU
    output reg dack,               // DMA Acknowledgement Signal
    input [1:0] transfer_type,     // Transfer type: 2'b00 for memory-to-memory, 2'b01 for peripheral-to-memory
    input [2:0] src_module,        // Select Source Module
    input [2:0] dest_module,       // Select Destination Module
    input [4:0] src_address,       // Select Source Address
    input [4:0] dest_address,      // Select Destination Address
    output reg transfer_done       // Transfer Completion Signal to CPU
);

// Internal memory
reg [7:0] memory0 [0:31];
reg [7:0] memory1 [0:31];
reg [7:0] memory2 [0:31];
reg [7:0] memory3 [0:31];
reg [7:0] memory4 [0:31];
reg [7:0] memory5 [0:31];
reg [7:0] memory6 [0:31];
reg [7:0] memory7 [0:31];

// Peripheral Buffers
reg [7:0] peripheral0 [0:31];
reg [7:0] peripheral1 [0:31];
reg [7:0] peripheral2 [0:31];
reg [7:0] peripheral3 [0:31];
reg [7:0] peripheral4 [0:31];
reg [7:0] peripheral5 [0:31];
reg [7:0] peripheral6 [0:31];
reg [7:0] peripheral7 [0:31];

// Parameters for data rate management
parameter DELAY_CYCLES = 2;   // Delay cycles between transfers
parameter FIFO_DEPTH = 8;     // Depth of FIFO buffer

// Circular FIFO buffer
reg [7:0] fifo [0:FIFO_DEPTH-1];
reg [3:0] fifo_wr_ptr, fifo_rd_ptr;
reg [3:0] fifo_count;

// Internal signals
reg [4:0] src_addr, dest_addr;          // Source and destination memory addresses
reg [2:0] state;                        // State machine state
reg [1:0] delay_cycles_counter;         // Counter for delay cycles

// Define state machine states
parameter DMA_REQ = 3'b000, IDLE = 3'b001, READ = 3'b010, TRANSFER = 3'b011, DELAY = 3'b100, DONE = 3'b101;

// Initialize internal memory and signals
initial begin
    // Initialize FIFO buffer pointers and count
    fifo_wr_ptr = 0;
    fifo_rd_ptr = 0;
    fifo_count = 0;

    // Initialize other signals
    src_addr = 0;
    dest_addr = 0;
    state = DMA_REQ;
    delay_cycles_counter = 0;
    transfer_done = 0;
end

// State machine for data transfer and delay management
always @(posedge clk) begin
    if (rst) begin
        // Reset state machine and internal signals
        state <= DMA_REQ;
        src_addr <= 0;
        dest_addr <= 0;
        delay_cycles_counter <= 0;
        fifo_wr_ptr <= 0;
        fifo_rd_ptr <= 0;
        fifo_count <= 0;
        transfer_done <= 0;
    end else begin
        // State machine transitions
        case(state)
            DMA_REQ: begin
                // Check for DMA Request Signal
                if (drq == 1'b1) begin
                        // Send Hold Request Signal to CPU
                        hrq <= 1'b1;
                        state <= IDLE;
                    end
                else begin
                    hrq <= 1'b0;
                end
            end

            IDLE: begin
                // Check for transfer request/Hold Acknowledgement Signal
                if (start_transfer) begin
                    // Send DMA Acknowledgement Signal
                    dack <= 1'b1;
                    src_addr <= src_address;
                    dest_addr <= dest_address;
                    state <= READ;
                end
                else begin
                    dack <= 1'b0;
                end
            end

            READ: begin
                if(dack == 1'b1) begin
                    if (transfer_type == 2'b00) begin
                        // Write data to FIFO buffer if it's a memory-to-memory transfer
                        case (src_module)
                            3'b000 : fifo[fifo_wr_ptr] <= memory0[src_addr]; 
                            3'b001 : fifo[fifo_wr_ptr] <= memory1[src_addr]; 
                            3'b010 : fifo[fifo_wr_ptr] <= memory2[src_addr]; 
                            3'b011 : fifo[fifo_wr_ptr] <= memory3[src_addr]; 
                            3'b100 : fifo[fifo_wr_ptr] <= memory4[src_addr]; 
                            3'b101 : fifo[fifo_wr_ptr] <= memory5[src_addr]; 
                            3'b110 : fifo[fifo_wr_ptr] <= memory6[src_addr]; 
                            3'b111 : fifo[fifo_wr_ptr] <= memory7[src_addr]; 
                        endcase
                    end else begin
                        // Write data to FIFO buffer if it's a peripheral-to-memory transfer
                        case (src_module)
                            3'b000 : fifo[fifo_wr_ptr] <= peripheral0[src_addr]; 
                            3'b001 : fifo[fifo_wr_ptr] <= peripheral1[src_addr]; 
                            3'b010 : fifo[fifo_wr_ptr] <= peripheral2[src_addr]; 
                            3'b011 : fifo[fifo_wr_ptr] <= peripheral3[src_addr]; 
                            3'b100 : fifo[fifo_wr_ptr] <= peripheral4[src_addr]; 
                            3'b101 : fifo[fifo_wr_ptr] <= peripheral5[src_addr]; 
                            3'b110 : fifo[fifo_wr_ptr] <= peripheral6[src_addr]; 
                            3'b111 : fifo[fifo_wr_ptr] <= peripheral7[src_addr]; 
                        endcase
                    end
                end
                if (fifo_wr_ptr == FIFO_DEPTH - 1)   // Circular FIFO
                        fifo_wr_ptr <= 0;            // reset the write pointer
                    else
                        fifo_wr_ptr <= fifo_wr_ptr + 1; // Incrementing Write Pointer
                fifo_count <= fifo_count + 1;   // Incrementing FIFO Count
                // Move to transfer state
                state <= TRANSFER;
            end
            TRANSFER: begin
                // Perform data transfer from FIFO buffer
                if (fifo_count > 0) begin
                    // Read data from FIFO buffer
                    // Write data to Destination from FIFO buffer if it's a memory-to-memory transfer/peripheral-to-meory transfer
                        case (dest_module)
                            3'b000 : memory0[dest_addr] <= fifo[fifo_rd_ptr]; 
                            3'b001 : memory1[dest_addr] <= fifo[fifo_rd_ptr]; 
                            3'b010 : memory2[dest_addr] <= fifo[fifo_rd_ptr];
                            3'b011 : memory3[dest_addr] <= fifo[fifo_rd_ptr]; 
                            3'b100 : memory4[dest_addr] <= fifo[fifo_rd_ptr]; 
                            3'b101 : memory5[dest_addr] <= fifo[fifo_rd_ptr]; 
                            3'b110 : memory6[dest_addr] <= fifo[fifo_rd_ptr]; 
                            3'b111 : memory7[dest_addr] <= fifo[fifo_rd_ptr]; 
                        endcase

                    if (fifo_rd_ptr == FIFO_DEPTH - 1)    // Circular FIFO
                        fifo_rd_ptr <= 0;                // reseting the read pointer
                    else 
                        fifo_rd_ptr <= fifo_rd_ptr + 1;  // Incrementing Read Pointer

                    fifo_count <= fifo_count - 1;    // Decrementing FIFO Count
                    // Increment memory addresses
                    src_addr <= src_addr + 1;
                    dest_addr <= dest_addr + 1;
                    // Move to delay state
                    state <= DELAY;
                end else begin
                    // Return to idle state if no data in FIFO buffer
                    state <= IDLE;
                end
            end
            DELAY: begin
                // Perform delay
                if (delay_cycles_counter < DELAY_CYCLES) begin
                    // Increment delay counter
                    delay_cycles_counter <= delay_cycles_counter + 1;
                    state <= DELAY;
                end else begin
                    // Reset delay counter and transition to DONE state
                    delay_cycles_counter <= 0;
                    state <= DONE;
                end
            end
            DONE: begin
                // Enable the Transfer done signal
                transfer_done <= 1'b1;
                state <= DONE;
            end
            default: state <= DMA_REQ;
        endcase
    end
end


endmodule
