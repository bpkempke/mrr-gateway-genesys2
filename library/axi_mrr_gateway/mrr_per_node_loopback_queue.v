
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
reg priority_request;
integer priority_idx;
always @* begin
    priority_request = 1'b0;
    priority_chip_id = 0;
    for(priority_idx=0; priority_idx<NUM_DECODE_CHAIN; priority_idx=priority_idx+1) begin
        if(pop_request[priority_idx]) begin
            priority_request = 1'b1;
            priority_chip_id = pop_chip_id[(priority_idx+1)*CHIP_ID_LEN-1-:CHIP_ID_LEN];
        end
    end
end

//2-port RAM to store the queue of messages
reg [LOOPBACK_QUEUE_LEN_LOG2-1:0] push_idx;
reg [LOOPBACK_QUEUE_LEN_LOG2-1:0] last_push_idx;
reg [LOOPBACK_QUEUE_LEN_LOG2-1:0] pop_idx;
reg [LOOPBACK_QUEUE_COUNTER_LEN_LOG2-1:0] push_counter;
reg [LOOPBACK_QUEUE_COUNTER_LEN_LOG2-1:0] pop_counter;
reg pop_write_en;
reg push_write_en;
reg increment_push_idx;
wire pop_valid;
wire [LOOPBACK_MESSAGE_LEN+LOOPBACK_QUEUE_COUNTER_LEN_LOG2+CHIP_ID_LEN-1:0] push_read_unused;
ram_2port @(.DWIDTH(LOOPBACK_QUEUE_COUNTER_LEN_LOG2+LOOBACK_MESSAGE_LEN+CHIP_ID_LEN+1), .AWIDTH(LOOPBACK_QUEUE_LEN_LOG2)) message_queue_ram (
    .clka(clk),
    .ena(1'b1),
    .wea(push_write_en)
    .addra((push_write_en) ? last_push_idx : push_idx),
    .dia({1'b1,push_counter,push_chip_id,push_message}),
    .doa({push_read_valid,push_read_unused}),

    .clkb(clk),
    .enb(1'b1),
    .web(pop_write_en),
    .addrb(pop_idx),
    .dib(0),
    .dob({pop_valid,pop_counter,pop_chip_id,pop_message)
);

reg [3:0] push_state;
reg [3:0] next_push_state;
always @(posedge clk) begin
    if(rst) begin
        push_state <= STATE_PUSH_IDLE;
        push_idx <= 0;
        push_counter <= 0;
        last_push_idx <= 0;
    end else begin
        push_state <= next_push_state;
        last_push_idx <= push_idx;
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
            if(push_request) begin
                next_push_state = STATE_PUSH_SEARCH;
            end
        end

        STATE_PUSH_SEARCH: begin
            increment_push_idx = 1'b1;
            if(push_read_valid) begin
                next_push_state = STATE_PUSH_SAVE;
            end
        end

        STATE_PUSH_SAVE: begin
            push_write_en = 1'b1;
            next_push_state = STATE_PUSH_WAIT;
        end

        STATE_PUSH_WAIT: begin
            push_ack = 1'b1;
            if(~push_request) begin
                next_push_state = STATE_PUSH_IDLE;
            end
        end
    endcase
end


//State machine to respond to pop requests
localparam STATE_POP_IDLE = 0;

reg [3:0] pop_state;
reg [3:0] next_pop_state;
reg increment_pop_idx;
always @(posedge clk) begin
    if(rst) begin
        pop_state <= STATE_POP_IDLE;
        pop_idx <= 0;
    end else begin
        pop_state <= next_pop_state;
        if(increment_pop_idx) begin
            pop_idx <= pop_idx + 1;
        end
    end
end

always @* begin
    pop_ack = 0;
    increment_pop_idx = 1'b0;
    next_pop_state = pop_state;

    case(pop_state)
        STATE_POP_IDLE: begin
            if(priority_request) begin
                next_pop_state = STATE_POP_SEARCH;
            end
        end

        STATE_POP_SEARCH: begin
             increment_pop_idx = 1'b1;
             if(pop_idx == {{LOOPBACK_QUEUE_LEN_LOG2}{1'b1}}) begin
                 next_pop_state = STATE_POP_ACK;
             end
        end

        STATE_POP_ACK: begin
            pop_ack = 1'b1;
            next_pop_state = STATE_POP_IDLE;
        end
    endcase
end
