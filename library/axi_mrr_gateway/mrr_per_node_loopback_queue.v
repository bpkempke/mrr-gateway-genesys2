// 
// Module: mrr_per_node_loopback_queue.v
// Project: MRR Gateway
// Description: 
//   Stores loopback messages for delivery to a number of independent tags.
//   Can be accessed serially from multiple decode chains.  Priority is given
//   to the chain with highest index.
//
// Port definitions:
//   - clk: System clock
//   - rst: Active-high reset signal
//   - pop_chip_id: Chip ID for pop request from decode chain
//   - pop_request: Pop request from decode chain (one bit per decode chain)
//   - pop_ack: Acknowledgement to corresponding pop request
//   - pop_message: Popped message destined for chip ID detailed in pop_chip_id
//   - push_chip_id: Destination chip ID for message to push onto queue
//   - push_request: Request to push a new message onto the queue
//   - push_message: Message data for the push request
//   - push_ack: Acknowledge successful message queue push
//
// Maintainer: Benjamin P. Kempke (bpkempke@gmail.com)
// Revision: 1.0
//

module mrr_per_node_loopback_queue(clk, rst, pop_chip_id, pop_request, pop_ack, pop_message, push_chip_id, push_request, push_message, push_ack)

`include "mrr_params.vh"

localparam LOOPBACK_QUEUE_COUNTER_LEN_LOG2 = 16;

input clk;
input rst;
input [NUM_DECODE_CHAINS*CHIP_ID_LEN-1:0] pop_chip_id;
input [NUM_DECODE_CHAINS-1:0] pop_request;
output reg [NUM_DECODE_CHAINS-1:0] pop_ack;
output [LOOPBACK_MESSAGE_LEN-1:0] pop_message;
input [CHIP_ID_LEN-1:0] push_chip_id;
input push_request;
input [LOOPBACK_MESSAGE_LEN-1:0] push_message;
output reg push_ack;

//Priority queue to determine which requesting decode chain to serve
reg [CHIP_ID_LEN-1:0] priority_chip_id;
reg [CHIP_ID_LEN-1:0] priority_chip_id_latched;
reg [NUM_DECODE_CHAINS-1:0] priority_chain;
reg [NUM_DECODE_CHAINS-1:0] priority_chain_latched;
reg priority_request;
integer priority_idx;
always @* begin
    priority_request = 1'b0;
    priority_chip_id = 0;
    priority_chain = 0;
    for(priority_idx=0; priority_idx<NUM_DECODE_CHAIN; priority_idx=priority_idx+1) begin
        if(pop_request[priority_idx]) begin
            priority_request = 1'b1;
            priority_chip_id = pop_chip_id[(priority_idx+1)*CHIP_ID_LEN-1-:CHIP_ID_LEN];
            priority_chain = 1<<priority_idx;
        end
    end
end

//2-port RAM to store the queue of messages
reg [LOOPBACK_QUEUE_LEN_LOG2-1:0] push_idx;
reg [CHIP_ID_LEN-1:0] push_chip_id_latched;
reg [LOOPBACK_MESSAGE_LEN-1:0] push_message_latched;
reg [LOOPBACK_QUEUE_LEN_LOG2-1:0] last_push_idx;
reg [LOOPBACK_QUEUE_LEN_LOG2-1:0] pop_idx;
reg [LOOPBACK_QUEUE_LEN_LOG2-1:0] pop_search_idx;
reg [LOOPBACK_QUEUE_COUNTER_LEN_LOG2-1:0] push_counter;
wire [LOOPBACK_QUEUE_COUNTER_LEN_LOG2-1:0] pop_read_counter;
wire [CHIP_ID_LEN-1:0] pop_read_chip_id;
wire [LOOPBACK_MESSAGE_LEN-1:0] pop_read_message;
reg [LOOPBACK_MESSAGE_LEN-1:0] pop_search_message;
assign pop_message = pop_search_message;
reg pop_write_en;
reg push_write_en;
wire pop_read_valid;
wire [LOOPBACK_MESSAGE_LEN+LOOPBACK_QUEUE_COUNTER_LEN_LOG2+CHIP_ID_LEN-1:0] push_read_unused;
ram_2port @(.DWIDTH(LOOPBACK_QUEUE_COUNTER_LEN_LOG2+LOOBACK_MESSAGE_LEN+CHIP_ID_LEN+1), .AWIDTH(LOOPBACK_QUEUE_LEN_LOG2)) message_queue_ram (
    .clka(clk),
    .ena(1'b1),
    .wea(push_write_en)
    .addra((push_write_en) ? last_push_idx : push_idx),
    .dia({1'b1,push_counter,push_chip_id_latched,push_message_latched}),
    .doa({push_read_valid,push_read_unused}),

    .clkb(clk),
    .enb(1'b1),
    .web(pop_write_en),
    .addrb((pop_write_en) ? pop_search_idx : pop_idx),
    .dib(0),
    .dob({pop_read_valid,pop_read_counter,pop_read_chip_id,pop_read_message)
);

reg [3:0] push_state;
reg [3:0] next_push_state;
reg increment_push_idx;
always @(posedge clk) begin
    if(rst) begin
        push_state <= STATE_PUSH_IDLE;
        push_idx <= 0;
        push_counter <= 0;
        last_push_idx <= 0;
        push_chip_id_latched <= 0;
        push_message_latched <= 0;
    end else begin
        push_state <= next_push_state;

        //last_push_idx always refers to the index of data present on the "doa" port
        last_push_idx <= push_idx;

        //push_chip_id and push_message only guaranteed to be valid while push_request == 1
        if(push_request) begin
            push_chip_id_latched <= push_chip_id;
            push_message_latched <= push_message;
        end

        if(increment_push_idx) begin
            push_idx <= push_idx + 1;
        end

        if(push_write_en) begin
            push_counter <= push_counter + 1;
        end
    end
end

localparam STATE_PUSH_IDLE = 0;
localparam STATE_PUSH_SEARCH = 1;
localparam STATE_PUSH_SAVE = 2;
localparam STATE_PUSH_WAIT = 3;

always @* begin
    next_push_state = push_state;
    increment_push_idx = 1'b0;
    push_ack = 1'b0;
    push_write_en = 1'b0;

    case(push_state)
        STATE_PUSH_IDLE: begin
            //Wait for push request to store data to message queue
            if(push_request) begin
                next_push_state = STATE_PUSH_SEARCH;
            end
        end

        STATE_PUSH_SEARCH: begin
	    //Work our way through the message queue until we find an row which
	    // isn't occupied
            increment_push_idx = 1'b1;
            if(push_read_valid) begin
                next_push_state = STATE_PUSH_SAVE;
            end
        end

        STATE_PUSH_SAVE: begin
            //Push the requested message into the free row
            push_write_en = 1'b1;
            next_push_state = STATE_PUSH_WAIT;
        end

        STATE_PUSH_WAIT: begin
            //Acknowledge the push request until push_request goes low
            push_ack = 1'b1;
            if(~push_request) begin
                next_push_state = STATE_PUSH_IDLE;
            end
        end
    endcase
end


//State machine to respond to pop requests
localparam STATE_POP_IDLE = 0;
localparam STATE_POP_SEARCH = 1;
localparam STATE_POP_INVALIDATE = 2;
localparam STATE_POP_ACK = 3;

reg [3:0] pop_state;
reg [3:0] next_pop_state;
reg [LOOPBACK_QUEUE_LEN_LOG2-1:0] pop_idx_last;
reg [LOOPBACK_QUEUE_COUNTER_LEN_LOG2-1:0] pop_search_lowest_counter;
reg reset_pop_search;
reg increment_pop_idx;
always @(posedge clk) begin
    if(rst) begin
        pop_state <= STATE_POP_IDLE;
        pop_search_lowest_counter <= 0;
        pop_search_idx <= 0;
        pop_search_message <= 0;
        pop_idx <= 0;
        pop_idx_last <= 0;
        priority_chip_id_latched <= 0;
        priority_chain_latched <= 0;
    end else begin
        pop_idx_last <= pop_idx;

        pop_state <= next_pop_state;
        if(reset_pop_search) begin
            pop_idx <= 0;
            pop_search_lowest_counter <= {{LOOPBACK_QUEUE_COUNTER_LEN_LOG2}{1'b1}};
            priority_chip_id_latched <= priority_chip_id;
            priority_chain_latched <= priority_chain;
        end

        if(increment_pop_idx) begin
            pop_idx <= pop_idx + 1;
            if(pop_read_valid && (pop_read_counter < pop_search_lowest_counter) && (pop_read_chip_id == priority_chip_id_latched)) begin
                pop_search_lowest_counter <= pop_read_counter;
                pop_search_idx <= pop_idx_last;
                pop_search_message <= pop_read_message;
            end
        end
    end
end

always @* begin
    pop_ack = 0;
    reset_pop_search = 1'b0;
    increment_pop_idx = 1'b0;
    pop_write_en = 1'b0;
    next_pop_state = pop_state;

    case(pop_state)
        STATE_POP_IDLE: begin
            //Wait for a decode chain to request a message from the queue
            reset_pop_search = 1'b1;
            if(priority_request) begin
                next_pop_state = STATE_POP_SEARCH;
            end
        end

        STATE_POP_SEARCH: begin
	    //Traverse the queue, searching for the oldest message with the
	    // desired chip ID
            increment_pop_idx = 1'b1;
            if(pop_idx_last == {{LOOPBACK_QUEUE_LEN_LOG2}{1'b1}}) begin
                next_pop_state = STATE_POP_ACK;
            end
        end

        STATE_POP_INVALIDATE: begin
	    //Once the whole queue has been traversed, pop the oldest message
	    // destined for the given chip ID
            pop_write_en = 1'b1;
            next_pop_state = STATE_POP_ACK;
        end

        STATE_POP_ACK: begin
            //Acknowledge the popped message to the requesting decode chain
            pop_ack = priority_chain_latched;
            next_pop_state = STATE_POP_IDLE;
        end
    endcase
end
