
module axi_mrr_gateway #(
  parameter NUM_FIFOS = 2,                      //Number of FIFOs that share the AXI4 memory space (max 4)
  parameter [NUM_FIFOS*30-1:0] DEFAULT_FIFO_BASE = {30'h00000000, 30'h02000000}, //Default base addr for each FIFO (configurable via setting reg)
  parameter [NUM_FIFOS*30-1:0] DEFAULT_FIFO_SIZE = {30'h01FFFFFF, 30'h01FFFFFF}, //Default size of each FIFO (configurable via setting reg)
  parameter [NUM_FIFOS*12-1:0] DEFAULT_BURST_TIMEOUT = {12'd280, 12'd280}, //Timeout (in memory clock cycles) for issuing smaller than optimal bursts
  parameter EXTENDED_DRAM_BIST = 1              //Prune out additional BIST features for production
)(
  input ce_clk, input ce_rst_in,

  input enable,
  input soft_reset,

  inout [7:0] PROG_D,
  input PROG_CLKO,
  output reg PROG_OEN,
  output reg PROG_RDN,
  input  PROG_RXFN,
  output reg PROG_SIWUN,
  output reg PROG_SPIEN,
  input PROG_TXEN,
  output reg PROG_WRN,

  input          adc_clk,
  input          adc_enable_i0,
  input          adc_valid_i0,
  input  [15:0]  adc_data_i0,
  input          adc_enable_q0,
  input          adc_valid_q0,
  input  [15:0]  adc_data_q0,

  output          out_enable_i0,
  output          out_valid_i0,
  output  [15:0]  out_data_i0,
  output          out_enable_q0,
  output          out_valid_q0,
  output  [15:0]  out_data_q0,

  // axi interface

  input                 s_axi_aclk,
  input                 s_axi_aresetn,
  input                 s_axi_awvalid,
  input       [ 6:0]    s_axi_awaddr,
  input       [ 2:0]    s_axi_awprot,
  output                s_axi_awready,
  input                 s_axi_wvalid,
  input       [31:0]    s_axi_wdata,
  input       [ 3:0]    s_axi_wstrb,
  output                s_axi_wready,
  output                s_axi_bvalid,
  output      [ 1:0]    s_axi_bresp,
  input                 s_axi_bready,
  input                 s_axi_arvalid,
  input       [ 6:0]    s_axi_araddr,
  input       [ 2:0]    s_axi_arprot,
  output                s_axi_arready,
  output                s_axi_rvalid,
  output      [31:0]    s_axi_rdata,
  output      [ 1:0]    s_axi_rresp,
  input                 s_axi_rready,

  //
  // AXI Memory Mapped Interface 1
  //
  // -- AXI Write address channel
  input         m_axi_aclk,
  input         m_axi_aresetn,
  output        m_axi_awid,     // Write address ID. This signal is the identification tag for the write address signals
  output [31:0] m_axi_awaddr,   // Write address. The write address gives the address of the first transfer in a write burst
  output [7:0]  m_axi_awlen,    // Burst length. The burst length gives the exact number of transfers in a burst.
  output [2:0]  m_axi_awsize,   // Burst size. This signal indicates the size of each transfer in the burst. 
  output [1:0]  m_axi_awburst,  // Burst type. The burst type and the size information, determine how the address is calculated
  output        m_axi_awlock,   // Lock type. Provides additional information about the atomic characteristics of the transfer.
  output [3:0]  m_axi_awcache,  // Memory type. This signal indicates how transactions are required to progress
  output [2:0]  m_axi_awprot,   // Protection type. This signal indicates the privilege and security level of the transaction
  output [3:0]  m_axi_awqos,    // Quality of Service, QoS. The QoS identifier sent for each write transaction
  output [3:0]  m_axi_awregion, // Region identifier. Permits a single physical interface on a slave to be re-used.
  output        m_axi_awuser,   // User signal. Optional User-defined signal in the write address channel.
  output        m_axi_awvalid,  // Write address valid. This signal indicates that the channel is signaling valid write addr
  input         m_axi_awready,  // Write address ready. This signal indicates that the slave is ready to accept an address
  // -- AXI Write data channel.
  output [63:0] m_axi_wdata,    // Write data
  output [7:0]  m_axi_wstrb,    // Write strobes. This signal indicates which byte lanes hold valid data.
  output        m_axi_wlast,    // Write last. This signal indicates the last transfer in a write burst
  output        m_axi_wuser,    // User signal. Optional User-defined signal in the write data channel.
  output        m_axi_wvalid,   // Write valid. This signal indicates that valid write data and strobes are available. 
  input         m_axi_wready,   // Write ready. This signal indicates that the slave can accept the write data.
  // -- AXI Write response channel signals
  input         m_axi_bid,      // Response ID tag. This signal is the ID tag of the write response. 
  input  [1:0]  m_axi_bresp,    // Write response. This signal indicates the status of the write transaction.
  input         m_axi_buser,    // User signal. Optional User-defined signal in the write response channel.
  input         m_axi_bvalid,   // Write response valid. This signal indicates that the channel is signaling a valid response
  output        m_axi_bready,   // Response ready. This signal indicates that the master can accept a write response
  // -- AXI Read address channel
  output        m_axi_arid,     // Read address ID. This signal is the identification tag for the read address group of signals
  output [31:0] m_axi_araddr,   // Read address. The read address gives the address of the first transfer in a read burst
  output [7:0]  m_axi_arlen,    // Burst length. This signal indicates the exact number of transfers in a burst.
  output [2:0]  m_axi_arsize,   // Burst size. This signal indicates the size of each transfer in the burst.
  output [1:0]  m_axi_arburst,  // Burst type. The burst type and the size information determine how the address for each transfer
  output        m_axi_arlock,   // Lock type. This signal provides additional information about the atomic characteristics
  output [3:0]  m_axi_arcache,  // Memory type. This signal indicates how transactions are required to progress 
  output [2:0]  m_axi_arprot,   // Protection type. This signal indicates the privilege and security level of the transaction
  output [3:0]  m_axi_arqos,    // Quality of Service, QoS. QoS identifier sent for each read transaction.
  output [3:0]  m_axi_arregion, // Region identifier. Permits a single physical interface on a slave to be re-used
  output        m_axi_aruser,   // User signal. Optional User-defined signal in the read address channel.
  output        m_axi_arvalid,  // Read address valid. This signal indicates that the channel is signaling valid read addr
  input         m_axi_arready,  // Read address ready. This signal indicates that the slave is ready to accept an address
  // -- AXI Read data channel
  input         m_axi_rid,      // Read ID tag. This signal is the identification tag for the read data group of signals
  input  [63:0] m_axi_rdata,    // Read data.
  input  [1:0]  m_axi_rresp,    // Read response. This signal indicates the status of the read transfer
  input         m_axi_rlast,    // Read last. This signal indicates the last transfer in a read burst.
  input         m_axi_ruser,    // User signal. Optional User-defined signal in the read data channel.
  input         m_axi_rvalid,   // Read valid. This signal indicates that the channel is signaling the required read data. 
  output        m_axi_rready,   // Read ready. This signal indicates that the master can accept the read data and response

  //
  // AXI Memory Mapped Interface 2
  //
  // -- AXI Write address channel
  input         m_axi2_aclk,
  input         m_axi2_aresetn,
  output        m_axi2_awid,     // Write address ID. This signal is the identification tag for the write address signals
  output [31:0] m_axi2_awaddr,   // Write address. The write address gives the address of the first transfer in a write burst
  output [7:0]  m_axi2_awlen,    // Burst length. The burst length gives the exact number of transfers in a burst.
  output [2:0]  m_axi2_awsize,   // Burst size. This signal indicates the size of each transfer in the burst. 
  output [1:0]  m_axi2_awburst,  // Burst type. The burst type and the size information, determine how the address is calculated
  output        m_axi2_awlock,   // Lock type. Provides additional information about the atomic characteristics of the transfer.
  output [3:0]  m_axi2_awcache,  // Memory type. This signal indicates how transactions are required to progress
  output [2:0]  m_axi2_awprot,   // Protection type. This signal indicates the privilege and security level of the transaction
  output [3:0]  m_axi2_awqos,    // Quality of Service, QoS. The QoS identifier sent for each write transaction
  output [3:0]  m_axi2_awregion, // Region identifier. Permits a single physical interface on a slave to be re-used.
  output        m_axi2_awuser,   // User signal. Optional User-defined signal in the write address channel.
  output        m_axi2_awvalid,  // Write address valid. This signal indicates that the channel is signaling valid write addr
  input         m_axi2_awready,  // Write address ready. This signal indicates that the slave is ready to accept an address
  // -- AXI Write data channel.
  output [63:0] m_axi2_wdata,    // Write data
  output [7:0]  m_axi2_wstrb,    // Write strobes. This signal indicates which byte lanes hold valid data.
  output        m_axi2_wlast,    // Write last. This signal indicates the last transfer in a write burst
  output        m_axi2_wuser,    // User signal. Optional User-defined signal in the write data channel.
  output        m_axi2_wvalid,   // Write valid. This signal indicates that valid write data and strobes are available. 
  input         m_axi2_wready,   // Write ready. This signal indicates that the slave can accept the write data.
  // -- AXI Write response channel signals
  input         m_axi2_bid,      // Response ID tag. This signal is the ID tag of the write response. 
  input  [1:0]  m_axi2_bresp,    // Write response. This signal indicates the status of the write transaction.
  input         m_axi2_buser,    // User signal. Optional User-defined signal in the write response channel.
  input         m_axi2_bvalid,   // Write response valid. This signal indicates that the channel is signaling a valid response
  output        m_axi2_bready,   // Response ready. This signal indicates that the master can accept a write response
  // -- AXI Read address channel
  output        m_axi2_arid,     // Read address ID. This signal is the identification tag for the read address group of signals
  output [31:0] m_axi2_araddr,   // Read address. The read address gives the address of the first transfer in a read burst
  output [7:0]  m_axi2_arlen,    // Burst length. This signal indicates the exact number of transfers in a burst.
  output [2:0]  m_axi2_arsize,   // Burst size. This signal indicates the size of each transfer in the burst.
  output [1:0]  m_axi2_arburst,  // Burst type. The burst type and the size information determine how the address for each transfer
  output        m_axi2_arlock,   // Lock type. This signal provides additional information about the atomic characteristics
  output [3:0]  m_axi2_arcache,  // Memory type. This signal indicates how transactions are required to progress 
  output [2:0]  m_axi2_arprot,   // Protection type. This signal indicates the privilege and security level of the transaction
  output [3:0]  m_axi2_arqos,    // Quality of Service, QoS. QoS identifier sent for each read transaction.
  output [3:0]  m_axi2_arregion, // Region identifier. Permits a single physical interface on a slave to be re-used
  output        m_axi2_aruser,   // User signal. Optional User-defined signal in the read address channel.
  output        m_axi2_arvalid,  // Read address valid. This signal indicates that the channel is signaling valid read addr
  input         m_axi2_arready,  // Read address ready. This signal indicates that the slave is ready to accept an address
  // -- AXI Read data channel
  input         m_axi2_rid,      // Read ID tag. This signal is the identification tag for the read data group of signals
  input  [63:0] m_axi2_rdata,    // Read data.
  input  [1:0]  m_axi2_rresp,    // Read response. This signal indicates the status of the read transfer
  input         m_axi2_rlast,    // Read last. This signal indicates the last transfer in a read burst.
  input         m_axi2_ruser,    // User signal. Optional User-defined signal in the read data channel.
  input         m_axi2_rvalid,   // Read valid. This signal indicates that the channel is signaling the required read data. 
  output        m_axi2_rready,   // Read ready. This signal indicates that the master can accept the read data and response

  output [15:0] debug
);
  localparam NUM_INPUTS = 1; //Input Port 0: IQ Data (input-output synchronized)
                             //NO MORE: Input Port 1: FFT Data
  localparam NUM_OUTPUTS = 3;//Output Port 0: IQ Data (input-output synchronized)
                             //Output Port 1: Decoded Soft Symbols
  `include "mrr_params.vh"
  `include "git_version.vh"

  //TODO: Any other valid sources for 'clear' signal?
  wire clear = 1'b0;

  /////////////////////////////////////////////////////////////
  //
  // DPTI (FT245) FIFO Interface
  //
  ////////////////////////////////////////////////////////////
  wire record_en;
  reg dpti_fifo_rd_en;
  wire dpti_fifo_rd_empty;
  reg dpti_shift_reset;
  reg dpti_shift_en;
  reg dpti_rd_push;
  reg next_oen;
  reg next_rdn;
  reg dpti_shift_rd_out;
  reg [2:0] dpti_state, next_dpti_state;
  reg [1:0] enable_last;
  reg [2:0] dpti_shift_ctr;
  reg [39:0] dpti_d_shift;
  wire [39:0] dpti_fifo_rd;
  reg [39:0] dpti_shift_rd;
  reg [2:0] dpti_shift_rd_ctr;
  assign PROG_D = (PROG_OEN) ? dpti_d_shift[39-:8] : 8'hzz;

  localparam DPTI_STATE_IDLE = 0;
  localparam DPTI_STATE_TX_WORD = 1;
  localparam DPTI_STATE_RX_WORD1 = 2;
  localparam DPTI_STATE_RX_WORD2 = 3;

  always @(posedge PROG_CLKO or posedge ce_rst) begin
    PROG_SIWUN <= 1'b1;
    PROG_SPIEN <= 1'b1;
    enable_last <= {enable_last[0], enable};

    if(ce_rst) begin
      dpti_d_shift <= 0;
      dpti_state <= DPTI_STATE_IDLE;
      dpti_shift_rd_ctr <= 0;
      dpti_rd_push <= 1'b0;
      dpti_shift_rd <= 0;
      PROG_OEN <= 1'b1;
    end else begin
      PROG_OEN <= next_oen;
      dpti_state <= next_dpti_state;
      if(dpti_shift_reset) begin
        dpti_d_shift <= dpti_fifo_rd;
        dpti_shift_ctr <= 0;
      end else if(dpti_shift_en) begin
        dpti_d_shift <= {dpti_d_shift[31:0], 8'd0};
        dpti_shift_ctr <= dpti_shift_ctr + 1;
      end

      dpti_rd_push <= 1'b0;
      if(dpti_shift_rd_out) begin
        dpti_shift_rd_ctr <= dpti_shift_rd_ctr + 1;
        dpti_shift_rd <= {dpti_shift_rd[31:0], PROG_D};
        if(dpti_shift_rd_ctr == 4) begin
          dpti_shift_rd_ctr <= 0;
          dpti_rd_push <= 1'b1;
        end
      end
    end
  end

  always @* begin
    PROG_RDN = 1'b1;
    next_dpti_state = dpti_state;
    next_oen = 1'b1;
    next_rdn = 1'b1;
    dpti_shift_reset = 1'b0;
    dpti_shift_en = 1'b0;
    dpti_shift_rd_out = 1'b0;
    dpti_fifo_rd_en = 1'b0;
    PROG_WRN = 1'b1;
    case(dpti_state)

      DPTI_STATE_IDLE: begin
        dpti_shift_reset = 1'b1;
        if(~PROG_RXFN) begin
          next_dpti_state = DPTI_STATE_RX_WORD1;
        end else if(~dpti_fifo_rd_empty) begin
          next_dpti_state = DPTI_STATE_TX_WORD;
        end
      end

      DPTI_STATE_TX_WORD: begin
        PROG_WRN = 1'b0;
        dpti_shift_en = (PROG_TXEN == 1'b0);
        dpti_shift_reset = dpti_shift_en & (dpti_shift_ctr == 3'd4);
        dpti_fifo_rd_en = dpti_shift_en & (dpti_shift_ctr == 3'd0);
        if(dpti_shift_reset & dpti_fifo_rd_empty) begin
          next_dpti_state = DPTI_STATE_IDLE;
        end
      end

      DPTI_STATE_RX_WORD1: begin
        next_oen = 1'b0;
        next_dpti_state = DPTI_STATE_RX_WORD2;
      end

      DPTI_STATE_RX_WORD2: begin
        next_oen = 1'b0;
        PROG_RDN = 1'b0;
        dpti_shift_rd_out = ((PROG_RDN == 1'b0) && (PROG_RXFN == 1'b0));
        if(PROG_RXFN) begin//(dpti_shift_rd_out == 1'b1) && (dpti_shift_rd_ctr == 4)) begin
          next_dpti_state = DPTI_STATE_IDLE;
        end
      end
    endcase
  end

  reg [31:0] out_decoded_tdata_counter;
  wire ce_rst;
  always @(posedge ce_clk) begin
    if(ce_rst) begin
      out_decoded_tdata_counter <= 0;
    end else begin
      if(out_decoded_tvalid) begin
        out_decoded_tdata_counter <= out_decoded_tdata_counter + 1;
      end
    end
  end

  wire dpti_fifo_full;
  wire dpti_fifo_valid;
  wire [39:0] dpti_fifo_wr;
  wire [31:0] dpti_fifo_unused;
  fifo_short_2clk dpti_fifo (
    .rst(ce_rst),
    .wr_clk(ce_clk),
    .din({32'd0,dpti_fifo_wr}),
    .wr_en(dpti_fifo_valid),
    .full(dpti_fifo_full),
    .wr_data_count(),
    .rd_clk(PROG_CLKO),
    .dout({dpti_fifo_unused,dpti_fifo_rd}),
    .rd_en(dpti_fifo_rd_en),
    .empty(dpti_fifo_rd_empty),
    .rd_data_count()
  );

  wire [31:0] set_data;
  wire [7:0]  set_addr;
  wire        set_empty;
  wire        set_stb = ~set_empty;
  fifo_short_2clk dpti_rd_fifo (
    .rst(ce_rst),
    .wr_clk(PROG_CLKO),
    .din(dpti_shift_rd),
    .wr_en(dpti_rd_push),
    .full(),
    .wr_data_count(),
    .rd_clk(ce_clk),
    .dout({set_addr,set_data}),
    .rd_en(1'b1),
    .empty(set_empty),
    .rd_data_count()
  );

  //out_decoded_tlast,7'd0,out_decoded_tdata}),
  //out_decoded_tvalid
  localparam NUM_MUX_CHANNELS = 3;
  localparam NUM_MUX_CHANNELS_LOG2 = 2;
  wire [NUM_MUX_CHANNELS-1:0] dpti_fifo_pre_tvalids;
  reg [NUM_MUX_CHANNELS-1:0] dpti_fifo_pre_treadies;
  wire [39:0] dpti_fifo_pre_tdatas [NUM_MUX_CHANNELS-1:0];
  reg [NUM_MUX_CHANNELS-1:0] dpti_fifo_pre_tvalids_saved;
  reg [39:0] dpti_fifo_pre_tdatas_saved [NUM_MUX_CHANNELS-1:0];
  reg [39:0] dpti_fifo_pre_tdata;
  reg dpti_fifo_pre_tvalid;
  wire dpti_fifo_pre_tready;
  reg [15:0] dpti_fifo_pre_tdata_count;
  axi_fifo #(
    .WIDTH(40),
    .SIZE(12))
  dpti_fifo_pre (
    .clk(ce_clk),
    .reset(ce_rst),
    .clear(clear),
    .i_tdata(dpti_fifo_pre_tdata),//{dpti_fifo_pre_tdata[39:16],dpti_fifo_pre_tdata_count}),
    .i_tvalid(dpti_fifo_pre_tvalid),
    .i_tready(dpti_fifo_pre_tready),
    .o_tdata(dpti_fifo_wr),
    .o_tvalid(dpti_fifo_valid),
    .o_tready(~dpti_fifo_full)
  );

  reg [NUM_MUX_CHANNELS_LOG2-1:0] dpti_fifo_pre_arb_idx;
  reg dpti_fifo_pre_arb_valid;
  integer arb_idx;
  always @* begin
    dpti_fifo_pre_arb_idx = 0;
    dpti_fifo_pre_arb_valid = 1'b0;
    for(arb_idx=0; arb_idx < NUM_MUX_CHANNELS; arb_idx=arb_idx+1) begin
      if(dpti_fifo_pre_tvalids[arb_idx]) begin
        dpti_fifo_pre_arb_valid = 1'b1;
        dpti_fifo_pre_arb_idx = arb_idx;
      end
    end
  end

  localparam DPTI_PRE_IDLE = 0;
  localparam DPTI_PRE_WAIT_ON_PATH = 1;
  localparam DPTI_PRE_FLUSH_SAVED_DATA = 2;
  reg [NUM_MUX_CHANNELS_LOG2-1:0] cur_pre_arb_idx, cur_pre_idx;
  reg [1:0] dpti_fifo_pre_state, next_dpti_fifo_pre_state;
  reg save_pre_arb_idx;
  reg reset_pre_cur_idx;
  reg incr_pre_cur_idx;
  reg [31:0] record_count;

  integer cur_idx;
  always @(posedge ce_clk) begin
    if(ce_rst) begin
      dpti_fifo_pre_tdata_count <= 0;
      cur_pre_arb_idx <= 0;
      cur_pre_idx <= 0;
      dpti_fifo_pre_state <= DPTI_PRE_IDLE;
      record_count <= 0;
      for(cur_idx=0; cur_idx < NUM_MUX_CHANNELS; cur_idx=cur_idx+1) begin
        dpti_fifo_pre_tvalids_saved[cur_idx] <= 0;
        dpti_fifo_pre_tdatas_saved[cur_idx] <= 0;
      end
    end else begin
      if(~record_en) begin
          record_count <= 0;
      end else begin
          if(dpti_fifo_pre_tvalids[2] & dpti_fifo_pre_treadies[2]) begin
              record_count <= record_count + 1;
          end
      end
      if(dpti_fifo_pre_tvalid & dpti_fifo_pre_tready) begin
          dpti_fifo_pre_tdata_count <= dpti_fifo_pre_tdata_count + 1;
      end
      dpti_fifo_pre_state <= next_dpti_fifo_pre_state;
      if(save_pre_arb_idx) begin
        cur_pre_arb_idx <= dpti_fifo_pre_arb_idx;
        for(cur_idx=0; cur_idx < NUM_MUX_CHANNELS; cur_idx=cur_idx+1) begin
          dpti_fifo_pre_tvalids_saved[cur_idx] <= dpti_fifo_pre_tvalids[cur_idx];
          dpti_fifo_pre_tdatas_saved[cur_idx] <= dpti_fifo_pre_tdatas[cur_idx];
        end
      end 
      if(reset_pre_cur_idx) begin
        cur_pre_idx <= 0;
      end else if(incr_pre_cur_idx) begin
        cur_pre_idx <= cur_pre_idx + 1;
      end
    end
  end

  always @* begin
    next_dpti_fifo_pre_state = dpti_fifo_pre_state;
    save_pre_arb_idx = 1'b0;
    reset_pre_cur_idx = 1'b0;
    incr_pre_cur_idx = 1'b0;
    dpti_fifo_pre_tvalid = 1'b0;
    dpti_fifo_pre_treadies = 0;
    dpti_fifo_pre_tdata = 0;

    case(dpti_fifo_pre_state)
      DPTI_PRE_IDLE: begin
        save_pre_arb_idx = 1'b1;
        dpti_fifo_pre_treadies = {{NUM_MUX_CHANNELS}{dpti_fifo_pre_tready}};
        dpti_fifo_pre_tvalid = dpti_fifo_pre_arb_valid;
        dpti_fifo_pre_tdata = dpti_fifo_pre_tdatas[dpti_fifo_pre_arb_idx];
        if(dpti_fifo_pre_arb_valid & dpti_fifo_pre_tready) begin
          next_dpti_fifo_pre_state = DPTI_PRE_WAIT_ON_PATH;
        end
      end

      DPTI_PRE_WAIT_ON_PATH: begin
        dpti_fifo_pre_treadies = ({{{NUM_MUX_CHANNELS-1}{1'b0}},dpti_fifo_pre_tready} << cur_pre_arb_idx);
        dpti_fifo_pre_tvalid = dpti_fifo_pre_tvalids[cur_pre_arb_idx];
        dpti_fifo_pre_tdata = dpti_fifo_pre_tdatas[cur_pre_arb_idx];
        if(~dpti_fifo_pre_tvalid) begin
          reset_pre_cur_idx = 1'b1;
          next_dpti_fifo_pre_state = DPTI_PRE_FLUSH_SAVED_DATA;
        end
      end

      DPTI_PRE_FLUSH_SAVED_DATA: begin
        incr_pre_cur_idx = 1'b1;
        dpti_fifo_pre_tvalid = (dpti_fifo_pre_tvalids_saved[cur_pre_idx] == 1'b1) && (cur_pre_idx != cur_pre_arb_idx);
        dpti_fifo_pre_tdata = dpti_fifo_pre_tdatas_saved[cur_pre_idx];
        if(cur_pre_idx == NUM_MUX_CHANNELS-1) begin
          next_dpti_fifo_pre_state = DPTI_PRE_IDLE;
        end
      end
    endcase
  end

  /////////////////////////////////////////////////////////////
  //
  // ADI Stuff...
  //
  ////////////////////////////////////////////////////////////
  wire              up_clk;
  wire              up_rstn;
  wire    [ 4:0]    up_waddr;
  wire    [31:0]    up_wdata;
  wire              up_wack;
  wire              up_wreq;
  wire              up_rack;
  wire    [31:0]    up_rdata;
  wire              up_rreq;
  wire    [ 4:0]    up_raddr;

  up_axi #(
    .AXI_ADDRESS_WIDTH(7),
    .ADDRESS_WIDTH(5)
  ) i_up_axi (
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq),
    .up_waddr (up_waddr),
    .up_wdata (up_wdata),
    .up_wack (up_wack),
    .up_rreq (up_rreq),
    .up_raddr (up_raddr),
    .up_rdata (up_rdata),
    .up_rack (up_rack));

  wire [3:0] setting_primary_fft_len_decim_log2;
  wire [PRIMARY_FFT_MAX_LEN_LOG2:0] setting_reorder_factor_mask;
  wire [PRIMARY_FFT_MAX_LEN_DECIM_LOG2:0] setting_primary_fft_len_decim_mask;
  wire [PRIMARY_FFT_MAX_LEN_LOG2_LOG2-1:0] setting_primary_fft_len_log2;
  wire setting_primary_fft_len_log2_changed;
  wire [PRIMARY_FFT_MAX_LEN_LOG2:0] setting_reorder_factor_log2 = setting_primary_fft_len_log2-setting_primary_fft_len_decim_log2;

  reg [2:0] ce_rst_reg;
  assign ce_rst = ce_rst_reg[2];
  always @(posedge ce_clk) begin
    ce_rst_reg <= {ce_rst_reg[1:0], ce_rst_in | soft_reset};
  end

  reg [2:0] dram_rst_reg;
  wire dram_rst = dram_rst_reg[2];
  always @(posedge m_axi_aclk) begin
    dram_rst_reg <= {dram_rst_reg[1:0], (~m_axi_aresetn) | soft_reset};
  end

  reg [2:0] dram2_rst_reg;
  wire dram2_rst = dram2_rst_reg[2];
  always @(posedge m_axi2_aclk) begin
    dram2_rst_reg <= {dram2_rst_reg[1:0], (~m_axi2_aresetn) | soft_reset};
  end

  /////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  reg  [63:0] rb_data;
  wire [7:0]  rb_addr;

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0]    str_src_tdata[NUM_OUTPUTS-1:0];
  wire [NUM_OUTPUTS-1:0]     str_src_tlast, str_src_tvalid, str_src_tready;

  //TODO: Probably need to feed these data streams somewhere...
  assign str_src_tready = {{NUM_OUTPUTS}{1'b1}};

  //TODO: Should this be assigned to anything??
  wire [15:0]    src_sid[NUM_OUTPUTS-1:0], next_dst_sid[NUM_OUTPUTS-1:0];

  wire [63:0]    sample_tdata;
  (* dont_touch="true",mark_debug="true"*) wire           sample_tlast, sample_tvalid, sample_tready, sample_tready_fft, sample_tready_iq;
  assign sample_tready = sample_tready_fft & sample_tready_iq;

  reg adc_last;
  reg adc_valid;
  reg adc_ping_pong;
  wire enable_sync;
  reg [15:0] adc_i_in_latched;
  reg [15:0] adc_q_in_latched;
  reg [15:0] adc_i_in_latched_last;
  reg [15:0] adc_q_in_latched_last;
  reg [PRIMARY_FFT_MAX_LEN_LOG2-1:0] input_sample_counter;

  wire [PRIMARY_FFT_MAX_LEN_LOG2:0] setting_primary_fft_len;
  reg [PRIMARY_FFT_MAX_LEN_LOG2:0] setting_primary_fft_len_sync[1:0];
  always @(posedge adc_clk) begin
    if(ce_rst) begin
      setting_primary_fft_len_sync[0] <= 0;
      setting_primary_fft_len_sync[1] <= 0;
      input_sample_counter <= 0;
      adc_valid <= 1'b0;
      adc_last <= 1'b0;
      adc_i_in_latched <= 0;
      adc_q_in_latched <= 0;
      adc_i_in_latched_last <= 0;
      adc_q_in_latched_last <= 0;
      adc_ping_pong <= 1'b0;
    end else begin
      setting_primary_fft_len_sync[0] <= setting_primary_fft_len;
      setting_primary_fft_len_sync[1] <= setting_primary_fft_len_sync[0];
      if(~enable_sync) begin
        adc_valid <= 1'b0;
      end else begin
        if(adc_enable_i0 & adc_valid_i0 & enable_sync) begin
          if(input_sample_counter == setting_primary_fft_len_sync[1]-1)
            input_sample_counter <= 0;
          else
            input_sample_counter <= input_sample_counter + 1;
          adc_i_in_latched <= adc_data_i0;
          adc_i_in_latched_last <= adc_i_in_latched;
          adc_ping_pong <= ~adc_ping_pong;
          adc_valid <= (record_en) ? adc_ping_pong : 1'b1;
          adc_last <= (input_sample_counter == setting_primary_fft_len_sync[1]-1);
        end else begin
          adc_valid <= 1'b0;
        end

        if(adc_enable_q0 & adc_valid_q0 & enable_sync) begin
          adc_q_in_latched <= adc_data_q0;
          adc_q_in_latched_last <= adc_q_in_latched;
        end
      end
    end
  end

  wire sample_fifo_empty;
  wire [6:0] fifo_unused;
  assign sample_tvalid = ~sample_fifo_empty;
  fifo_short_2clk input_samples_fifo (
    .rst(ce_rst),
    .wr_clk(adc_clk),
    .din({7'd0,adc_last,adc_i_in_latched_last,adc_q_in_latched_last,adc_i_in_latched,adc_q_in_latched}),
    .wr_en(adc_valid),
    .full(),
    .wr_data_count(),
    .rd_clk(ce_clk),
    .dout({fifo_unused,sample_tlast,sample_tdata}),
    .rd_en(sample_tready | (sample_tready_iq & record_en)),
    .empty(sample_fifo_empty),
    .rd_data_count()
  );

  wire [31:0]    out_tdata;
  wire           out_tlast, out_tvalid, out_tready, out_tkeep;
  assign out_tready = 1'b1;

  wire [15:0] turnaround_ticks;
  wire [15:0] tick_rate;
  reg [63:0] cur_time;

  always @(posedge ce_clk) begin
    if(ce_rst) begin
      cur_time <= 0;
    end else begin
      cur_time <= cur_time + 1;
    end
  end

  //A FIFO is used to store IQ samples which are currently being processed by FFT block
  //TODO: What size is best?!
  wire [31:0] sample_buff_tdata;
  wire        sample_buff_tvalid;
  wire        sample_buff_tready;
  wire        sample_buff_tlast;
  wire [63:0] replay_sample_buff_tdata;
  wire        replay_sample_buff_tvalid;
  wire        replay_sample_buff_tready;
  wire        replay_sample_buff_tlast;
  axi_fifo #(
    .WIDTH(32+1), 
    .SIZE(12)) 
  fft_samples_fifo (
    .clk(ce_clk),
    .reset(ce_rst),
    .clear(clear),
    .i_tdata({sample_tlast,sample_tdata}),
    .i_tvalid(sample_tvalid & sample_tready & ~record_en),
    .i_tready(),
    .o_tdata({sample_buff_tlast,sample_buff_tdata}),
    .o_tvalid(sample_buff_tvalid),
    .o_tready(sample_buff_tready));

  //FFT Block runs in parallel to IQ data path
  wire [63:0] fft_data_o_tdata;
  wire        fft_data_o_tlast;
  wire        fft_data_o_tvalid;
  wire        fft_data_o_tready;
  wire [15:0] fft_data_o_tuser;

  wire [31:0] fft_mag_o_tdata;
  wire        fft_mag_o_tlast;
  wire        fft_mag_o_tvalid;
  wire        fft_mag_o_tready;

  wire [31:0] fft_buff_o_tdata;
  wire        fft_buff_o_tlast;
  wire        fft_buff_o_tvalid;
  wire        fft_buff_o_tready;

  //FFT configuration parameters
  wire [7:0] primary_fft_size_log2   = setting_primary_fft_len_log2;  // Set FFT size
  wire primary_fft_direction         = 0;//TODO: Doc says 1=forw// Set FFT direction to forward (i.e. DFT[x(n)] => X(k))
  wire [11:0] primary_fft_scale      = 12'b011010101010;        // Conservative scaling of 1/N
  // Padding of the control word depends on the FFT options enabled
  wire [31:0] primary_fft_ctrl_word  = {11'd0, primary_fft_scale, primary_fft_direction, primary_fft_size_log2};
  (* dont_touch="true",mark_debug="true"*) reg primary_fft_config_tvalid;
  (* dont_touch="true",mark_debug="true"*) wire primary_fft_config_tready;

  reg rst_fft;
  always @(posedge ce_clk) begin
    if(rst_fft) begin
        primary_fft_config_tvalid <= 1'b1;
    end else begin
	//Upon reset, we need to re-configure the FFT block.  This consists of
	// asserting the config_tvalid flag until the configuration has been
	// loaded
        if(setting_primary_fft_len_log2_changed) begin
            primary_fft_config_tvalid <= 1'b1;
        end else if(primary_fft_config_tready) begin
            primary_fft_config_tvalid <= 0;
        end
    end
  end

  reg rst_last;
  wire rst_fft_pre = (ce_rst | clear | setting_primary_fft_len_log2_changed);
  always @(posedge ce_clk) begin
      rst_last <= rst_fft_pre;
      rst_fft <= rst_fft_pre | rst_last;
  end

  axi_fft_un inst_axi_fft (
    .aclk(ce_clk), .aresetn(~rst_fft),
    .s_axis_data_tvalid(sample_tvalid & sample_tready & ~record_en),
    .s_axis_data_tready(sample_tready_fft),
    .s_axis_data_tlast(sample_tlast),
    .s_axis_data_tdata(sample_tdata[31:0]),
    .m_axis_data_tvalid(fft_data_o_tvalid),
    .m_axis_data_tready(fft_data_o_tready),
    .m_axis_data_tlast(fft_data_o_tlast),
    .m_axis_data_tdata(fft_data_o_tdata),
    .m_axis_data_tuser(fft_data_o_tuser), // FFT index
    .s_axis_config_tdata(primary_fft_ctrl_word[15:0]),
    .s_axis_config_tvalid(primary_fft_config_tvalid),
    .s_axis_config_tready(primary_fft_config_tready),
    // Unused
    .event_frame_started(),
    .event_tlast_unexpected(),
    .event_tlast_missing(),
    .event_status_channel_halt(),
    .event_data_in_channel_halt(),
    .event_data_out_channel_halt());

  //Resize FFT packets by asserting tlast multiple times per packet
  reg [PRIMARY_FFT_MAX_LEN_LOG2-1:0] fft_decim_counter;
  reg fft_data_o_tlast_decim;
  always @(posedge ce_clk) begin
    if(ce_rst | clear) begin
      fft_decim_counter <= 0;
      fft_data_o_tlast_decim <= 1'b0;
    end else begin
      if(fft_data_o_tready & fft_data_o_tvalid) begin
        fft_decim_counter <= fft_decim_counter + 1;
        if(fft_decim_counter == (setting_primary_fft_len_decim_mask & {{{PRIMARY_FFT_MAX_LEN_LOG2-1}{1'b1}},1'b0})) begin
          fft_decim_counter <= 0;
          fft_data_o_tlast_decim <= 1'b1;
        end else begin
          fft_data_o_tlast_decim <= 1'b0;
        end
      end
    end
  end

  complex_to_mag_approx #(
    .SAMP_WIDTH(32)
  ) inst_complex_to_mag (
    .clk(ce_clk), .reset(ce_rst), .clear(clear),
    .i_tvalid(fft_data_o_tvalid),
    .i_tlast(fft_data_o_tlast),
    .i_tready(fft_data_o_tready),
    .i_tdata(fft_data_o_tdata),
    .o_tvalid(fft_mag_o_tvalid),
    .o_tlast(fft_mag_o_tlast),
    .o_tready(fft_mag_o_tready),
    .o_tdata(fft_mag_o_tdata));

  wire [PRIMARY_FFT_MAX_LEN_LOG2-1:0] fft_norm_idx_next;
  wire [FFT_SHIFT_WIDTH-2:0] fft_norm_shift;
  wire [FFT_SHIFT_WIDTH-1:0] fft_norm_sq_shift = (fft_norm_shift < 15) ? 0 : ((fft_norm_shift-14) << 1);
  wire fft_norm_sq_shift_valid = (fft_buff_o_tvalid & fft_buff_o_tready);
  reg [PRIMARY_FFT_MAX_LEN_DECIM_LOG2-1:0] fft_norm_sq_shift_idx;

  //CFO/SFO search requires an explicit trigger signal
  reg [PRIMARY_FFT_MAX_LEN_LOG2+SECONDARY_FFT_MAX_LEN_LOG2-1:0] fft_buff_write_ctr;
  reg last_fft_buff_sample;
  wire trigger_cfo_sfo_search;
  wire [PRIMARY_FFT_MAX_LEN_DECIM_LOG2+SECONDARY_FFT_MAX_LEN_LOG2:0] setting_hist_len_mask;
  always @(posedge ce_clk) begin
    if(ce_rst | clear) begin
      fft_buff_write_ctr <= 0;
      last_fft_buff_sample <= 1'b0;
    end else begin
      if(fft_mag_o_tvalid & fft_mag_o_tready) begin
        fft_buff_write_ctr <= fft_buff_write_ctr + 1;
        if(fft_buff_write_ctr == setting_hist_len_mask) begin
          last_fft_buff_sample <= 1'b1;
        end else begin
          last_fft_buff_sample <= 1'b0;
        end
      end
    end
  end

  wire [PRIMARY_FFT_MAX_LEN_LOG2:0] setting_primary_fft_len_mask;
  wire [SECONDARY_FFT_MAX_LEN_LOG2:0] setting_secondary_fft_len_mask;
  wire [SECONDARY_FFT_MAX_LEN_LOG2_LOG2-1:0] setting_secondary_fft_len_log2;
  mrr_sfo_fft_normalization
  inst_fft_normalization (
    .clk(ce_clk),
    .rst(ce_rst | clear),
    .clear(clear),
    .setting_primary_fft_len_log2(setting_primary_fft_len_log2),
    .setting_primary_fft_len_mask(setting_primary_fft_len_mask),
    .setting_secondary_fft_len_mask(setting_secondary_fft_len_mask),
    .data_in_mag(fft_mag_o_tdata),
    .data_in_valid(fft_mag_o_tvalid & fft_mag_o_tready),
    .data_in_last(last_fft_buff_sample),
    .data_out_idx_next(fft_norm_idx_next),
    .data_out_shift(fft_norm_shift)
  );

  /////////////////////////////////////////////////////////////////////////////
  //
  // DRAM FFT Sample Buffer          
  //
  /////////////////////////////////////////////////////////////////////////////

  wire fft_sync_req;
  wire fft_sync_latest;
  wire fft_sync_ack;
  wire [63:0] dram_fft_buffer_debug, dram_fft_buffer_debug2;
  localparam i = 0;
  localparam SR_USER_REG_BASE = 160;
  mrr_dram_fft_buffer #(
        .DEFAULT_BASE(DEFAULT_FIFO_BASE[(30*(i+1))-1:30*i]),
        .DEFAULT_MASK(~(DEFAULT_FIFO_SIZE[(30*(i+1))-1:30*i])),
        .DEFAULT_TIMEOUT(DEFAULT_BURST_TIMEOUT[(12*(i+1))-1:12*i]),
        .SR_BASE(SR_USER_REG_BASE),
        .EXT_BIST(EXTENDED_DRAM_BIST)
  ) inst_fft_buffer (
        //
        // Clocks and reset
        //
        .bus_clk(ce_clk), .bus_reset(ce_rst | clear),
        .dram_clk(m_axi_aclk), .dram_reset(dram_rst),
        //
        // AXI Write address channel
        //
        .m_axi_awid     (m_axi_awid),
        .m_axi_awaddr   (m_axi_awaddr),
        .m_axi_awlen    (m_axi_awlen),
        .m_axi_awsize   (m_axi_awsize),
        .m_axi_awburst  (m_axi_awburst),
        .m_axi_awlock   (m_axi_awlock),
        .m_axi_awcache  (m_axi_awcache),
        .m_axi_awprot   (m_axi_awprot),
        .m_axi_awqos    (m_axi_awqos),
        .m_axi_awregion (m_axi_awregion),
        .m_axi_awuser   (m_axi_awuser),
        .m_axi_awvalid  (m_axi_awvalid),
        .m_axi_awready  (m_axi_awready),
        //
        // AXI Write data channel.
        //
        .m_axi_wdata    (m_axi_wdata),
        .m_axi_wstrb    (m_axi_wstrb),
        .m_axi_wlast    (m_axi_wlast),
        .m_axi_wuser    (m_axi_wuser),
        .m_axi_wvalid   (m_axi_wvalid),
        .m_axi_wready   (m_axi_wready),
        //
        // AXI Write response channel signals
        //
        .m_axi_bid      (m_axi_bid),
        .m_axi_bresp    (m_axi_bresp),
        .m_axi_buser    (m_axi_buser),
        .m_axi_bvalid   (m_axi_bvalid),
        .m_axi_bready   (m_axi_bready),
        //
        // AXI Read address channel
        //
        .m_axi_arid     (m_axi_arid),
        .m_axi_araddr   (m_axi_araddr),
        .m_axi_arlen    (m_axi_arlen),
        .m_axi_arsize   (m_axi_arsize),
        .m_axi_arburst  (m_axi_arburst),
        .m_axi_arlock   (m_axi_arlock),
        .m_axi_arcache  (m_axi_arcache),
        .m_axi_arprot   (m_axi_arprot),
        .m_axi_arqos    (m_axi_arqos),
        .m_axi_arregion (m_axi_arregion),
        .m_axi_aruser   (m_axi_aruser),
        .m_axi_arvalid  (m_axi_arvalid),
        .m_axi_arready  (m_axi_arready),
        //
        // AXI Read data channel
        //
        .m_axi_rid      (m_axi_rid),
        .m_axi_rdata    (m_axi_rdata),
        .m_axi_rresp    (m_axi_rresp),
        .m_axi_rlast    (m_axi_rlast),
        .m_axi_ruser    (m_axi_ruser),
        .m_axi_rvalid   (m_axi_rvalid),
        .m_axi_rready   (m_axi_rready),
        //
        // CHDR friendly AXI stream input
        //
        .i_tdata        ({32'd0,fft_mag_o_tdata}),
        .i_tlast        (fft_mag_o_tlast),
        .i_tvalid       (fft_mag_o_tvalid),
        .i_tready       (fft_mag_o_tready),
        //
        // CHDR friendly AXI Stream output
        //
        .o_tdata        (fft_buff_o_tdata),
        .o_tlast        (fft_buff_o_tlast),
        .o_tvalid       (fft_buff_o_tvalid),
        .o_tready       (fft_buff_o_tready),
        //
        // Settings
        //
        .set_stb        (set_stb),//[i]),
        .set_addr       (set_addr),//[(8*(i+1))-1:8*i]),
        .set_data       (set_data),//[(32*(i+1))-1:32*i]),
        .rb_data        (),//[(64*i+32)-1:64*i]),
        //
        // Backtracking: Disabled for FFT output
        //
        .sync_req(fft_sync_req),
        .sync_latest(fft_sync_latest),
        .sync_ack(fft_sync_ack),
        .flush_req(1'b0),
        .flush_done(),
        .trigger_new_superframe_sync(trigger_cfo_sfo_search),
        //
        // Frame size settings
        //
        .setting_input_frame_size_log2(setting_primary_fft_len_decim_log2),
        .setting_input_frame_size_mask({{{PRIMARY_FFT_MAX_LEN_LOG2-PRIMARY_FFT_MAX_LEN_DECIM_LOG2-1}{1'b0}},setting_primary_fft_len_decim_mask}),
        .setting_reorder_factor_log2(setting_reorder_factor_log2),
        .setting_reorder_factor_mask(setting_reorder_factor_mask),
        .setting_mod_sync_frames_log2(setting_secondary_fft_len_log2),
        .setting_mod_sync_frames_mask(setting_secondary_fft_len_mask),

        .force_full_size(1'b0),

        //
        // Debug
        //
        .debug          (dram_fft_buffer_debug),
        .debug2         (dram_fft_buffer_debug2)
  );

  wire [15:0] fft_buff_o_tdata_scaled = (fft_norm_shift < 15) ? fft_buff_o_tdata : (fft_buff_o_tdata >> (fft_norm_shift - 14));
  reg [PRIMARY_FFT_MAX_LEN_LOG2+SECONDARY_FFT_MAX_LEN_LOG2-1:0] fft_readback_idx;
  wire [PRIMARY_FFT_MAX_LEN_LOG2+SECONDARY_FFT_MAX_LEN_LOG2-1:0] fft_readback_idx_next = fft_readback_idx + 1;
  assign fft_norm_idx_next = ((fft_readback_idx_next >> setting_secondary_fft_len_log2) & setting_primary_fft_len_mask & ~setting_primary_fft_len_decim_mask) | (fft_readback_idx_next & setting_primary_fft_len_decim_mask);
  always @(posedge ce_clk) begin
    if(ce_rst | clear) begin
      fft_readback_idx <= 0;
    end else begin
      if(fft_sync_req) begin
        fft_readback_idx <= 0;
      end else if(fft_buff_o_tvalid & fft_buff_o_tready) begin
        fft_readback_idx <= fft_readback_idx + 1;
      end
    end
  end

  //Rest of logic assumes magsq values
  wire fft_buff_magsq_tlast;
  wire fft_buff_magsq_tvalid;
  wire fft_buff_magsq_tready;
  wire [31:0] fft_buff_magsq_tdata;
  complex_to_magsq magsq_inst (
      .clk(ce_clk),
      .reset(ce_rst | fft_sync_req),
      .clear(clear),
      .i_tdata({16'd0,fft_buff_o_tdata_scaled}),
      .i_tlast(fft_buff_o_tlast),
      .i_tvalid(fft_buff_o_tvalid),
      .i_tready(fft_buff_o_tready),
      .o_tdata(fft_buff_magsq_tdata),
      .o_tlast(fft_buff_magsq_tlast),
      .o_tvalid(fft_buff_magsq_tvalid),
      .o_tready(fft_buff_magsq_tready)
  );

  always @(posedge ce_clk) begin
    if(ce_rst | clear) begin
      fft_norm_sq_shift_idx <= 0;
    end else begin
      if(fft_buff_o_tvalid & fft_buff_o_tready) begin
        if(fft_buff_o_tlast) begin
          fft_norm_sq_shift_idx <= 0;
        end else begin
          fft_norm_sq_shift_idx <= fft_norm_sq_shift_idx + 1;
        end
      end
    end
  end

  /////////////////////////////////////////////////////////////////////////////
  //
  // DRAM IQ Sample Buffer          
  //
  /////////////////////////////////////////////////////////////////////////////

  wire iq_sync_req;
  wire iq_sync_latest;
  wire iq_sync_ack;
  wire iq_flush_req;
  wire iq_flush_done;
  wire dram_force_full_size;
  wire [63:0] dram_iq_buffer_debug, dram_iq_buffer_debug2;
  localparam j = 1;
  mrr_dram_fft_buffer #(
        .DEFAULT_BASE(DEFAULT_FIFO_BASE[(30*(j+1))-1:30*j]),
        .DEFAULT_MASK(~(DEFAULT_FIFO_SIZE[(30*(j+1))-1:30*j])),
        .DEFAULT_TIMEOUT(DEFAULT_BURST_TIMEOUT[(12*(j+1))-1:12*j]),
        .SR_BASE(SR_USER_REG_BASE),
        .EXT_BIST(EXTENDED_DRAM_BIST)
  ) inst_iq_buffer (
        //
        // Clocks and reset
        //
        .bus_clk(ce_clk), .bus_reset(ce_rst | clear),
        .dram_clk(m_axi2_aclk), .dram_reset(dram2_rst),
        //
        // AXI Write address channel
        //
        .m_axi_awid     (m_axi2_awid),
        .m_axi_awaddr   (m_axi2_awaddr),
        .m_axi_awlen    (m_axi2_awlen),
        .m_axi_awsize   (m_axi2_awsize),
        .m_axi_awburst  (m_axi2_awburst),
        .m_axi_awlock   (m_axi2_awlock),
        .m_axi_awcache  (m_axi2_awcache),
        .m_axi_awprot   (m_axi2_awprot),
        .m_axi_awqos    (m_axi2_awqos),
        .m_axi_awregion (m_axi2_awregion),
        .m_axi_awuser   (m_axi2_awuser),
        .m_axi_awvalid  (m_axi2_awvalid),
        .m_axi_awready  (m_axi2_awready),
        //
        // AXI Write data channel.
        //
        .m_axi_wdata    (m_axi2_wdata),
        .m_axi_wstrb    (m_axi2_wstrb),
        .m_axi_wlast    (m_axi2_wlast),
        .m_axi_wuser    (m_axi2_wuser),
        .m_axi_wvalid   (m_axi2_wvalid),
        .m_axi_wready   (m_axi2_wready),
        //
        // AXI Write response channel signals
        //
        .m_axi_bid      (m_axi2_bid),
        .m_axi_bresp    (m_axi2_bresp),
        .m_axi_buser    (m_axi2_buser),
        .m_axi_bvalid   (m_axi2_bvalid),
        .m_axi_bready   (m_axi2_bready),
        //
        // AXI Read address channel
        //
        .m_axi_arid     (m_axi2_arid),
        .m_axi_araddr   (m_axi2_araddr),
        .m_axi_arlen    (m_axi2_arlen),
        .m_axi_arsize   (m_axi2_arsize),
        .m_axi_arburst  (m_axi2_arburst),
        .m_axi_arlock   (m_axi2_arlock),
        .m_axi_arcache  (m_axi2_arcache),
        .m_axi_arprot   (m_axi2_arprot),
        .m_axi_arqos    (m_axi2_arqos),
        .m_axi_arregion (m_axi2_arregion),
        .m_axi_aruser   (m_axi2_aruser),
        .m_axi_arvalid  (m_axi2_arvalid),
        .m_axi_arready  (m_axi2_arready),
        //
        // AXI Read data channel
        //
        .m_axi_rid      (m_axi2_rid),
        .m_axi_rdata    (m_axi2_rdata),
        .m_axi_rresp    (m_axi2_rresp),
        .m_axi_rlast    (m_axi2_rlast),
        .m_axi_ruser    (m_axi2_ruser),
        .m_axi_rvalid   (m_axi2_rvalid),
        .m_axi_rready   (m_axi2_rready),
        //
        // CHDR friendly AXI stream input
        //
        .i_tdata        (sample_tdata),
        .i_tlast        (sample_tlast),
        .i_tvalid       (sample_tvalid & (sample_tready | record_en)),
        .i_tready       (sample_tready_iq),
        //
        // CHDR friendly AXI Stream output
        //
        .o_tdata        (replay_sample_buff_tdata),
        .o_tlast        (replay_sample_buff_tlast),
        .o_tvalid       (replay_sample_buff_tvalid),
        .o_tready       (replay_sample_buff_tready),
        .empty          (replay_sample_buff_empty),
        //
        // Settings
        //
        .set_stb        (set_stb),//[i]),
        .set_addr       (set_addr),//[(8*(i+1))-1:8*i]),
        .set_data       (set_data),//[(32*(i+1))-1:32*i]),
        .rb_data        (),//[(64*i+32)-1:64*i]),
        //
        // Backtracking: Required for replaying IQ samples upon header detection
        //
        .sync_req(iq_sync_req),
        .sync_latest(iq_sync_latest),
        .sync_ack(iq_sync_ack),
        .flush_req(iq_flush_req),
        .flush_done(iq_flush_done),
        //
        // Frame size settings
        //
        .setting_input_frame_size_log2(setting_primary_fft_len_log2),
        .setting_input_frame_size_mask(setting_primary_fft_len_mask),
        .setting_reorder_factor_log2(0),
        .setting_reorder_factor_mask(0),
        .setting_mod_sync_frames_log2(setting_secondary_fft_len_log2),
        .setting_mod_sync_frames_mask(setting_secondary_fft_len_mask),

        //Full size used for prompting buffering of recorded samples
        .force_full_size(dram_force_full_size),

        //
        // Debug
        //
        .debug          (dram_iq_buffer_debug),
        .debug2         (dram_iq_buffer_debug2)
  );

  reg [2:0] enable_reg;
  assign enable_sync = enable_reg[2];
  always @(posedge adc_clk) begin
    enable_reg <= {enable_reg[1:0], enable};
  end

  wire [31:0] out_decoded_tdata_post;
  wire [31:0] out_decoded_tdata;
  wire [39:0] out_decoded_tdata_post_unused;
  wire out_decoded_tempty_post;
  wire out_decoded_tlast, out_decoded_tvalid, out_decoded_tready;
  fifo_short_2clk output_samples_fifo (
    .rst(ce_rst),
    .wr_clk(ce_clk),
    .din({40'd0,out_decoded_tdata}),
    .wr_en(out_decoded_tvalid),
    .full(),
    .wr_data_count(),
    .rd_clk(adc_clk),
    .dout({out_decoded_tdata_post_unused,out_decoded_tdata_post}),
    .rd_en(1'b1),
    .empty(out_decoded_tempty_post),
    .rd_data_count()
  );

  assign out_enable_i0 = (enable_reg[2]) ? 1'b1 : adc_enable_i0;
  assign out_enable_q0 = (enable_reg[2]) ? 1'b1 : adc_enable_q0;
  assign out_valid_i0  = (enable_reg[2]) ? ~out_decoded_tempty_post : adc_valid_i0;
  assign out_valid_q0  = (enable_reg[2]) ? ~out_decoded_tempty_post : adc_valid_q0;
  assign out_data_i0   = (enable_reg[2]) ? out_decoded_tdata_post[31:16] : adc_data_i0;
  assign out_data_q0   = (enable_reg[2]) ? out_decoded_tdata_post[15:0] : adc_data_q0;

  //A separate port is used to push out decoded data
  wire pause_block;
  wire [127:0]   out_decoded_tuser = {2'd0,1'b0,1'b1,12'd0,16'd4,src_sid[1],next_dst_sid[1],64'd0};
  //chdr_framer #(.SIZE(8)) chdr_framer (
  //  .clk(ce_clk), .reset(ce_rst), .clear(clear | pause_block),
  //  .i_tdata(out_decoded_tdata), .i_tuser(out_decoded_tuser), .i_tlast(out_decoded_tlast), .i_tvalid(out_decoded_tvalid), .i_tready(out_decoded_tready),
  //  .o_tdata(str_src_tdata[1]), .o_tlast(str_src_tlast[1]), .o_tvalid(str_src_tvalid[1]), .o_tready(str_src_tready[1]));

  //Another separate port is used to push out correlator values
  wire [31:0]    out_corr_tdata;
  wire [127:0]   out_corr_tuser = {2'd0,1'b0,1'b1,12'd0,16'd4,src_sid[0],next_dst_sid[0],64'd0};
  wire           out_corr_tlast, out_corr_tvalid, out_corr_tready;
  //chdr_framer #(.SIZE(8)) chdr_framer2 (
  //  .clk(ce_clk), .reset(ce_rst), .clear(clear | pause_block),
  //  .i_tdata(out_corr_tdata), .i_tuser(out_corr_tuser), .i_tlast(out_corr_tlast), .i_tvalid(out_corr_tvalid), .i_tready(out_corr_tready),
  //  .o_tdata(str_src_tdata[0]), .o_tlast(str_src_tlast[0]), .o_tvalid(str_src_tvalid[0]), .o_tready(str_src_tready[0]));


  /////////////////////////////////////////////////////////////////////////////
  //
  // Settings and readback registers
  //
  /////////////////////////////////////////////////////////////////////////////
  localparam NUM_AXI_CONFIG_BUS = 1;
  localparam AXI_WRAPPER_BASE    = 128;
  localparam SR_NEXT_DST         = AXI_WRAPPER_BASE;
  localparam SR_AXI_CONFIG = 129; //129,130 used fo config
  //localparam SR_N = 131;
  localparam SR_THRE = 132;
  localparam SR_NUM_BITS = 133;
  localparam SR_TX_DISABLE = 137;
  localparam SR_WAIT_STEP = 138;
  localparam SR_TURN_TICKS = 139;
  localparam SR_TICK_RATE = 140;
  localparam SR_TX_WORD = 141;
  localparam SR_MAX_JITTER = 142;
  localparam SR_RECHARGE_LEN = 144;
  localparam SR_MF_NUM_ACCUM = 146;
  localparam SR_MF_ACCUM_LEN = 147;
  localparam SR_PRIMARY_FFT_MASK = 150;
  localparam SR_PAUSE_BLOCK = 151;
  localparam SR_NUM_HARMONICS = 152;
  localparam SR_SFO_INT = 153;
  localparam SR_SFO_FRAC = 154;
  localparam SR_RESAMPLE_INT = 155;
  localparam SR_RESAMPLE_FRAC = 156;
  localparam SR_PRIMARY_FFT_LEN_LOG2 = 157;
  localparam SR_PRIMARY_FFT_LEN_DECIM_LOG2 = 158;
  localparam SR_SECONDARY_FFT_LEN_LOG2 = 159;
  localparam SR_RECORD_EN = 160;
  //localparam SR_USER_REG_BASE = 160; (DDR control registers: 160-163)
  localparam SR_CORR_WAIT_LEN = 164;
  localparam SR_RECORD_LEN = 165;

  setting_reg #(
      .my_addr(SR_TURN_TICKS), .awidth(8), .width(32), .at_reset(16000))
  sr_turnaround_ticks (
      .clk(ce_clk), .rst(ce_rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data), .out(turnaround_ticks), .changed());

  wire [CORR_WIDTH-1:0] threshold;

  setting_reg #(
    .my_addr(SR_THRE), .awidth(8), .width(CORR_WIDTH), .at_reset(2500))
  sr_thre (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(threshold), .changed());

  wire [7:0] num_payload_bits;

  setting_reg #(
    .my_addr(SR_NUM_BITS), .awidth(8), .width(8), .at_reset(180))
  sr_num_bits (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(num_payload_bits), .changed());

 wire tx_disable;

  setting_reg #(
    .my_addr(SR_TX_DISABLE), .awidth(8), .width(1), .at_reset(1))
  sr_tx_disable (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(tx_disable), .changed());

 wire [15:0] wait_step;

  setting_reg #(
    .my_addr(SR_WAIT_STEP), .awidth(8), .width(16), .at_reset(4))
  sr_wait_step (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(wait_step), .changed());

  setting_reg #(
      .my_addr(SR_TICK_RATE), .awidth(8), .width(32), .at_reset(10))
  sr_tick_rate (
      .clk(ce_clk), .rst(ce_rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data), .out(tick_rate), .changed());

  wire [31:0] tx_word;
  setting_reg #(
      .my_addr(SR_TX_WORD), .awidth(8), .width(32), .at_reset(0))
  sr_tx_word (
      .clk(ce_clk), .rst(ce_rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data), .out(tx_word), .changed());

  wire [7:0] max_jitter;
  setting_reg #(
      .my_addr(SR_MAX_JITTER), .awidth(8), .width(8), .at_reset(4))
  sr_max_jitter (
      .clk(ce_clk), .rst(ce_rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data), .out(max_jitter), .changed());

  wire [14:0] recharge_len;
  setting_reg #(
      .my_addr(SR_RECHARGE_LEN), .awidth(8), .width(15), .at_reset(6))
  sr_recharge_len (
      .clk(ce_clk), .rst(ce_rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data), .out(recharge_len), .changed());

  wire [3:0] mf_num_accum;
  wire mf_num_accum_changed;
  setting_reg #(
      .my_addr(SR_MF_NUM_ACCUM), .awidth(8), .width(4), .at_reset(10))
  sr_mf_num_accum (
      .clk(ce_clk), .rst(ce_rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data), .out(mf_num_accum), .changed(mf_num_accum_changed));

  wire [7:0] mf_accum_len;
  wire mf_accum_len_changed;
  setting_reg #(
      .my_addr(SR_MF_ACCUM_LEN), .awidth(8), .width(8), .at_reset(6))
  sr_mf_accum_len (
      .clk(ce_clk), .rst(ce_rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data), .out(mf_accum_len), .changed(mf_accum_len_changed));

  wire mf_settings_changed = mf_num_accum_changed | mf_accum_len_changed;

  wire [31:0] primary_fft_mask_temp;
  wire primary_fft_mask_shift;
  setting_reg #(
      .my_addr(SR_PRIMARY_FFT_MASK), .awidth(8), .width(32), .at_reset(32'hFFFFFFFF))
  sr_pfm (
      .clk(ce_clk), .rst(ce_rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data), .out(primary_fft_mask_temp), .changed(primary_fft_mask_shift));


  setting_reg #(
    .my_addr(SR_PAUSE_BLOCK), .awidth(8), .width(1), .at_reset(0))
  sr_pause_block (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(pause_block), .changed());

  wire [NUM_HARMONICS_LOG2-1:0] setting_num_harmonics;
  setting_reg #(
      .my_addr(SR_NUM_HARMONICS), .awidth(8), .width(NUM_HARMONICS), .at_reset(7))
  sr_num_harmonics (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(setting_num_harmonics), .changed());

  wire [SFO_INT_WIDTH-1:0] setting_sfo_int_temp;
  wire setting_sfo_int_temp_changed;
  setting_reg #(
      .my_addr(SR_SFO_INT), .awidth(8), .width(SFO_INT_WIDTH))
  sr_sfo_int (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(setting_sfo_int_temp), .changed(setting_sfo_int_temp_changed));

  wire [SFO_FRAC_WIDTH-1:0] setting_sfo_frac_temp;
  wire setting_sfo_frac_temp_changed;
  setting_reg #(
      .my_addr(SR_SFO_FRAC), .awidth(8), .width(SFO_FRAC_WIDTH))
  sr_sfo_frac (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(setting_sfo_frac_temp), .changed(setting_sfo_frac_temp_changed));

  wire [RESAMPLE_INT_WIDTH-1:0] setting_resample_int_temp;
  wire setting_resample_int_temp_changed;
  setting_reg #(
      .my_addr(SR_RESAMPLE_INT), .awidth(8), .width(RESAMPLE_INT_WIDTH))
  sr_resample_int (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(setting_resample_int_temp), .changed(setting_resample_int_temp_changed));

  wire [RESAMPLE_FRAC_WIDTH-1:0] setting_resample_frac_temp;
  wire setting_resample_frac_temp_changed;
  setting_reg #(
      .my_addr(SR_RESAMPLE_FRAC), .awidth(8), .width(RESAMPLE_FRAC_WIDTH))
  sr_resample_frac (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(setting_resample_frac_temp), .changed(setting_resample_frac_temp_changed));

  mrr_log2_expand prim_len_expand (
    .clk(ce_clk),
    .num_log2_in(setting_primary_fft_len_log2),
    .num_out(setting_primary_fft_len),
    .mask_out(setting_primary_fft_len_mask)
  );
  setting_reg #(
      .my_addr(SR_PRIMARY_FFT_LEN_LOG2), .awidth(8), .width(4), .at_reset(PRIMARY_FFT_LEN_LOG2))
  sr_primary_fft_len (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(setting_primary_fft_len_log2), .changed(setting_primary_fft_len_log2_changed));

  wire [PRIMARY_FFT_MAX_LEN_DECIM_LOG2:0] setting_primary_fft_len_decim;
  mrr_log2_expand prim_len_decim_expand (
    .clk(ce_clk),
    .num_log2_in(setting_primary_fft_len_decim_log2),
    .num_out(setting_primary_fft_len_decim),
    .mask_out(setting_primary_fft_len_decim_mask)
  );
  mrr_log2_expand reorder_factor_expand (
    .clk(ce_clk),
    .num_log2_in(setting_reorder_factor_log2),
    .num_out(),
    .mask_out(setting_reorder_factor_mask)
  );
  setting_reg #(
      .my_addr(SR_PRIMARY_FFT_LEN_DECIM_LOG2), .awidth(8), .width(4), .at_reset(PRIMARY_FFT_LEN_DECIM_LOG2))
  sr_primary_fft_len_decim (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(setting_primary_fft_len_decim_log2), .changed());

  wire [SECONDARY_FFT_MAX_LEN_LOG2:0] setting_secondary_fft_len;
  wire setting_secondary_fft_len_log2_changed;
  mrr_log2_expand secondary_len_expand (
    .clk(ce_clk),
    .num_log2_in(setting_secondary_fft_len_log2),
    .num_out(setting_secondary_fft_len),
    .mask_out(setting_secondary_fft_len_mask)
  );
  setting_reg #(
      .my_addr(SR_SECONDARY_FFT_LEN_LOG2), .awidth(8), .width(SECONDARY_FFT_MAX_LEN_LOG2_LOG2), .at_reset(SECONDARY_FFT_LEN_LOG2))
  sr_secondary_fft_len (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(setting_secondary_fft_len_log2), .changed(setting_secondary_fft_len_log2_changed));

  assign dram_force_full_size = record_en;
  setting_reg #(
      .my_addr(SR_RECORD_EN), .awidth(8), .width(1), .at_reset(1'b0))
  sr_record_en (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(record_en), .changed());

  wire [PRIMARY_FFT_MAX_LEN_DECIM_LOG2+SECONDARY_FFT_MAX_LEN_LOG2:0] setting_hist_len;
  mrr_log2_expand hist_len_expand (
    .clk(ce_clk),
    .num_log2_in(setting_primary_fft_len_log2+setting_secondary_fft_len_log2),
    .num_out(setting_hist_len),
    .mask_out(setting_hist_len_mask)
  );

  wire [CORR_WAIT_LEN_LOG2-1:0] corr_wait_len;
  setting_reg #(
      .my_addr(SR_CORR_WAIT_LEN), .awidth(8), .width(CORR_WAIT_LEN_LOG2), .at_reset(8))
  sr_corr_wait_len (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(corr_wait_len), .changed());

  wire [31:0] record_len;
  setting_reg #(
      .my_addr(SR_RECORD_LEN), .awidth(8), .width(32), .at_reset(8))
  sr_record_len (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(record_len), .changed());


  //Shift register in all sfo_frac and sfo_int values
  reg [SFO_INT_WIDTH*NUM_CORRELATORS-1:0] setting_sfo_int;
  reg [SFO_FRAC_WIDTH*NUM_CORRELATORS-1:0] setting_sfo_frac;
  reg [RESAMPLE_INT_WIDTH*NUM_CORRELATORS-1:0] setting_resample_int;
  reg [RESAMPLE_FRAC_WIDTH*NUM_CORRELATORS-1:0] setting_resample_frac;
  always @(posedge ce_clk) begin
    if(ce_rst) begin
      setting_sfo_int <= SFO_INTS;
      setting_sfo_frac <= SFO_FRACS;
      setting_resample_int <= N1S;
      setting_resample_frac <= N2S;
    end else begin
      if(setting_sfo_int_temp_changed) begin
        setting_sfo_int <= {setting_sfo_int[SFO_INT_WIDTH*(NUM_CORRELATORS-1)-1:0], setting_sfo_int_temp};
      end
      if(setting_sfo_frac_temp_changed) begin
        setting_sfo_frac <= {setting_sfo_frac[SFO_FRAC_WIDTH*(NUM_CORRELATORS-1)-1:0], setting_sfo_frac_temp};
      end
      if(setting_resample_int_temp_changed) begin
        setting_resample_int <= {setting_resample_int[RESAMPLE_INT_WIDTH*(NUM_CORRELATORS-1)-1:0], setting_resample_int_temp};
      end
      if(setting_resample_frac_temp_changed) begin
        setting_resample_frac <= {setting_resample_frac[RESAMPLE_FRAC_WIDTH*(NUM_CORRELATORS-1)-1:0], setting_resample_frac_temp};
      end
    end
  end

  reg [PRIMARY_FFT_MAX_LEN-1:0] primary_fft_mask;
  always @(posedge ce_clk) begin
    if(ce_rst) begin
      primary_fft_mask <= {{PRIMARY_FFT_MAX_LEN}{1'b1}};
    end else begin
      if(primary_fft_mask_shift) begin
        primary_fft_mask <= {primary_fft_mask[PRIMARY_FFT_MAX_LEN-32-1:0],primary_fft_mask_temp};
      end
    end
  end

  // Readback registers
  wire [63:0] cfo_search_debug;
  localparam RB_READIES = 0;
  localparam RB_VALIDS = 1;
  localparam RB_DRAM = 2;
  localparam RB_DRAM2 = 3;
  localparam RB_DRAM3 = 4;
  localparam RB_DRAM4 = 5;
  localparam RB_CFO   = 6;
  localparam RB_VERSION = 7;
//(* dont_touch="true",mark_debug="true"*) 
//(* dont_touch="true",mark_debug="true"*) 
//(* dont_touch="true",mark_debug="true"*) 
  wire [20:0] local_readies = {cmdout_tready, ackin_tready, str_src_tready[1], str_src_tready[0], sample_tready_fft, sample_tready, sample_tready_iq, out_tready, sample_buff_tready, replay_sample_buff_tready, fft_data_o_tready, fft_mag_o_tready, out_decoded_tready, ackin_tready, fft_buff_o_tready};
  wire [19:0] local_valids  = {cmdout_tvalid, ackin_tvalid, str_src_tvalid[1], str_src_tvalid[0], sample_tvalid, sample_tvalid,    sample_tvalid, out_tvalid, sample_buff_tvalid, replay_sample_buff_tvalid, fft_data_o_tvalid, fft_mag_o_tvalid, out_decoded_tvalid, ackin_tvalid, fft_buff_o_tvalid};
  wire [19:0] local_lasts  = {cmdout_tlast, ackin_tlast, str_src_tlast[1], str_src_tlast[0], 1'b0, sample_tlast, out_tlast, sample_buff_tlast, fft_data_o_tlast, fft_mag_o_tlast, out_decoded_tlast, ackin_tlast, fft_buff_o_tlast};
  wire [5:0] mrr_basic_readies, mrr_basic_valid;
  always @(*) begin
    case(rb_addr)
      RB_READIES     : rb_data <= {mrr_basic_readies,local_readies};
      RB_VALIDS      : rb_data <= {mrr_basic_valid,local_valids};
      RB_DRAM        : rb_data <= dram_iq_buffer_debug;
      RB_DRAM2       : rb_data <= dram_iq_buffer_debug2;
      RB_DRAM3       : rb_data <= dram_fft_buffer_debug;
      RB_DRAM4       : rb_data <= dram_fft_buffer_debug2;
      RB_CFO         : rb_data <= cfo_search_debug;
      RB_VERSION     : rb_data <= {32'h0,4'h0,GIT_VERSION};
      default        : rb_data <= 64'h0BADC0DE0BADC0DE;
    endcase
  end

  //(* dont_touch="true",mark_debug="true"*) reg [15:0] packet_length;
  //always @(posedge ce_clk) begin
  //    if(ce_rst | clear) begin
  //        packet_length <= 0;
  //    end else begin
  //        if(sample_tlast)
  //            packet_length <= 0;
  //        else if(sample_tvalid & sample_tready_fft)
  //            packet_length <= packet_length + 1;
  //    end
  //end
  
  // Control Source Unused
  assign cmdout_tdata  = 64'd0;
  assign cmdout_tlast  = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready  = 1'b1;

  wire replay_sample_buff_tready_receiver;

   mrr_basic_header #(
    .CORR_VAL_WIDTH(CORR_WIDTH)
  )
   mrr_basic_header_inst
  (
	.clk(ce_clk),
	.rst(ce_rst | clear),
	.threshold_in(threshold),
        .setting_num_harmonics(setting_num_harmonics),
        .setting_sfo_frac(setting_sfo_frac),
        .setting_sfo_int(setting_sfo_int),
        .setting_resample_frac(setting_resample_frac),
        .setting_resample_int(setting_resample_int),
        .setting_primary_fft_len(setting_primary_fft_len),
        .setting_primary_fft_len_log2(setting_primary_fft_len_log2),
        .setting_primary_fft_len_mask(setting_primary_fft_len_mask),
        .setting_primary_fft_len_decim(setting_primary_fft_len_decim),
        .setting_primary_fft_len_decim_log2(setting_primary_fft_len_decim_log2),
        .setting_primary_fft_len_decim_mask(setting_primary_fft_len_decim_mask),
        .setting_secondary_fft_len_log2(setting_secondary_fft_len_log2),
        .setting_secondary_fft_len_mask(setting_secondary_fft_len_mask),
        .setting_secondary_fft_len_log2_changed(setting_secondary_fft_len_log2_changed),
        .tx_word(tx_word),
        .cur_time(cur_time),
        .i_tdata_i(sample_buff_tdata[31:16]),
        .i_tdata_q(sample_buff_tdata[15:0]),
        .i_tvalid(sample_buff_tvalid),
    	.i_tready(sample_buff_tready),
        .i_tlast(sample_buff_tlast),
        .i_replay_tdata_i(replay_sample_buff_tdata[31:16]),
        .i_replay_tdata_q(replay_sample_buff_tdata[15:0]),
        .i_replay_tvalid(replay_sample_buff_tvalid),
        .i_replay_empty(replay_sample_buff_empty),
    	.i_replay_tready(replay_sample_buff_tready_receiver),
        .i_replay_tlast(replay_sample_buff_tlast),
        .i_tdata_fft_shift(fft_norm_sq_shift),
        .i_tdata_fft_shift_valid(fft_norm_sq_shift_valid),
        .i_tdata_fft_shift_idx(fft_norm_sq_shift_idx),
        .i_tdata_fft_i(fft_buff_magsq_tdata[31:16]),
        .i_tvalid_fft(fft_buff_magsq_tvalid),
        .i_tready_fft(fft_buff_magsq_tready),
        .i_tlast_fft(fft_buff_magsq_tlast),
	.o_tdata(out_tdata),
   	.o_tlast(out_tlast),
    	.o_tvalid(out_tvalid),
    	.o_tready(out_tready),
        .o_tkeep(out_tkeep),
        .o_decoded_tdata(out_decoded_tdata),
        .o_decoded_tvalid(out_decoded_tvalid),
        .o_decoded_tlast(out_decoded_tlast),
        .o_decoded_tready(out_decoded_tready),
        .o_corr_tdata(out_corr_tdata),
        .o_corr_tvalid(out_corr_tvalid),
        .o_corr_tlast(out_corr_tlast),
        .o_corr_tready(out_corr_tready),
	.tx_disable(tx_disable),
        .num_payload_bits(num_payload_bits),
        .max_jitter(max_jitter),
        .recharge_len(recharge_len),
        .mf_num_accum(mf_num_accum),
        .mf_accum_len(mf_accum_len),
        .mf_settings_changed(mf_settings_changed),
	.wait_step(wait_step),
        .primary_fft_mask(primary_fft_mask),
        .trigger_cfo_sfo_search(trigger_cfo_sfo_search),
        .iq_sync_req(iq_sync_req),
        .iq_sync_latest(iq_sync_latest),
        .iq_sync_ack(iq_sync_ack),
        .iq_flush_req(iq_flush_req),
        .iq_flush_done(iq_flush_done),
        .fft_sync_req(fft_sync_req),
        .fft_sync_latest(fft_sync_latest),
        .fft_sync_ack(fft_sync_ack),
        .corr_wait_len(corr_wait_len),

        //Debug stuff
        .readies(mrr_basic_readies),
        .valids(mrr_basic_valids),
        .cfo_search_debug(cfo_search_debug)
  );

//assign debug = {adc_clk, adc_enable_i0, adc_valid_i0, adc_enable_q0, adc_valid_q0, out_enable_i0, out_valid_i0, out_enable_q0, out_valid_q0, sample_tvalid, out_tvalid, sample_buff_tvalid, replay_sample_buff_tvalid, fft_data_o_tvalid, fft_mag_o_tvalid, fft_buff_o_tvalid};

//assign debug = {PROG_D,PROG_CLKO,PROG_OEN,PROG_RDN,PROG_RXFN,PROG_SIWUN,PROG_SPIEN,PROG_TXEN,PROG_WRN};
assign debug = {cfo_search_debug[7:0], 2'd0, dpti_fifo_pre_state, dpti_fifo_pre_tvalids, dpti_fifo_pre_treadies};
//assign debug = primary_fft_mask_temp[15:0];

  wire [31:0] out_decoded_buff_tdata;
  wire out_decoded_buff_tlast;
  wire out_decoded_buff_tvalid;
  wire out_decoded_buff_tready;
  axi_fifo #(
    .WIDTH(33),
    .SIZE(8))
  decoded_stream_buffer (
    .clk(ce_clk),
    .reset(ce_rst),
    .clear(clear),
    .i_tdata({out_decoded_tlast,out_decoded_tdata}),
    .i_tvalid(out_decoded_tvalid),
    .i_tready(out_decoded_tready),
    .o_tdata({out_decoded_buff_tlast,out_decoded_buff_tdata}),
    .o_tvalid(out_decoded_buff_tvalid),
    .o_tready(out_decoded_buff_tready)
  );

  wire record_tvalid = ((record_en == 1'b1) && (record_count < record_len)) ? replay_sample_buff_tvalid : 1'b0;
  wire record_tlast = replay_sample_buff_tlast;

  assign dpti_fifo_pre_tvalids = {record_tvalid, out_decoded_buff_tvalid, out_corr_tvalid};
  assign replay_sample_buff_tready = (record_en) ? (dpti_fifo_pre_treadies[2] & record_count[0]) : replay_sample_buff_tready_receiver;
  assign out_decoded_buff_tready = dpti_fifo_pre_treadies[1];
  assign out_corr_tready = dpti_fifo_pre_treadies[0];
  assign dpti_fifo_pre_tdatas[2] = (record_count[0]) ? {record_tlast, 7'd2, replay_sample_buff_tdata[31:0]} : {1'b0, 7'd2, replay_sample_buff_tdata[63:32]};
  assign dpti_fifo_pre_tdatas[1] = {out_decoded_buff_tlast, 7'd1, out_decoded_buff_tdata};
  assign dpti_fifo_pre_tdatas[0] = {out_corr_tlast, 7'd0, out_corr_tdata};

endmodule
