//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
//Date        : Thu Oct 17 12:18:07 2019
//Host        : Jon-PC running 64-bit major release  (build 9200)
//Command     : generate_target system_wrapper.bd
//Design      : system_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module red_pitaya_top #(
  // identification
  bit [0:5*32-1] GITH = '0,
  // module numbers
  int unsigned MNA = 2,  // number of acquisition modules
  int unsigned MNG = 2,   // number of generator   modules
  
  
  parameter integer N_SAMPLES = 4096,  // number of samples take after every transmit pulse
  parameter integer N_IPP = 256 // number of interpulse periods to be used for coherent accumulation
)(
  // PS connections
  inout  logic [54-1:0] FIXED_IO_mio     ,
  inout  logic          FIXED_IO_ps_clk  ,
  inout  logic          FIXED_IO_ps_porb ,
  inout  logic          FIXED_IO_ps_srstb,
  inout  logic          FIXED_IO_ddr_vrn ,
  inout  logic          FIXED_IO_ddr_vrp ,
  // DDR
  inout  logic [15-1:0] DDR_addr   ,
  inout  logic [ 3-1:0] DDR_ba     ,
  inout  logic          DDR_cas_n  ,
  inout  logic          DDR_ck_n   ,
  inout  logic          DDR_ck_p   ,
  inout  logic          DDR_cke    ,
  inout  logic          DDR_cs_n   ,
  inout  logic [ 4-1:0] DDR_dm     ,
  inout  logic [32-1:0] DDR_dq     ,
  inout  logic [ 4-1:0] DDR_dqs_n  ,
  inout  logic [ 4-1:0] DDR_dqs_p  ,
  inout  logic          DDR_odt    ,
  inout  logic          DDR_ras_n  ,
  inout  logic          DDR_reset_n,
  inout  logic          DDR_we_n   ,

  // Red Pitaya periphery

  // ADC
  input  logic [MNA-1:0] [16-1:0] adc_dat_i,  // ADC data
  input  logic           [ 2-1:0] adc_clk_i,  // ADC clock {p,n}
  output logic           [ 2-1:0] adc_clk_o,  // optional ADC clock source (unused)
  output logic                    adc_cdcs_o, // ADC clock duty cycle stabilizer
  // DAC
  output logic [14-1:0] dac_dat_o  ,  // DAC combined data
  output logic          dac_wrt_o  ,  // DAC write
  output logic          dac_sel_o  ,  // DAC channel select
  output logic          dac_clk_o  ,  // DAC clock
  output logic          dac_rst_o  ,  // DAC reset
  // PDM DAC
  output logic [ 4-1:0] dac_pwm_o  ,  // 1-bit PDM DAC
  // XADC
  input  logic [ 5-1:0] vinp_i     ,  // voltages p
  input  logic [ 5-1:0] vinn_i     ,  // voltages n
  // Expansion connector
  inout  logic [ 8-1:0] exp_p_io   ,
  inout  logic [ 8-1:0] exp_n_io   ,
  // SATA connector
  output logic [ 2-1:0] daisy_p_o  ,  // line 1 is clock capable
  output logic [ 2-1:0] daisy_n_o  ,
  input  logic [ 2-1:0] daisy_p_i  ,  // line 1 is clock capable
  input  logic [ 2-1:0] daisy_n_i  ,
  // LED
  inout  logic [ 8-1:0] led_o
);

// PLL signals
logic                 adc_clk_in;
logic                 adc_clk_daisy;
logic                 pll_adc_clk;
logic                 pll_dac_clk_1x;
logic                 pll_dac_clk_2x;
logic                 pll_dac_clk_2p;
logic                 pll_locked;

// DAC signals
logic                    dac_clk_1x;
logic                    dac_clk_2x;
logic                    dac_clk_2p;
logic                    dac_rst;

logic [4-1:0] fclk ; //[0]-125MHz, [1]-250MHz, [2]-50MHz, [3]-200MHz
logic [4-1:0] frstn;

logic          clksel;
logic [16-1:0] dac_dat_a, dac_dat_b;

// BRAM Interface (for accumulation arrays)
logic [31:0] bram_addr;
logic [31:0] bram_din;
logic [31:0] bram_dout;
logic        bram_en;
logic        bram_rst;
logic [3:0]  bram_we;
logic        bram_clk;

// coherent accumulation logic
logic       acq_start;


wire trig_out;
wire gpio_trig;
wire clk_125;
wire trig_ext;

////////////////////////////////////////////////////////////////////////////////
// PLL (clock and reset)
////////////////////////////////////////////////////////////////////////////////
assign dac_pwm_o = 4'h0;

reg [32-1:0] led_cnt;
reg          clk_rec_blnk='h0;

always @(posedge clk_125) //shows FPGA is loaded and has a clock
begin
  if (~rstn_0) begin
    led_cnt <= 32'h0;
    clk_rec_blnk <= 'h0;
  end else begin 
    if (led_cnt < 32'd62500000)
      led_cnt <= led_cnt + 'h1;
    else begin
      led_cnt <= 32'h0;
      clk_rec_blnk <= ~clk_rec_blnk;
    end
  end
end

red_pitaya_pll pll (
  // inputs
  .clk         (adc_clk_in),  // clock
  .rstn        (rstn_0    ),  // reset - active low
  // output clocks
  .clk_dac_1x  (pll_dac_clk_1x),  // DAC clock 125MHz
  .clk_dac_2x  (pll_dac_clk_2x),  // DAC clock 250MHz
  .clk_dac_2p  (pll_dac_clk_2p),  // DAC clock 250MHz -45DGR
  // status outputs
  .pll_locked  (pll_locked)
);

BUFG bufg_dac_clk_1x (.O (dac_clk_1x), .I (pll_dac_clk_1x));
BUFG bufg_dac_clk_2x (.O (dac_clk_2x), .I (pll_dac_clk_2x));
BUFG bufg_dac_clk_2p (.O (dac_clk_2p), .I (pll_dac_clk_2p));

// DDR outputs
ODDR oddr_dac_clk          (.Q(dac_clk_o), .D1(1'b0     ), .D2(1'b1     ), .C(dac_clk_2p), .CE(1'b1), .R(1'b0   ), .S(1'b0));
ODDR oddr_dac_wrt          (.Q(dac_wrt_o), .D1(1'b0     ), .D2(1'b1     ), .C(dac_clk_2x), .CE(1'b1), .R(1'b0   ), .S(1'b0));
ODDR oddr_dac_sel          (.Q(dac_sel_o), .D1(1'b1     ), .D2(1'b0     ), .C(dac_clk_1x), .CE(1'b1), .R(dac_rst), .S(1'b0));
ODDR oddr_dac_rst          (.Q(dac_rst_o), .D1(dac_rst  ), .D2(dac_rst  ), .C(dac_clk_1x), .CE(1'b1), .R(1'b0   ), .S(1'b0));
ODDR oddr_dac_dat [14-1:0] (.Q(dac_dat_o), .D1(dac_dat_b_o), .D2(dac_dat_a_o), .C(dac_clk_1x), .CE(1'b1), .R(dac_rst), .S(1'b0));

// DAC reset (active high)
always @(posedge dac_clk_1x)
dac_rst  <= ~rstn_0 | ~pll_locked;

wire [ 4-1:0] loopback_sel_ch1, loopback_sel_ch2;
reg signed [13:0] adc_dat_ch1;
reg signed [13:0] adc_dat_ch2;
reg  [14-1:0] adc_dat_ch1_r,    adc_dat_ch2_r;
reg  [14-1:0] dac_dat_a_o,      dac_dat_b_o;
reg  [31:0] i_dat_coint_r;
reg  [31:0] q_dat_coint_r;

always @(posedge dac_clk_1x)
begin
  dac_dat_a_o <= {dac_dat_a[16-1], ~dac_dat_a[16-2:2]};
  dac_dat_b_o <= {dac_dat_b[16-1], ~dac_dat_b[16-2:2]};
end

// capture if acq is high. perform coherent integration and  
integer i;

reg signed [31:0] i_accum [0:N_SAMPLES-1];
reg signed [31:0] q_accum [0:N_SAMPLES-1];
reg [$clog2(N_SAMPLES)-1:0] sample_index;
reg [$clog2(N_IPP)-1:0] count;

// stream data
// ------------------------------------------------------------------
// Pipeline valid tracking.
//
// The ADC capture pipeline below is 2 cycles deep
// (adc_dat_i -> adc_dat_ch1_r -> adc_dat_ch1). By delaying acq_start
// by exactly 2 cycles, cap_valid tells us precisely when
// adc_dat_ch1/adc_dat_ch2 hold data that corresponds to a sample
// taken while acq_start was actually asserted -- regardless of how
// deep the pipeline is or how sample_index/count are clocked.
// ------------------------------------------------------------------
reg  [2:0] cap_valid_sr;
wire       cap_valid = cap_valid_sr[2];

always @(posedge clk_125) begin
    if (~rstn_0)
        cap_valid_sr <= 3'b000;
    else
        cap_valid_sr <= {cap_valid_sr[1:0], acq_start};
end

// ------------------------------------------------------------------
// ADC capture pipeline - runs UNCONDITIONALLY, every cycle.
// It always reflects the incoming ADC stream with a fixed, known
// 2-cycle latency, independent of acq_start's state. This mirrors
// real ADC behavior (data is always live) and avoids the previous
// bug where sample_index advanced before the pipeline had caught up.
// ------------------------------------------------------------------
always @(posedge clk_125) begin

    if (~rstn_0) begin
        $display("[%0t] ADC pipeline reset applied", $time);
        adc_dat_ch1_r <= '0;
        adc_dat_ch2_r <= '0;
        adc_dat_ch1   <= '0;
        adc_dat_ch2   <= '0;
    end
    else begin
        adc_dat_ch1_r <= adc_dat_i[0][16-1:2];
        adc_dat_ch2_r <= adc_dat_i[1][16-1:2];
    
        if (loopback_sel_ch1[1])
            adc_dat_ch1 <= {dac_dat_a[16-1],     ~dac_dat_a[16-2:2]};
        else
            adc_dat_ch1 <= {adc_dat_ch1_r[14-1], ~adc_dat_ch1_r[14-2:0]};
    
        if (loopback_sel_ch2[1])
            adc_dat_ch2 <= {dac_dat_b[16-1],     ~dac_dat_b[16-2:2]};
        else
            adc_dat_ch2 <= {adc_dat_ch2_r[14-1], ~adc_dat_ch2_r[14-2:0]};
    end
end

reg [$clog2(N_SAMPLES*N_IPP)-1:0] req_count;
reg [$clog2(N_SAMPLES*N_IPP):0]   write_count;
reg                                accum_done;

// Request generator: drives acq_start high for EXACTLY N_SAMPLES*N_IPP
// cycles, independent of cap_valid's latency. Breaks the circular
// dependency that was causing 3 extra phantom pulses.
always @(posedge clk_125) begin
    if (~rstn_0) begin
        req_count <= 0;
        acq_start <= 1;
    end
    else if (acq_start) begin
        if (req_count == N_SAMPLES*N_IPP - 1)
            acq_start <= 1'b0;
        else
            req_count <= req_count + 1;
    end
end

// Accumulator: purely gated by cap_valid. Tracks its own completion
// (accum_done) instead of relying on acq_start, since acq_start now
// drops 3 cycles before the pipeline actually finishes draining.
always @(posedge clk_125) begin
    if (~rstn_0) begin
        sample_index <= 0;
        write_count  <= 0;
        accum_done   <= 1'b0;

        for (i = 0; i < N_SAMPLES; i = i + 1) begin
            i_accum[i] <= 32'sd0;
            q_accum[i] <= 32'sd0;
        end
    end
    else if (cap_valid) begin
        i_accum[sample_index] <= i_accum[sample_index] + $signed(adc_dat_ch1);
        q_accum[sample_index] <= q_accum[sample_index] + $signed(adc_dat_ch2);

        sample_index <= (sample_index == N_SAMPLES-1) ? 0 : sample_index + 1;
        write_count  <= write_count + 1;

        if (write_count == N_SAMPLES*N_IPP - 1)
            accum_done <= 1'b1;
    end
end

// BRAM write controller
reg [12:0] bram_write_index; //13 bc 8192 locations
reg        bram_write_active;
reg        bram_write_done;

// BRAM write logic
//always @(posedge clk_125) begin
//    if (~rstn_0) begin
//        bram_write_index  <= 13'd0;
//        bram_write_active <= 1'b0;
//        bram_write_done   <= 1'b0;
//    end
//    else begin

//        // Accumulation has finished.
//        // Start copying the accumulated results to BRAM.
//        if (~acq_start && ~bram_write_done && ~bram_write_active) begin
//            bram_write_index  <= 13'd0;
//            bram_write_active <= 1'b1;
//        end

//        // Advance through all 8192 BRAM locations.
//        if (bram_write_active) begin
//            if (bram_write_index == (2*N_SAMPLES-1)) begin
//                bram_write_active <= 1'b0;
//                bram_write_done   <= 1'b1;
//            end
//            else begin
//                bram_write_index <= bram_write_index + 1'b1;
//            end
//        end
//    end
//end

always @(posedge clk_125) begin
    if (~rstn_0) begin
        bram_write_index  <= 13'd0;
        bram_write_active <= 1'b0;
        bram_write_done   <= 1'b0;
    end
    else begin
        if (accum_done && ~bram_write_done && ~bram_write_active) begin   // was: ~acq_start
            bram_write_index  <= 13'd0;
            bram_write_active <= 1'b1;
        end
        if (bram_write_active) begin
            if (bram_write_index == (2*N_SAMPLES-1)) begin
                bram_write_active <= 1'b0;
                bram_write_done   <= 1'b1;
            end
            else
                bram_write_index <= bram_write_index + 1'b1;
        end
    end
end

// BRAM Port B signals
assign bram_en  = bram_write_active;
assign bram_we  = bram_write_active ? 4'b1111 : 4'b0000;
assign bram_rst = ~rstn_0;

// BRAM uses byte addressing.
// Each 32-bit word is 4 bytes.
assign bram_addr = {19'd0, bram_write_index, 2'b00};

// First 4096 words = I accumulation
// Second 4096 words = Q accumulation
assign bram_din =
(bram_write_index < N_SAMPLES) ?
i_accum[bram_write_index] :
q_accum[bram_write_index - N_SAMPLES];

reg [10-1:0] daisy_cnt      =  'h0;
reg          daisy_slave    = 1'b0;

always @(posedge adc_clk_daisy) begin // if there is a clock present on the daisy chain connector, the board will be treated as a slave
  if (~rstn_0) begin
    daisy_cnt     <= 'h0;
    daisy_slave <= 1'b0;
  end else begin 
    daisy_cnt <= daisy_cnt + 'h1;
    if (&daisy_cnt)
      daisy_slave <= 1'b1;
  end
end

assign led_o = {5'h0,daisy_slave,~rstn_0,clk_rec_blnk};

ODDR i_adc_clk_p ( .Q(adc_clk_o[0]), .D1(1'b1), .D2(1'b0), .C(adc_clk_daisy), .CE(1'b1), .R(1'b0), .S(1'b0));
ODDR i_adc_clk_n ( .Q(adc_clk_o[1]), .D1(1'b0), .D2(1'b1), .C(adc_clk_daisy), .CE(1'b1), .R(1'b0), .S(1'b0));


assign adc_cdcs_o = 1'b1 ;
assign bram_clk = clk_125;
////////////////////////////////////////////////////////////////////////////////
// DAC IO
////////////////////////////////////////////////////////////////////////////////

  //system_wrapper system_wrapper_i
  system system_wrapper_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .FCLK_CLK0         (fclk[0]      ),
        .FCLK_CLK1         (fclk[1]      ),
        .FCLK_CLK2         (fclk[2]      ),
        .FCLK_CLK3         (fclk[3]      ),
        .FCLK_RESET0_N     (frstn[0]     ),
        .FCLK_RESET1_N     (frstn[1]     ),
        .FCLK_RESET2_N     (frstn[2]     ),
        .FCLK_RESET3_N     (frstn[3]     ),
        .trig_in           (external_trig),
        .gpio_trig         (gpio_trig),
        .trig_out          (trig_out),
        .clksel            (clksel),
        .daisy_slave       (daisy_slave),
        .adc_clk           (adc_clk_in),
        .clk_out           (clk_125),
        .rstn_out          (rstn_0),
        .dac_dat_a         (dac_dat_a),
        .dac_dat_b         (dac_dat_b),
        .gpio_p            (exp_p_io),
        .gpio_n            (exp_n_io),
        .loopback_sel      ({loopback_sel_ch2,loopback_sel_ch1}),
        .adc_data_ch1      (adc_dat_ch1),
        .adc_data_ch2      (adc_dat_ch2),
        
        .BRAM_PORTB_0_addr (bram_addr),
        .BRAM_PORTB_0_clk  (bram_clk),
        .BRAM_PORTB_0_din  (bram_din),
        .BRAM_PORTB_0_dout (bram_dout),
        .BRAM_PORTB_0_en   (bram_en),
        .BRAM_PORTB_0_rst  (bram_rst),
        .BRAM_PORTB_0_we   (bram_we)
   );
        
//wire signed [39:0] integ_I;
//wire signed [39:0] integ_Q;
//wire integ_valid;

OBUFDS #(.IOSTANDARD ("DIFF_HSTL_I_18"), .SLEW ("FAST")) i_OBUF_trig
(
  .O  ( daisy_p_o[0]  ),
  .OB ( daisy_n_o[0]  ),
  .I  ( trig_out      )
);

OBUFDS #(.IOSTANDARD ("DIFF_HSTL_I_18"), .SLEW ("FAST")) i_OBUF_clk
(
  .O  ( daisy_p_o[1]  ),
  .OB ( daisy_n_o[1]  ),
  .I  ( adc_clk_in    )
);

IBUFDS #() i_IBUF_clkadc
(
  .I  ( adc_clk_i[1]  ),
  .IB ( adc_clk_i[0]  ),
  .O  ( adc_clk_in    )
);

IBUFDS #(.IOSTANDARD ("DIFF_HSTL_I_18")) i_IBUF_clkdaisy
(
  .I  ( daisy_p_i[1]  ),
  .IB ( daisy_n_i[1]  ),
  .O  ( adc_clk_daisy )
);

IBUFDS #(.IOSTANDARD ("DIFF_HSTL_I_18")) i_IBUFDS_trig
(
  .I  ( daisy_p_i[0]  ),
  .IB ( daisy_n_i[0]  ),
  .O  ( trig_ext      )
);

assign external_trig = trig_ext | gpio_trig;



endmodule