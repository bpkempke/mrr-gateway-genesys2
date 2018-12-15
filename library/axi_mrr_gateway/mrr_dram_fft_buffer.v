
//
// There are various obligations put on this code not present in regular BRAM based FIFO's
//
// 1) Bursts are way more efficient, use local small FIFO's to interact with DRAM
// 2) Never cross a 4KByte address boundry within a single transaction, this is an AXI4 rule.
// 3) 2^SIZE must be greater than 4KB so that the 4KByte page protection also deals with FIFO wrap corner case.
//
module mrr_dram_fft_buffer
#(
   parameter DEFAULT_BASE     = 30'h00000000,
   parameter DEFAULT_MASK     = 30'hFF000000,
   parameter DEFAULT_TIMEOUT  = 12'd256,
   parameter SR_BASE          = 0,            //Base address for settings registers
   parameter EXT_BIST         = 0,            //If 1 then instantiate extended BIST with dynamic SID, delays and BW counters
   parameter INPUT_FRAME_SIZE_LOG2 = 6,
   parameter REORDER_FACTOR_LOG2 = 0
)(
bus_clk,
bus_reset, 
dram_clk,
dram_reset,
m_axi_awid,
m_axi_awaddr,
m_axi_awlen,
m_axi_awsize,
m_axi_awburst,
m_axi_awlock,
m_axi_awcache,
m_axi_awprot,
m_axi_awqos,
m_axi_awregion,
m_axi_awuser,
m_axi_awvalid,
m_axi_awready,
m_axi_wdata,
m_axi_wstrb,
m_axi_wlast,
m_axi_wuser,
m_axi_wvalid,
m_axi_wready,
m_axi_bid,
m_axi_bresp,
m_axi_buser,
m_axi_bvalid,
m_axi_bready,
m_axi_arid,
m_axi_araddr,
m_axi_arlen,
m_axi_arsize,
m_axi_arburst,
m_axi_arlock,
m_axi_arcache,
m_axi_arprot,
m_axi_arqos,
m_axi_arregion,
m_axi_aruser,
m_axi_arvalid,
m_axi_arready,
m_axi_rid,
m_axi_rdata,
m_axi_rresp,
m_axi_rlast,
m_axi_ruser,
m_axi_rvalid,
m_axi_rready,
i_tdata,
i_tlast,
i_tvalid,
i_tready,
o_tdata,
o_tlast,
o_tvalid,
o_tready,
set_stb,
set_addr,
set_data,
rb_data,
sync_req,
sync_latest,
sync_ack,
empty,
flush_req,
flush_done,
trigger_new_superframe_sync,
setting_input_frame_size_log2,
setting_input_frame_size_mask,
setting_reorder_factor_log2,
setting_reorder_factor_mask,
setting_mod_sync_frames_log2,
setting_mod_sync_frames_mask,
debug,
debug2
);

    `include "mrr_params.vh"

   input bus_clk;
   input bus_reset; 
   input dram_clk;
   input dram_reset;
   //
   // AXI Write address channel
   //
   output [0 : 0] m_axi_awid;     // Write address ID. This signal is the identification tag for the write address signals
   output [31 : 0] m_axi_awaddr;  // Write address. The write address gives the address of the first transfer in a write burst
   output [7 : 0] m_axi_awlen;    // Burst length. The burst length gives the exact number of transfers in a burst.
   output [2 : 0] m_axi_awsize;   // Burst size. This signal indicates the size of each transfer in the burst. 
   output [1 : 0] m_axi_awburst;  // Burst type. The burst type and the size information; determine how the address is calculated
   output [0 : 0] m_axi_awlock;   // Lock type. Provides additional information about the atomic characteristics of the transfer.
   output [3 : 0] m_axi_awcache;  // Memory type. This signal indicates how transactions are required to progress
   output [2 : 0] m_axi_awprot;   // Protection type. This signal indicates the privilege and security level of the transaction
   output [3 : 0] m_axi_awqos;    // Quality of Service; QoS. The QoS identifier sent for each write transaction
   output [3 : 0] m_axi_awregion; // Region identifier. Permits a single physical interface on a slave to be re-used.
   output [0 : 0] m_axi_awuser;   // User signal. Optional User-defined signal in the write address channel.
   output m_axi_awvalid;      // Write address valid. This signal indicates that the channel is signaling valid write addr
   input m_axi_awready;           // Write address ready. This signal indicates that the slave is ready to accept an address
   //
   // AXI Write data channel.
   //
   output [63 : 0] m_axi_wdata;   // Write data
   output [7 : 0] m_axi_wstrb;    // Write strobes. This signal indicates which byte lanes hold valid data.
   output m_axi_wlast;        // Write last. This signal indicates the last transfer in a write burst
   output [0 : 0] m_axi_wuser;    // User signal. Optional User-defined signal in the write data channel.
   output m_axi_wvalid;           // Write valid. This signal indicates that valid write data and strobes are available. 
   input m_axi_wready;            // Write ready. This signal indicates that the slave can accept the write data.
   //
   // AXI Write response channel signals
   //
   input [0 : 0] m_axi_bid;       // Response ID tag. This signal is the ID tag of the write response. 
   input [1 : 0] m_axi_bresp;     // Write response. This signal indicates the status of the write transaction.
   input [0 : 0] m_axi_buser;     // User signal. Optional User-defined signal in the write response channel.
   input m_axi_bvalid;            // Write response valid. This signal indicates that the channel is signaling a valid response
   output m_axi_bready;       // Response ready. This signal indicates that the master can accept a write response
   //
   // AXI Read address channel
   //
   output [0 : 0] m_axi_arid;     // Read address ID. This signal is the identification tag for the read address group of signals
   output [31 : 0] m_axi_araddr;  // Read address. The read address gives the address of the first transfer in a read burst
   output [7 : 0] m_axi_arlen;    // Burst length. This signal indicates the exact number of transfers in a burst.
   output [2 : 0] m_axi_arsize;   // Burst size. This signal indicates the size of each transfer in the burst.
   output [1 : 0] m_axi_arburst;  // Burst type. The burst type and the size information determine how the address for each transfer
   output [0 : 0] m_axi_arlock;   // Lock type. This signal provides additional information about the atomic characteristics
   output [3 : 0] m_axi_arcache;  // Memory type. This signal indicates how transactions are required to progress 
   output [2 : 0] m_axi_arprot;   // Protection type. This signal indicates the privilege and security level of the transaction
   output [3 : 0] m_axi_arqos;    // Quality of Service, QoS. QoS identifier sent for each read transaction.
   output [3 : 0] m_axi_arregion; // Region identifier. Permits a single physical interface on a slave to be re-used
   output [0 : 0] m_axi_aruser;   // User signal. Optional User-defined signal in the read address channel.
   output m_axi_arvalid;          // Read address valid. This signal indicates that the channel is signaling valid read addr
   input m_axi_arready;           // Read address ready. This signal indicates that the slave is ready to accept an address
   //
   // AXI Read data channel
   //
   input [0 : 0] m_axi_rid;       // Read ID tag. This signal is the identification tag for the read data group of signals
   input [63 : 0] m_axi_rdata;    // Read data.
   input [1 : 0] m_axi_rresp;     // Read response. This signal indicates the status of the read transfer
   input m_axi_rlast;             // Read last. This signal indicates the last transfer in a read burst.
   input [0 : 0] m_axi_ruser;     // User signal. Optional User-defined signal in the read data channel.
   input m_axi_rvalid;            // Read valid. This signal indicates that the channel is signaling the required read data. 
   output m_axi_rready;           // Read ready. This signal indicates that the master can accept the read data and response
   //
   // CHDR friendly AXI stream input
   //
   input [63:0] i_tdata;
   input i_tlast;
   input i_tvalid;
   output i_tready;
   //
   // CHDR friendly AXI Stream output
   //
   output [63:0] o_tdata;
   output o_tlast;
   output o_tvalid;
   input o_tready;
   //
   // Settings and Readback
   //
   input              set_stb;
   input [7:0]        set_addr;
   input [31:0]       set_data;
   output reg [31:0]  rb_data;
   //
   // Back-track
   //
   input sync_req;
   input sync_latest;
   output sync_ack;
   //
   // Flush buffer
   //
   input flush_req;
   output reg flush_done;
   //
   // Status signals
   //
   output empty;
   output trigger_new_superframe_sync;
   input [PRIMARY_FFT_MAX_LEN_LOG2_LOG2-1:0] setting_input_frame_size_log2;
   input [PRIMARY_FFT_MAX_LEN_LOG2:0] setting_input_frame_size_mask;
   input [PRIMARY_FFT_MAX_LEN_LOG2_LOG2-1:0] setting_reorder_factor_log2;
   input [PRIMARY_FFT_MAX_LEN_LOG2-1:0] setting_reorder_factor_mask;
   input [SECONDARY_FFT_MAX_LEN_LOG2_LOG2-1:0] setting_mod_sync_frames_log2;
   input [SECONDARY_FFT_MAX_LEN_LOG2:0] setting_mod_sync_frames_mask;
   //
   // Debug Bus
   //
   output [63:0] debug;
   output [63:0] debug2;

   //
   // We are only solving for width 64bits here, since it's our standard CHDR quanta
   //
   localparam DWIDTH = 64;
   localparam AWIDTH = 30;

   //
   // Settings and Readback
   //
   wire [2:0]         rb_addr;
   wire               clear_bclk;
   wire               supress_enable_bclk;
   wire [15:0]        supress_threshold_bclk;
   wire [11:0]        timeout_bclk;
   wire [AWIDTH-1:0]  fifo_base_addr_bclk;
   wire [AWIDTH-1:0]  fifo_addr_mask_bclk;
   wire [1:0]         ctrl_reserved;

   wire [31:0]  rb_fifo_status;
   wire [3:0]   rb_bist_status;
   wire [95:0]  rb_bist_bw_ratio;

   localparam RB_FIFO_STATUS    = 3'd0;
   localparam RB_BIST_STATUS    = 3'd1;
   localparam RB_BIST_XFER_CNT  = 3'd2;
   localparam RB_BIST_CYC_CNT   = 3'd3;

   wire sync_req_sync;
   reg [4:0] sync_req_sync_d;
   wire sync_latest_sync;
   reg sync_ack_sync;
   reg trigger_new_superframe;

   reg sync_req_reg, sync_latest_reg;
   always @(posedge bus_clk) begin
     sync_req_reg <= sync_req;
     sync_latest_reg <= sync_latest;
   end
   synchronizer #(.INITIAL_VAL(1'b0)) sync_req_sync_inst (.clk(dram_clk), .rst(1'b0), .in(sync_req_reg), .out(sync_req_sync));
   synchronizer #(.INITIAL_VAL(1'b0)) sync_latest_sync_inst (.clk(dram_clk), .rst(1'b0), .in(sync_latest_reg), .out(sync_latest_sync));
   synchronizer #(.INITIAL_VAL(1'b0)) sync_ack_sync_inst (.clk(bus_clk), .rst(1'b0), .in(sync_ack_sync), .out(sync_ack));
   synchronizer #(.INITIAL_VAL(1'b0)) sync_trigger_inst (.clk(bus_clk), .rst(1'b0), .in(trigger_new_superframe), .out(trigger_new_superframe_sync));

   reg empty_sync;
   synchronizer #(.INITIAL_VAL(1'b1)) sync_empty_sync_inst (.clk(bus_clk), .rst(1'b0), .in(empty_sync), .out(empty));

   // SETTING: Readback Address Register
   // Fields:
   // - [2:0]  : Address for readback register
   //            - 0 = RB_FIFO_STATUS
   //            - 1 = RB_BIST_STATUS
   //            - 2 = RB_BIST_XFER_CNT
   //            - 3 = RB_BIST_CYC_CNT
   //            - rest reserved
   setting_reg #(.my_addr(SR_BASE + 0), .awidth(8), .width(3), .at_reset(3'b000)) sr_readback
     (.clk(bus_clk), .rst(bus_reset),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(rb_addr));

   // SETTING: FIFO Control Register
   // Fields:
   // - [0]     : Clear FIFO and discard stored data
   // - [1]     : Enable read suppression to prioritize writes
   // - [3:2]   : Reserved
   // - [15:4]  : Timeout (in memory clock beats) for issuing smaller than optimal bursts
   // - [31:16] : Read suppression threshold in number of words
   setting_reg #(.my_addr(SR_BASE + 1), .awidth(8), .width(32), .at_reset({16'h0, DEFAULT_TIMEOUT[11:0], 2'b00, 1'b0, 1'b0})) sr_fifo_ctrl
     (.clk(bus_clk), .rst(bus_reset),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out({supress_threshold_bclk, timeout_bclk, ctrl_reserved, supress_enable_bclk, clear_bclk}));

   // SETTING: Base Address for FIFO in memory space
   // Fields:
   // - [29:0]  : Base address
   setting_reg #(.my_addr(SR_BASE + 2), .awidth(8), .width(AWIDTH), .at_reset(DEFAULT_BASE)) sr_fifo_base_addr
     (.clk(bus_clk), .rst(bus_reset),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(fifo_base_addr_bclk));

   // SETTING: Address Mask for FIFO in memory space. The mask is ANDed with the base address to define
   //          a unique address for this FIFO. A zero in the mask signifies that the DRAM FIFO can
   //          utilize the address bit internally for maintaining FIFO data
   // Fields:
   // - [29:0]  : Address mask
   setting_reg #(.my_addr(SR_BASE + 3), .awidth(8), .width(AWIDTH), .at_reset(DEFAULT_MASK)) sr_fifo_addr_mask
     (.clk(bus_clk), .rst(bus_reset),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(fifo_addr_mask_bclk));

   always @(*) begin
      case(rb_addr)
         RB_FIFO_STATUS:      rb_data = rb_fifo_status;
         RB_BIST_STATUS:      rb_data = {(EXT_BIST?1'b1:1'b0), 27'h0, rb_bist_status};
         RB_BIST_XFER_CNT:    rb_data = rb_bist_bw_ratio[79:48];
         RB_BIST_CYC_CNT:     rb_data = rb_bist_bw_ratio[31:0];
         default:             rb_data = 32'h0;
      endcase
   end

   //
   // Synchronize settings register values to dram_clk
   //
   wire clear;
   synchronizer #(.INITIAL_VAL(1'b1)) clear_sync_inst (.clk(dram_clk), .rst(1'b0), .in(clear_bclk), .out(clear));

   wire               set_suppress_en;
   wire [15:0]        set_supress_threshold;
   wire [11:0]        set_timeout;
   wire [AWIDTH-1:0]  set_fifo_base_addr, set_fifo_addr_mask, set_fifo_addr_mask_bar;

   wire [(72-AWIDTH-29-1):0]  set_sync_discard0;
   wire [(72-(2*AWIDTH)-1):0] set_sync_discard1;
   //fifo_short_2clk set_sync_fifo0(
   //   .rst(bus_reset),
   //   .wr_clk(bus_clk), .din({{(72-AWIDTH-29){1'b0}}, timeout_bclk, supress_enable_bclk, supress_threshold_bclk, fifo_base_addr_bclk}),
   //   .wr_en(1'b1), .full(), .wr_data_count(),
   //   .rd_clk(dram_clk), .dout({set_sync_discard0, set_timeout, set_suppress_en, set_supress_threshold, set_fifo_base_addr}),
   //   .rd_en(1'b1), .empty(), .rd_data_count()
   //);
   //fifo_short_2clk set_sync_fifo1(
   //   .rst(bus_reset),
   //   .wr_clk(bus_clk), .din({{(72-(2*AWIDTH)){1'b0}}, ~fifo_addr_mask_bclk, fifo_addr_mask_bclk}),
   //   .wr_en(1'b1), .full(), .wr_data_count(),
   //   .rd_clk(dram_clk), .dout({set_sync_discard1, set_fifo_addr_mask_bar, set_fifo_addr_mask}),
   //   .rd_en(1'b1), .empty(), .rd_data_count()
   //);

   assign set_timeout = DEFAULT_TIMEOUT[11:0];
   assign set_suppress_en = 1'b0;
   assign set_supress_threshold = 0;
   assign set_fifo_base_addr = DEFAULT_BASE;
   assign set_fifo_addr_mask = DEFAULT_MASK;
   assign set_fifo_addr_mask_bar = ~DEFAULT_MASK;

   //
   // Input side declarations
   //
   localparam INPUT_IDLE = 0;
   localparam INPUT1 = 1;
   localparam INPUT2 = 2;
   localparam INPUT3 = 3;   
   localparam INPUT4 = 4;
   localparam INPUT5 = 5;
   localparam INPUT6 = 6;

   reg [2:0]   input_state;
   wire [15:0]      space_input, occupied_input;
   reg [15:0]       space_input_reg;
   wire        input_timeout_triggered = (occupied_input >= (1 << setting_input_frame_size_log2));
   reg         input_timeout_reset;
   reg [8:0]   input_timeout_count;
   reg [AWIDTH-1:0]  write_addr, last_write_addr;
   wire [AWIDTH-1:0] write_addr_lastframe = write_addr - (1 << setting_input_frame_size_log2+setting_mod_sync_frames_log2+setting_reorder_factor_log2+3);
   //wire [AWIDTH-1:0] write_addr_reordered = (REORDER_FACTOR_LOG2 == 0) ? write_addr : {
   //    write_addr[AWIDTH-1:INPUT_FRAME_SIZE_LOG2+MOD_SYNC_FRAMES_LOG2+REORDER_FACTOR_LOG2+3],
   //    write_addr[INPUT_FRAME_SIZE_LOG2+REORDER_FACTOR_LOG2+2-:REORDER_FACTOR_LOG2],
   //    write_addr[INPUT_FRAME_SIZE_LOG2+MOD_SYNC_FRAMES_LOG2+REORDER_FACTOR_LOG2+2-:MOD_SYNC_FRAMES_LOG2],
   //    write_addr[INPUT_FRAME_SIZE_LOG2+2:0]};

   wire [AWIDTH-1:0] write_addr_reordered = (setting_reorder_factor_log2 == 0) ? write_addr : {
         (write_addr & {{{AWIDTH}{1'b1}} << (setting_input_frame_size_log2+setting_mod_sync_frames_log2+setting_reorder_factor_log2+3)})
       | ((write_addr & ({{{AWIDTH}{1'b0}}, setting_reorder_factor_mask} << (setting_input_frame_size_log2+3))) << setting_mod_sync_frames_log2)
       | ((write_addr & ({{{AWIDTH}{1'b0}}, setting_mod_sync_frames_mask} << (setting_input_frame_size_log2+setting_reorder_factor_log2+3))) >> setting_reorder_factor_log2)
       | (write_addr & 3'b111)};

   reg         write_ctrl_valid;
   wire        write_ctrl_ready;
   reg [7:0]   write_count;
   wire [AWIDTH-1:0] write_count_expanded = {{{AWIDTH-8}{1'b0}},write_count};
   reg         update_write;
   
   //
   // Output side declarations
   //
   localparam OUTPUT_IDLE = 0;
   localparam OUTPUT1 = 1;
   localparam OUTPUT2 = 2;
   localparam OUTPUT3 = 3;   
   localparam OUTPUT4 = 4;
   localparam OUTPUT5 = 5;
   localparam OUTPUT6 = 6;
   localparam OUTPUT_SYNC = 7;
   localparam OUTPUT_SYNC_WAIT = 8;

   reg [3:0]   output_state;
   reg         output_timeout_triggered;
   reg         output_timeout_reset;
   reg [8:0]   output_timeout_count;
   reg [AWIDTH-1:0]  read_addr;
   reg         read_ctrl_valid;
   wire        read_ctrl_ready;
   reg [7:0]   read_count; 
   wire [AWIDTH-1:0] read_count_expanded = {{{AWIDTH-8}{1'b0}},read_count};
   reg         update_read;
   always @(posedge dram_clk) begin
       empty_sync <= (read_addr == write_addr);
   end
   
   // Track main FIFO active size.
   reg [AWIDTH-3:0] space, occupied;
   wire [11:0]    input_page_boundry, output_page_boundry;

   // Assign FIFO status bits
   wire [71:0] status_out_bclk;
   fifo_short_2clk status_fifo_2clk(
      .rst(bus_reset),
      .wr_clk(dram_clk), .din({{(72-(AWIDTH-2)){1'b0}}, occupied}),
      .wr_en(1'b1), .full(), .wr_data_count(),
      .rd_clk(bus_clk), .dout(status_out_bclk),
      .rd_en(1'b1), .empty(), .rd_data_count()
   );
   assign rb_fifo_status[31]         = 1'b1;   //DRAM FIFO signature (validates existence of DRAM FIFO)
   assign rb_fifo_status[30:27]      = {o_tvalid, o_tready, i_tvalid, i_tready};   //Ready valid flags
   assign rb_fifo_status[AWIDTH-4:0] = status_out_bclk[AWIDTH-4:0];   //FIFO fullness count in 64bit words (max 27 bits = 1GiB)

   ///////////////////////////////////////////////////////////////////////////////
   // Inline BIST for production testing
   //
   wire       i_tready_int;

   wire [DWIDTH-1:0] i_tdata_fifo;
   wire       i_tvalid_fifo, i_tready_fifo, i_tlast_fifo;

   wire [DWIDTH-1:0] i_tdata_bist;
   wire       i_tvalid_bist, i_tready_bist, i_tlast_bist;

   wire       o_tvalid_int;

   wire [DWIDTH-1:0] o_tdata_fifo;
   wire       o_tvalid_fifo, o_tready_fifo, o_tlast_fifo;

   wire [DWIDTH-1:0] o_tdata_bist;
   wire       o_tvalid_bist, o_tready_bist, o_tlast_bist;

   wire [DWIDTH-1:0] o_tdata_gate;
   wire       o_tvalid_gate, o_tready_gate, o_tlast_gate;

   assign i_tready_bist = 1'b1;
   assign i_tdata_fifo = i_tdata;
   assign i_tlast_fifo = i_tlast;
   assign i_tvalid_fifo = i_tvalid;
   assign i_tready_int = i_tready_fifo;

   //axi_mux4 #(.PRIO(1), .WIDTH(DWIDTH), .BUFFER(1)) axi_mux (
   //   .clk(bus_clk), .reset(bus_reset), .clear(clear_bclk),
   //   .i0_tdata(i_tdata), .i0_tlast(i_tlast), .i0_tvalid(i_tvalid), .i0_tready(i_tready_int),
   //   .i1_tdata(i_tdata_bist), .i1_tlast(i_tlast_bist), .i1_tvalid(i_tvalid_bist), .i1_tready(i_tready_bist),
   //   .i2_tdata({DWIDTH{1'b0}}), .i2_tlast(1'b0), .i2_tvalid(1'b0), .i2_tready(),
   //   .i3_tdata({DWIDTH{1'b0}}), .i3_tlast(1'b0), .i3_tvalid(1'b0), .i3_tready(),
   //   .o_tdata(i_tdata_fifo), .o_tlast(i_tlast_fifo), .o_tvalid(i_tvalid_fifo), .o_tready(i_tready_fifo)
   //);
   reg i_tready_flush;
   assign i_tready = i_tready_int & (~clear_bclk) & i_tready_flush;

   //wire       bist_running, bist_done;
   //wire [1:0] bist_error;
   //
   //axi_chdr_test_pattern #(
   //  .DELAY_MODE(EXT_BIST ? "DYNAMIC" : "STATIC"), 
   //  .SID_MODE(EXT_BIST ? "DYNAMIC" : "STATIC"), 
   //  .BW_COUNTER(EXT_BIST ? 1 : 0),
   //  .SR_BASE(SR_BASE + 4)
   //) axi_chdr_test_pattern_i (
   //   .clk(bus_clk), .reset(bus_reset),
   //   .i_tdata(i_tdata_bist), .i_tlast(i_tlast_bist), .i_tvalid(i_tvalid_bist), .i_tready(i_tready_bist),
   //   .o_tdata(o_tdata_bist), .o_tlast(o_tlast_bist), .o_tvalid(o_tvalid_bist), .o_tready(o_tready_bist),
   //   .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
   //   .running(bist_running), .done(bist_done), .error(bist_error), .status_vtr(), .bw_ratio(rb_bist_bw_ratio)
   //);
   //assign rb_bist_status = {bist_error, bist_done, bist_running};
   assign rb_bist_status = 4'd0;

   //axi_demux4 #(.ACTIVE_CHAN(4'b0011), .WIDTH(DWIDTH)) axi_demux(
   //   .clk(bus_clk), .reset(bus_reset), .clear(clear_bclk),
   //   .header(), .dest({1'b0, bist_running}),
   //   .i_tdata(o_tdata_fifo), .i_tlast(o_tlast_fifo), .i_tvalid(o_tvalid_fifo), .i_tready(o_tready_fifo),
   //   .o0_tdata(o_tdata_gate), .o0_tlast(o_tlast_gate), .o0_tvalid(o_tvalid_gate), .o0_tready(o_tready_gate),
   //   .o1_tdata(o_tdata_bist), .o1_tlast(o_tlast_bist), .o1_tvalid(o_tvalid_bist), .o1_tready(o_tready_bist),
   //   .o2_tdata(), .o2_tlast(), .o2_tvalid(), .o2_tready(1'b0),
   //   .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready(1'b0)
   //);

   assign o_tdata_gate = o_tdata_fifo;
   assign o_tlast_gate = o_tlast_fifo;
   assign o_tvalid_gate = o_tvalid_fifo;
   assign o_tready_fifo = o_tready_gate;

   ////Insert package gate before output to absorb any intra-packet bubble cycles
   //axi_packet_gate #(.WIDTH(DWIDTH), .SIZE(11)) out_pkt_gate (
   //   .clk(bus_clk), .reset(bus_reset), .clear(clear_bclk),
   //   .i_tdata(o_tdata_gate), .i_tlast(o_tlast_gate), .i_tvalid(o_tvalid_gate), .i_tready(o_tready_gate),
   //   .i_terror(1'b0),
   //   .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid_int), .o_tready(o_tready | clear_bclk)
   //);

   assign o_tvalid = o_tvalid_int & (~clear_bclk);
   assign o_tdata = o_tdata_gate;
   assign o_tlast = o_tlast_gate;
   assign o_tvalid_int = o_tvalid_gate;
   assign o_tready_gate = o_tready | clear_bclk;

   //
   // Buffer input in FIFO's. Embeded tlast signal using ESCape code.
   //

   wire [DWIDTH-1:0] i_tdata_i0;
   wire             i_tvalid_i0, i_tready_i0, i_tlast_i0;
 
   wire [DWIDTH-1:0] i_tdata_i1;
   wire             i_tvalid_i1, i_tready_i1, i_tlast_i1;

   wire [DWIDTH-1:0] i_tdata_i2;
   wire             i_tvalid_i2, i_tready_i2;

   wire [DWIDTH-1:0] i_tdata_i3;
   wire             i_tvalid_i3, i_tready_i3;

   wire [DWIDTH-1:0] i_tdata_input;
   wire             i_tvalid_input, i_tready_input;
   reg              supress_reads;


   ///////////////////////////////////////////////////////////////////////////////
   
   wire         write_in, read_in, empty_in, full_in;
   assign       i_tready_fifo = ~full_in;
   assign       write_in = i_tvalid_fifo & i_tready_fifo;
   assign       i_tvalid_i0 = ~empty_in;
   assign       read_in = i_tvalid_i0 & i_tready_i0;
   wire [6:0]   discard_i0;
   
   fifo_short_2clk fifo_short_2clk_i0 (
      .rst(bus_reset),
      .wr_clk(bus_clk),
      .din({7'h0,i_tlast_fifo,i_tdata_fifo}), // input [71 : 0] din
      .wr_en(write_in), // input wr_en
      .full(full_in), // output full
      .wr_data_count(), // output [9 : 0] wr_data_count

      .rd_clk(dram_clk), // input rd_clk
      .dout({discard_i0,i_tlast_i0,i_tdata_i0}), // output [71 : 0] dout
      .rd_en(read_in), // input rd_en
      .empty(empty_in), // output empty
      .rd_data_count()  // output [9 : 0] rd_data_count
   );

   axi_fifo_flop2 #(.WIDTH(DWIDTH+1)) input_pipe_i0
     (
      .clk(dram_clk), 
      .reset(dram_reset), 
      .clear(clear),
      //
      .i_tdata({i_tlast_i0, i_tdata_i0}), 
      .i_tvalid(i_tvalid_i0), 
      .i_tready(i_tready_i0),
      //
      .o_tdata({i_tlast_i1, i_tdata_i1}), 
      .o_tvalid(i_tvalid_i1), 
      .o_tready(i_tready_i1)
   );

   //axi_embed_tlast #(.WIDTH(DWIDTH), .ADD_CHECKSUM(0)) axi_embed_tlast_i (
   //   .clk(dram_clk),
   //   .reset(dram_reset),
   //   .clear(clear),
   //   //
   //   .i_tdata(i_tdata_i1),
   //   .i_tlast(i_tlast_i1),
   //   .i_tvalid(i_tvalid_i1),
   //   .i_tready(i_tready_i1),
   //   //
   //   .o_tdata(i_tdata_i2),
   //   .o_tvalid(i_tvalid_i2),
   //   .o_tready(i_tready_i2)
   //);

   axi_fifo_flop2 #(.WIDTH(DWIDTH)) input_pipe_i1 (
      .clk(dram_clk), 
      .reset(dram_reset), 
      .clear(clear),
      //
      .i_tdata(i_tdata_i1), 
      .i_tvalid(i_tvalid_i1), 
      .i_tready(i_tready_i1),
      //
      .o_tdata(i_tdata_i3), 
      .o_tvalid(i_tvalid_i3), 
      .o_tready(i_tready_i3)
   );

   axi_fifo #(.WIDTH(DWIDTH),.SIZE(12)) fifo_i1 (
      .clk(dram_clk), 
      .reset(dram_reset), 
      .clear(clear),
      //
      .i_tdata(i_tdata_i3), 
      .i_tvalid(i_tvalid_i3), 
      .i_tready(i_tready_i3),
      //
      .o_tdata(i_tdata_input), 
      .o_tvalid(i_tvalid_input), 
      .o_tready(i_tready_input),
      //
      .space(space_input), 
      .occupied(occupied_input)
   );

   //
   // Monitor occupied_input to deduce when DRAM FIFO is running short of bandwidth and there is a danger of backpressure
   // passing upstream of the DRAM FIFO.
   // In this situation supress read requests to the DRAM FIFO so that more bandwidth is available to writes.
   //
   always @(posedge dram_clk) 
      begin
         space_input_reg <= space_input;
         if ((space_input_reg < set_supress_threshold[15:0])  && set_suppress_en)
            supress_reads <= 1'b1;
         else 
            supress_reads <= 1'b0;
      end

   //
   // Buffer output in 32entry FIFO's. Extract embeded tlast signal.
   //
   wire [DWIDTH-1:0] o_tdata_output;
   wire             o_tvalid_output, o_tready_output;
   wire [15:0]      space_output, occupied_output;
   reg clear_output_fifos;
   wire clear_output_fifos_sync;
   synchronizer #(.INITIAL_VAL(1'b0)) clear_out_fifos_sync_inst (.clk(bus_clk), .rst(1'b0), .in(clear_output_fifos), .out(clear_output_fifos_sync));

   wire [DWIDTH-1:0] o_tdata_i0;
   wire             o_tvalid_i0, o_tready_i0;
   
   wire [DWIDTH-1:0] o_tdata_i1;
   wire             o_tvalid_i1, o_tready_i1;
   
   wire [DWIDTH-1:0] o_tdata_i2;
   wire             o_tvalid_i2, o_tready_i2;
   
   wire [DWIDTH-1:0] o_tdata_i3;
   wire             o_tvalid_i3, o_tready_i3;
   
   wire [DWIDTH-1:0] o_tdata_i4;
   wire             o_tvalid_i4, o_tready_i4;
   reg              o_tlast_i4;

   wire [DWIDTH-1:0] o_tdata_i5;
   wire             o_tvalid_i5, o_tready_i5, o_tlast_i5;

   wire             checksum_error;

   axi_fifo #(.WIDTH(DWIDTH),.SIZE(10)) fifo_i2 (
      .clk(dram_clk), 
      .reset(dram_reset), 
      .clear(clear | clear_output_fifos),
      //
      .i_tdata(o_tdata_output), 
      .i_tvalid(o_tvalid_output), 
      .i_tready(o_tready_output),
      //
      .o_tdata(o_tdata_i0), 
      .o_tvalid(o_tvalid_i0), 
      .o_tready(o_tready_i0),
      //
      .space(space_output), 
      .occupied(occupied_output)
   );

   // Place FLops straight after SRAM read access for timing.
   axi_fifo_flop2 #(.WIDTH(DWIDTH)) output_pipe_i0
     (
      .clk(dram_clk), 
      .reset(dram_reset), 
      .clear(clear | clear_output_fifos),
      //
      .i_tdata(o_tdata_i0), 
      .i_tvalid(o_tvalid_i0), 
      .i_tready(o_tready_i0),
      //
      .o_tdata(o_tdata_i1), 
      .o_tvalid(o_tvalid_i1), 
      .o_tready(o_tready_i1 && ~supress_reads)
   );

   // Read suppression logic
   // The CL part of this exists between these
   // axi_flops 
   axi_fifo_flop2 #(.WIDTH(DWIDTH)) output_pipe_i1
     (
      .clk(dram_clk), 
      .reset(dram_reset), 
      .clear(clear | clear_output_fifos),
      //
      .i_tdata(o_tdata_i1), 
      .i_tvalid(o_tvalid_i1 && ~supress_reads), 
      .i_tready(o_tready_i1),
      //
      .o_tdata(o_tdata_i2), 
      .o_tvalid(o_tvalid_i2), 
      .o_tready(o_tready_i2)
   );

   // Pipeline flop before tlast extraction logic
   axi_fifo_flop2 #(.WIDTH(DWIDTH)) output_pipe_i2
     (
      .clk(dram_clk), 
      .reset(dram_reset), 
      .clear(clear | clear_output_fifos),
      //
      .i_tdata(o_tdata_i2), 
      .i_tvalid(o_tvalid_i2), 
      .i_tready(o_tready_i2),
      //
      .o_tdata(o_tdata_i4), 
      .o_tvalid(o_tvalid_i4), 
      .o_tready(o_tready_i4)
   );

   //axi_extract_tlast #(.WIDTH(DWIDTH), .VALIDATE_CHECKSUM(0)) axi_extract_tlast_i (
   //   .clk(dram_clk),
   //   .reset(dram_reset),
   //   .clear(clear),
   //   //
   //   .i_tdata(o_tdata_i3),
   //   .i_tvalid(o_tvalid_i3),
   //   .i_tready(o_tready_i3),
   //   //
   //   .o_tdata(o_tdata_i4),
   //   .o_tlast(o_tlast_i4),
   //   .o_tvalid(o_tvalid_i4),
   //   .o_tready(o_tready_i4),
   //   //
   //   .checksum_error(checksum_error)
   //);

   //We know that all packets coming through should be of size "INPUT_FRAME_SIZE_LOG2"
   reg [PRIMARY_FFT_MAX_LEN_LOG2-1:0] o_tlast_i4_counter;
   always @(posedge dram_clk) begin
       if(dram_reset | clear_output_fifos) begin
           o_tlast_i4 <= 1'b0;
           o_tlast_i4_counter <= 0;
       end else begin
           if(o_tvalid_i4 & o_tready_i4) begin
               o_tlast_i4_counter <= o_tlast_i4_counter + 1;
               if(o_tlast_i4_counter == {setting_input_frame_size_mask[PRIMARY_FFT_MAX_LEN_LOG2:1],1'b0}) begin
                   o_tlast_i4 <= 1'b1;
               end else begin
                   o_tlast_i4 <= 1'b0;
               end
           end
       end
   end

   // Pipeline flop after tlast extraction logic
   axi_fifo_flop2 #(.WIDTH(DWIDTH+1)) output_pipe_i3
     (
      .clk(dram_clk), 
      .reset(dram_reset), 
      .clear(clear | clear_output_fifos),
      //
      .i_tdata({o_tlast_i4,o_tdata_i4}), 
      .i_tvalid(o_tvalid_i4), 
      .i_tready(o_tready_i4),
      //
      .o_tdata({o_tlast_i5,o_tdata_i5}), 
      .o_tvalid(o_tvalid_i5), 
      .o_tready(o_tready_i5)
   );

   wire         write_out, read_out, empty_out, full_out;
   assign       o_tready_i5 = ~full_out;
   assign       write_out = o_tvalid_i5 & o_tready_i5;
   assign       o_tvalid_fifo = ~empty_out;
   assign       read_out = o_tvalid_fifo & o_tready_fifo;
   wire [6:0]   discard_i1;
   
   fifo_short_2clk fifo_short_2clk_i1 (
      .rst(bus_reset | clear_output_fifos_sync),
      .wr_clk(dram_clk),
      .din({7'h0,o_tlast_i5,o_tdata_i5}), // input [71 : 0] din
      .wr_en(write_out), // input wr_en
      .full(full_out), // output full
      .wr_data_count(), // output [9 : 0] wr_data_count

      .rd_clk(bus_clk), // input rd_clk
      .dout({discard_i1,o_tlast_fifo,o_tdata_fifo}), // output [71 : 0] dout
      .rd_en(read_out), // input rd_en
      .empty(empty_out), // output empty
      .rd_data_count()  // output [9 : 0] rd_data_count
   );

   //
   // Simple input timeout counter for now.
   // Timeout count only increments when there is some data waiting to be written.
   //
   //always @(posedge dram_clk)
   //   if (dram_reset | clear) begin
   //      input_timeout_count <= 0;
   //      input_timeout_triggered <= 1'b0;
   //   end else if (input_timeout_reset) begin
   //      input_timeout_count <= 0;
   //      input_timeout_triggered <= 1'b0;
   //  end else if (input_timeout_count == set_timeout) begin
   //      input_timeout_triggered <= 1'b1;
   //  end else if (input_state == INPUT_IDLE) begin
   //      input_timeout_count <= input_timeout_count + (occupied_input != 0);
   //  end

   //
   // Wait for 16 entries in input FIFO to trigger DRAM write burst.
   // Timeout can also trigger burst so fragments of data are not left to rot in the input FIFO.
   // Also if enough data is present in the input FIFO to complete a burst upto the edge
   // of a 4KByte page then immediately start the burst.
   //
   always @(posedge dram_clk)
      if (dram_reset | clear) begin
         input_state <= INPUT_IDLE;
         write_addr <= set_fifo_base_addr & set_fifo_addr_mask;
         last_write_addr <= set_fifo_base_addr & set_fifo_addr_mask;
         input_timeout_reset <= 1'b0;
         write_ctrl_valid <= 1'b0;
         write_count <= 8'd0; 
         update_write <= 1'b0;
         trigger_new_superframe <= 1'b0;
      end else
         case (input_state)
         //
         // INPUT_IDLE.
         // To start an input transfer to DRAM need:
         // 1) Space in the DRAM FIFO 
         // and either
         // 2) 256 entrys in the input FIFO
         // or
         // 3) Timeout waiting for more data.
         //
         INPUT_IDLE: begin
            write_ctrl_valid <= 1'b0;
            update_write <= 1'b0;
            if (1'b1) begin//TODO: FOR NOW, IGNORE SPACE! space > 255) begin // Space in the DRAM FIFO
               if (input_timeout_triggered) begin // input FIFO timeout waiting for new data.
                  input_state <= INPUT2;
                  input_timeout_reset <= 1'b1;
               end else begin
                  input_timeout_reset <= 1'b0;
                  input_state <= INPUT_IDLE;
               end
            end else begin
               input_timeout_reset <= 1'b0;
               input_state <= INPUT_IDLE;
            end
         end
         //
         // INPUT1.
         // Caused by input FIFO reaching 256 entries.
         // Request write burst of lesser of:
         // 1) Entrys until page boundry crossed
         // 2) 256.
         //
         INPUT1: begin
            write_count <= (input_page_boundry < 255) ? input_page_boundry[7:0] : 8'd255;
            write_ctrl_valid <= 1'b1;
            if (write_ctrl_ready)
               input_state <= INPUT4; // Pre-emptive ACK
            else
               input_state <= INPUT3; // Wait for ACK
         end
         //
         // INPUT2.
         // Caused by timeout of input FIFO. (occupied_input was implicitly less than 256 last cycle)
         // Request write burst of lesser of:
         // 1) Entries until page boundry crossed
         // 2) Entries in input FIFO
         //
         INPUT2: begin
            write_count <= setting_input_frame_size_mask;//(1 << INPUT_FRAME_SIZE_LOG2)-1;//(input_page_boundry < ({3'h0,occupied_input[8:0]} - 12'd1)) ? input_page_boundry[7:0] : (occupied_input[8:0] - 12'd1);
            write_ctrl_valid <= 1'b1;
            if (write_ctrl_ready)
               input_state <= INPUT4; // Pre-emptive ACK
            else
               input_state <= INPUT3; // Wait for ACK
         end
         //
         // INPUT3.
         // Wait in this state for AXI4_DMA engine to accept transaction.
         //
         INPUT3: begin
            if (write_ctrl_ready) begin
               write_ctrl_valid <= 1'b0;
               input_state <= INPUT4; // ACK
            end else begin
               write_ctrl_valid <= 1'b1;
               input_state <= INPUT3; // Wait for ACK
            end
         end
         //
         // INPUT4.
         // Wait here until write_ctrl_ready_deasserts.
         // This is important as the next time it asserts we know that a write response was receieved.
         INPUT4: begin
            write_ctrl_valid <= 1'b0;
            if (!write_ctrl_ready)
               input_state <= INPUT5; // Move on
            else
               input_state <= INPUT4; // Wait for deassert
         end   
         //
         // INPUT5.
         // Transaction has been accepted by AXI4 DMA engine. Now we wait for the re-assertion
         // of write_ctrl_ready which signals that the AXI4 DMA engine has receieved a response
         // for the whole write transaction and we assume that this means it is commited to DRAM.
         // We are now free to update write_addr pointer and go back to idle state.
         // 
         INPUT5: begin
            write_ctrl_valid <= 1'b0;
            if (write_ctrl_ready) begin
               write_addr <= ((write_addr + ((write_count_expanded + 1) << 3)) & set_fifo_addr_mask_bar) | (write_addr & set_fifo_addr_mask);
               input_state <= INPUT6;
               update_write <= 1'b1;
            end else begin
               input_state <= INPUT5;
            end
         end
         //
         // INPUT6:
         // Need to let space update before looking if there's more to do.
         //
         INPUT6: begin
            if((last_write_addr & {{{AWIDTH}{1'b1}} << (setting_input_frame_size_log2+setting_mod_sync_frames_log2+setting_reorder_factor_log2+3)}) != (write_addr & {{{AWIDTH}{1'b1}} << (setting_input_frame_size_log2+setting_mod_sync_frames_log2+setting_reorder_factor_log2+3)})) begin
            //if(last_write_addr[AWIDTH-1:INPUT_FRAME_SIZE_LOG2+MOD_SYNC_FRAMES_LOG2+REORDER_FACTOR_LOG2+3] != write_addr[AWIDTH-1:INPUT_FRAME_SIZE_LOG2+MOD_SYNC_FRAMES_LOG2+REORDER_FACTOR_LOG2+3]) begin
                trigger_new_superframe <= 1'b1;
            end else begin
                trigger_new_superframe <= 1'b0;
            end
            last_write_addr <= write_addr;
            input_state <= INPUT_IDLE;
            update_write <= 1'b0;
         end

         default: 
            input_state <= INPUT_IDLE;
      endcase // case(input_state)


   //
   // Simple output timeout counter for now
   //
   always @(posedge dram_clk)
      if (dram_reset | clear) begin
         output_timeout_count <= 0;
         output_timeout_triggered <= 1'b0;
      end else if (output_timeout_reset) begin
         output_timeout_count <= 0;
         output_timeout_triggered <= 1'b0;
      end else if ((output_timeout_count == set_timeout) && (set_timeout != 0)) begin
         output_timeout_triggered <= 1'b1;
      end else if (output_state == OUTPUT_IDLE) begin
         output_timeout_count <= output_timeout_count + (occupied != 0);
     end


   //
   // Wait for 64 entries in main FIFO to trigger DRAM read burst.
   // Timeout can also trigger burst so fragments of data are not left to rot in the main FIFO.
   // Also if enough data is present in the main FIFO to complete a burst upto the edge
   // of a 4KByte page then immediately start the burst.
   //
   integer bit_idx;
   always @(posedge dram_clk)
      if (dram_reset | clear) begin
         output_state <= OUTPUT_IDLE;
         read_addr <= set_fifo_base_addr & set_fifo_addr_mask;
         output_timeout_reset <= 1'b0;
         read_ctrl_valid <= 1'b0;
         read_count <= 8'd0;
         update_read <= 1'b0;
         sync_ack_sync <= 1'b0;
         clear_output_fifos <= 1'b0;
         sync_req_sync_d <= 5'd0;
      end else begin
         sync_req_sync_d <= {sync_req_sync_d[3:0], sync_req_sync};
         case (output_state)
         //
         // OUTPUT_IDLE.
         // To start an output tranfer from DRAM
         // 1) Space in the small output FIFO 
         // and either
         // 2) 256 entrys in the DRAM FIFO
         // or
         // 3) Timeout waiting for more data.
         //
         OUTPUT_IDLE: begin
            read_ctrl_valid <= 1'b0;
            update_read <= 1'b0;
            sync_ack_sync <= 1'b0;
            clear_output_fifos <= 1'b0;
            if (sync_req_sync_d[3] & sync_req_sync_d[4]) begin
               output_state <= OUTPUT_SYNC;
            end else if (space_output > 255) begin // Space in the output FIFO.
               if (occupied > 255) begin // 64 or more entrys in main FIFO
                  output_state <= OUTPUT1;
                  output_timeout_reset <= 1'b1;
               end else if (output_timeout_triggered) begin // output FIFO timeout waiting for new data.
                  output_state <= OUTPUT2;
                  output_timeout_reset <= 1'b1;
               end else begin
                  output_timeout_reset <= 1'b0;
                  output_state <= OUTPUT_IDLE;
               end
            end else begin
               output_timeout_reset <= 1'b0;
               output_state <= OUTPUT_IDLE;
            end
         end // case: OUTPUT_IDLE
         OUTPUT_SYNC: begin
            if(sync_latest_sync) begin
                for(bit_idx=0; bit_idx<AWIDTH; bit_idx=bit_idx+1) begin
                    if(bit_idx >= setting_input_frame_size_log2+setting_mod_sync_frames_log2+setting_reorder_factor_log2+3)
                        read_addr[bit_idx] <= write_addr[bit_idx];
                end
            end else begin
                for(bit_idx=0; bit_idx<AWIDTH; bit_idx=bit_idx+1) begin
                    if(bit_idx >= setting_input_frame_size_log2+setting_mod_sync_frames_log2+setting_reorder_factor_log2+3)
                        read_addr[bit_idx] <= (write_addr_lastframe[bit_idx] & set_fifo_addr_mask_bar[bit_idx]) | set_fifo_base_addr[bit_idx];
                end
            end
            for(bit_idx=0; bit_idx<AWIDTH; bit_idx=bit_idx+1) begin
                if(bit_idx < setting_input_frame_size_log2+setting_mod_sync_frames_log2+setting_reorder_factor_log2+3)
                    read_addr[bit_idx] <= 1'b0;
            end
            clear_output_fifos <= 1'b1;
            output_state <= OUTPUT_SYNC_WAIT;
         end
         OUTPUT_SYNC_WAIT: begin
            sync_ack_sync <= 1'b1;
            clear_output_fifos <= 1'b1;
            if((sync_req_sync_d[3] & sync_req_sync_d[4]) == 1'b0) begin
               output_state <= OUTPUT_IDLE;
            end
         end
         //
         // OUTPUT1.
         // TODO: OUTPUT1 and OUTPUT2 are currently the same.  Should merge...
         // Caused by main FIFO reaching 256 entries.
         // Request read burst of lesser of lesser of:
         // 1) Entrys until page boundry crossed
         // 2) 256.
         //
         OUTPUT1: begin
            read_count <= setting_input_frame_size_mask;//(output_page_boundry < 255) ? output_page_boundry : 8'd255;
            read_ctrl_valid <= 1'b1;
            if (read_ctrl_ready)
               output_state <= OUTPUT4; // Pre-emptive ACK
            else
               output_state <= OUTPUT3; // Wait for ACK
         end
         //
         // OUTPUT2.
         // Caused by timeout of main FIFO
         // Request read burst of lesser of:
         // 1) Entries until page boundry crossed
         // 2) Entries in main FIFO
         //
         OUTPUT2: begin
            read_count <= setting_input_frame_size_mask;//(output_page_boundry < (occupied - 1)) ? output_page_boundry : (occupied - 1);
            read_ctrl_valid <= 1'b1;
            if (read_ctrl_ready)
               output_state <= OUTPUT4; // Pre-emptive ACK
            else
               output_state <= OUTPUT3; // Wait for ACK
         end
         //
         // OUTPUT3.
         // Wait in this state for AXI4_DMA engine to accept transaction.
         //
         OUTPUT3: begin
            if (read_ctrl_ready) begin
               read_ctrl_valid <= 1'b0;
               output_state <= OUTPUT4; // ACK
            end else begin
               read_ctrl_valid <= 1'b1;
               output_state <= OUTPUT3; // Wait for ACK
            end
         end
         //
         // OUTPUT4.
         // Wait here unitl read_ctrl_ready_deasserts.
         // This is important as the next time it asserts we know that a read response was receieved.
         OUTPUT4: begin
            read_ctrl_valid <= 1'b0;
            if (!read_ctrl_ready)
               output_state <= OUTPUT5; // Move on
            else
               output_state <= OUTPUT4; // Wait for deassert
         end   
         //
         // OUTPUT5.
         // Transaction has been accepted by AXI4 DMA engine. Now we wait for the re-assertion
         // of read_ctrl_ready which signals that the AXI4 DMA engine has receieved a last signal and good response
         // for the whole read transaction.
         // We are now free to update read_addr pointer and go back to idle state.
         // 
         OUTPUT5: begin
            read_ctrl_valid <= 1'b0;
            if (read_ctrl_ready) begin
               read_addr <= ((read_addr + ((read_count_expanded + 1) << 3)) & set_fifo_addr_mask_bar) | (read_addr & set_fifo_addr_mask);
               output_state <= OUTPUT6;
               update_read <= 1'b1;
            end else begin
               output_state <= OUTPUT5;
            end
         end // case: OUTPUT5
         //
         // OUTPUT6.
         // Need to get occupied value updated before checking if there's more to do.
         //
         OUTPUT6: begin
            update_read <= 1'b0;
            output_state <= OUTPUT_IDLE;
         end

         default: 
            output_state <= OUTPUT_IDLE;
       endcase // case(output_state)
       end

   //
   // Calculate number of entries remaining until next 4KB page boundry is crossed minus 1.
   // Note, units of calculation are 64bit wide words. Address is always 64bit alligned.
   //
   assign input_page_boundry = {write_addr[AWIDTH-1:12],9'h1ff} - write_addr[AWIDTH-1:3];   
   assign output_page_boundry = {read_addr[AWIDTH-1:12],9'h1ff} - read_addr[AWIDTH-1:3];
   
   //
   // Count number of used entries in main DRAM FIFO.
   // Note that this is expressed in units of 64bit wide words.
   //
   always @(posedge dram_clk)
      if (dram_reset | clear)
         occupied <= 0;
      else
         occupied <= write_addr[AWIDTH-1:3] - read_addr[AWIDTH-1:3];
         //if(output_state == OUTPUT_SYNC) begin
         //  if(sync_latest_sync) begin
         //      occupied <= (write_addr[AWIDTH-1:3] & ~({{AWIDTH-3}{1'b1}} << setting_input_frame_size_log2+setting_mod_sync_frames_log2+setting_reorder_factor_log2)) + (update_write ? write_count_expanded + 1 : 0);
         //  end else begin
         //      occupied <= (write_addr[AWIDTH-1:3] & ~({{AWIDTH-3}{1'b1}} << setting_input_frame_size_log2+setting_mod_sync_frames_log2+setting_reorder_factor_log2)) + (update_write ? write_count_expanded + 1 : 0) + (1 << (setting_input_frame_size_log2+setting_mod_sync_frames_log2+setting_reorder_factor_log2));
         //  end
         //end else begin
         //  occupied <= occupied + (update_write ? write_count_expanded + 1 : 0) - (update_read ? read_count_expanded + 1 : 0);
         //end
   
   always @(posedge dram_clk)
      if (dram_reset | clear)
         space <= set_fifo_addr_mask_bar[AWIDTH-1:3] & ~('d63); // Subtract 64 from space to make allowance for read/write reordering in DRAM controller
      else
         if(output_state == OUTPUT_SYNC)
           space <= (set_fifo_addr_mask_bar[AWIDTH-1:3] & (({{AWIDTH-3}{1'b1}} << setting_input_frame_size_log2-setting_mod_sync_frames_log2-setting_reorder_factor_log2) | (write_addr[AWIDTH-1:3] & ~({{AWIDTH-3}{1'b1}} << setting_input_frame_size_log2+setting_mod_sync_frames_log2+setting_reorder_factor_log2-1)))) - (update_write ? write_count_expanded + 1 : 0);
         else
           space <= space - (update_write ? write_count_expanded + 1 : 0) + (update_read ? read_count_expanded + 1 : 0);

   //
   // Flush logic
   //
   localparam FLUSH_STATE_IDLE = 0;
   localparam FLUSH_STATE_WAIT_TLAST = 1;
   localparam FLUSH_STATE_FLUSH = 2;
   localparam FLUSH_STATE_DONE = 3;
   reg [3:0] flush_state, next_flush_state;
   always @(posedge bus_clk) begin
       if(bus_reset | clear) begin
           flush_state <= FLUSH_STATE_IDLE;
       end else begin
           flush_state <= next_flush_state;
       end
   end

   always @* begin
       next_flush_state = flush_state;
       i_tready_flush = 1'b1;
       flush_done = 1'b0;

       case (flush_state)
           FLUSH_STATE_IDLE: begin
               if(flush_req) begin
                   next_flush_state = FLUSH_STATE_WAIT_TLAST;
               end
           end

           FLUSH_STATE_WAIT_TLAST: begin
               if(i_tlast & i_tvalid & i_tready) begin
                   next_flush_state = FLUSH_STATE_FLUSH;
               end
           end

           FLUSH_STATE_FLUSH: begin
               i_tready_flush = 1'b0;
               if(empty) begin
                   next_flush_state = FLUSH_STATE_DONE;
               end
           end

           FLUSH_STATE_DONE: begin
               flush_done = 1'b1;
               if(flush_req == 1'b0) begin
                   next_flush_state = FLUSH_STATE_IDLE;
               end
           end
       endcase
   end

   //
   // Instamce of axi_dma_master
   //
   axi_dma_master axi_dma_master_i
   (
      .aclk(dram_clk), // input aclk
      .areset(dram_reset | clear), // input aresetn
      // Write control
      .m_axi_awid(m_axi_awid), // input [0 : 0] m_axi_awid
      .m_axi_awaddr(m_axi_awaddr), // input [31 : 0] m_axi_awaddr
      .m_axi_awlen(m_axi_awlen), // input [7 : 0] m_axi_awlen
      .m_axi_awsize(m_axi_awsize), // input [2 : 0] m_axi_awsize
      .m_axi_awburst(m_axi_awburst), // input [1 : 0] m_axi_awburst
      .m_axi_awvalid(m_axi_awvalid), // input m_axi_awvalid
      .m_axi_awready(m_axi_awready), // output m_axi_awready
      .m_axi_awlock(m_axi_awlock),
      .m_axi_awcache(m_axi_awcache),
      .m_axi_awprot(m_axi_awprot),
      .m_axi_awqos(m_axi_awqos),
      .m_axi_awregion(m_axi_awregion),
      .m_axi_awuser(m_axi_awuser),
      // Write Data
      .m_axi_wdata(m_axi_wdata), // input [63 : 0] m_axi_wdata
      .m_axi_wstrb(m_axi_wstrb), // input [7 : 0] m_axi_wstrb
      .m_axi_wlast(m_axi_wlast), // input m_axi_wlast
      .m_axi_wvalid(m_axi_wvalid), // input m_axi_wvalid
      .m_axi_wready(m_axi_wready), // output m_axi_wready
      .m_axi_wuser(),
      // Write Response
      .m_axi_bid(m_axi_bid), // output [0 : 0] m_axi_bid
      .m_axi_bresp(m_axi_bresp), // output [1 : 0] m_axi_bresp
      .m_axi_bvalid(m_axi_bvalid), // output m_axi_bvalid
      .m_axi_bready(m_axi_bready), // input m_axi_bready
      .m_axi_buser(),
      // Read Control
      .m_axi_arid(m_axi_arid), // input [0 : 0] m_axi_arid
      .m_axi_araddr(m_axi_araddr), // input [31 : 0] m_axi_araddr
      .m_axi_arlen(m_axi_arlen), // input [7 : 0] m_axi_arlen
      .m_axi_arsize(m_axi_arsize), // input [2 : 0] m_axi_arsize
      .m_axi_arburst(m_axi_arburst), // input [1 : 0] m_axi_arburst
      .m_axi_arvalid(m_axi_arvalid), // input m_axi_arvalid
      .m_axi_arready(m_axi_arready), // output m_axi_arready
      .m_axi_arlock(m_axi_arlock),
      .m_axi_arcache(m_axi_arcache),
      .m_axi_arprot(m_axi_arprot),
      .m_axi_arqos(m_axi_arqos),
      .m_axi_arregion(m_axi_arregion),
      .m_axi_aruser(m_axi_aruser),
      // Read Data
      .m_axi_rid(m_axi_rid), // output [0 : 0] m_axi_rid
      .m_axi_rdata(m_axi_rdata), // output [63 : 0] m_axi_rdata
      .m_axi_rresp(m_axi_rresp), // output [1 : 0] m_axi_rresp
      .m_axi_rlast(m_axi_rlast), // output m_axi_rlast
      .m_axi_rvalid(m_axi_rvalid), // output m_axi_rvalid
      .m_axi_rready(m_axi_rready), // input m_axi_rready
      .m_axi_ruser(),
      //
      // DMA interface for Write transaction
      //
      .write_addr({3'b101, write_addr_reordered[AWIDTH-2:0]}),       // Byte address for start of write transaction (should be 64bit alligned)
      .write_count(write_count),       // Count of 64bit words to write.
      .write_ctrl_valid(write_ctrl_valid),
      .write_ctrl_ready(write_ctrl_ready),
      .write_data(i_tdata_input),
      .write_data_valid(i_tvalid_input),
      .write_data_ready(i_tready_input),
      //
      // DMA interface for Read
      //
      .read_addr({3'b101, read_addr[AWIDTH-2:0]}),       // Byte address for start of read transaction (should be 64bit alligned)
      .read_count(read_count),       // Count of 64bit words to read.
      .read_ctrl_valid(read_ctrl_valid),
      .read_ctrl_ready(read_ctrl_ready),
      .read_data(o_tdata_output),
      .read_data_valid(o_tvalid_output),
      .read_data_ready(o_tready_output),
      //
      // Debug
      //
      .debug()
   );

 //assign debug = {o_tready, i_tready, i_tready_int, i_tready_fifo, i_tready_bist, o_tready_fifo, o_tready_bist, o_tready_gate, i_tready_i0, i_tready_i1, i_tready_i2, i_tready_i3, i_tready_input, o_tready_output, o_tready_i0, o_tready_i1, o_tready_i2, o_tready_i3, o_tready_i4, o_tready_i5};
 reg [AWIDTH-1:0]  wr_addr;
 always @(posedge dram_clk) begin
   wr_addr <= write_addr-read_addr;
 end
 assign debug = {occupied, wr_addr};
 assign debug2 = {read_addr, write_addr};
 endmodule // axi_dma_fifo

