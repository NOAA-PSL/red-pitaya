
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2026 07:30:33 PM
// Design Name: 
// Module Name: tb_red_pitaya_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module tb_red_pitaya_top;

// ============================================================
// Small simulation parameters
//
// These override the large hardware values in our test
// expectations only. The DUT itself currently uses:
//
// N_SAMPLES = 4096
// N_IPP     = 256
//
// For this first test we will therefore test the DUT's
// actual parameters. This takes about 8.4 ms at 125 MHz.
// ============================================================

parameter integer N_SAMPLES = 16; //4096
parameter integer N_IPP     = 4; //256

// ============================================================
// Red Pitaya top-level ports
// ============================================================

tri [53:0] FIXED_IO_mio;

tri FIXED_IO_ps_clk;
tri FIXED_IO_ps_porb;
tri FIXED_IO_ps_srstb;

// driver variables
logic ps_clk_drv;
logic ps_porb_drv;
logic ps_srstb_drv;

assign FIXED_IO_ps_clk   = ps_clk_drv;
assign FIXED_IO_ps_porb  = ps_porb_drv;
assign FIXED_IO_ps_srstb = ps_srstb_drv;

initial begin
    adc_dat_i[0] = encode_adc(1);
    adc_dat_i[1] = encode_adc(10);
end

// ============================================================
// Zynq Processing System clock/reset
// ============================================================

 //Typical 33.333 MHz PS clock
initial begin
    ps_clk_drv = 1'b0;
    forever #15 ps_clk_drv = ~ps_clk_drv;
end

initial begin
    ps_porb_drv  = 1'b0;
    ps_srstb_drv = 1'b0;

    #1000;
    ps_porb_drv  = 1'b1;

    #1000;
    ps_srstb_drv = 1'b1;

    $display("[%0t] PS resets released", $time);
end


tri        FIXED_IO_ddr_vrn;
tri        FIXED_IO_ddr_vrp;

tri [14:0] DDR_addr;
tri [2:0]  DDR_ba;
tri        DDR_cas_n;
tri        DDR_ck_n;
tri        DDR_ck_p;
tri        DDR_cke;
tri        DDR_cs_n;
tri [3:0]  DDR_dm;
tri [31:0] DDR_dq;
tri [3:0]  DDR_dqs_n;
tri [3:0]  DDR_dqs_p;
tri        DDR_odt;
tri        DDR_ras_n;
tri        DDR_reset_n;
tri        DDR_we_n;

logic [1:0][15:0] adc_dat_i;
logic [1:0]       adc_clk_i;
logic [1:0]       adc_clk_o;
logic             adc_cdcs_o;

logic [13:0] dac_dat_o;
logic         dac_wrt_o;
logic         dac_sel_o;
logic         dac_clk_o;
logic         dac_rst_o;

logic [3:0]  dac_pwm_o;

logic [4:0]  vinp_i;
logic [4:0]  vinn_i;

tri [7:0] exp_p_io;
tri [7:0] exp_n_io;

logic [1:0] daisy_p_o;
logic [1:0] daisy_n_o;
logic [1:0] daisy_p_i;
logic [1:0] daisy_n_i;

tri [7:0] led_o;

// ============================================================
// Instantiate YOUR actual design
// ============================================================

red_pitaya_top #(
    .N_SAMPLES(N_SAMPLES),
    .N_IPP(N_IPP)
)dut (
    .FIXED_IO_mio      (FIXED_IO_mio),
    .FIXED_IO_ps_clk   (FIXED_IO_ps_clk),
    .FIXED_IO_ps_porb  (FIXED_IO_ps_porb),
    .FIXED_IO_ps_srstb (FIXED_IO_ps_srstb),
    .FIXED_IO_ddr_vrn  (FIXED_IO_ddr_vrn),
    .FIXED_IO_ddr_vrp  (FIXED_IO_ddr_vrp),

    .DDR_addr          (DDR_addr),
    .DDR_ba            (DDR_ba),
    .DDR_cas_n         (DDR_cas_n),
    .DDR_ck_n          (DDR_ck_n),
    .DDR_ck_p          (DDR_ck_p),
    .DDR_cke          (DDR_cke),
    .DDR_cs_n          (DDR_cs_n),
    .DDR_dm            (DDR_dm),
    .DDR_dq            (DDR_dq),
    .DDR_dqs_n         (DDR_dqs_n),
    .DDR_dqs_p         (DDR_dqs_p),
    .DDR_odt           (DDR_odt),
    .DDR_ras_n         (DDR_ras_n),
    .DDR_reset_n       (DDR_reset_n),
    .DDR_we_n          (DDR_we_n),

    .adc_dat_i         (adc_dat_i),
    .adc_clk_i         (adc_clk_i),
    .adc_clk_o         (adc_clk_o),
    .adc_cdcs_o        (adc_cdcs_o),

    .dac_dat_o         (dac_dat_o),
    .dac_wrt_o         (dac_wrt_o),
    .dac_sel_o         (dac_sel_o),
    .dac_clk_o         (dac_clk_o),
    .dac_rst_o         (dac_rst_o),
    .dac_pwm_o         (dac_pwm_o),

    .vinp_i            (vinp_i),
    .vinn_i            (vinn_i),

    .exp_p_io          (exp_p_io),
    .exp_n_io          (exp_n_io),

    .daisy_p_o         (daisy_p_o),
    .daisy_n_o         (daisy_n_o),
    .daisy_p_i         (daisy_p_i),
    .daisy_n_i         (daisy_n_i),

    .led_o             (led_o)
);

// ============================================================
// DEBUG CLOCK / RESET MONITORS
// ============================================================

always @(dut.rstn_0) begin
    $display("[%0t] rstn_0 = %b", $time, dut.rstn_0);
end

always @(ps_porb_drv or ps_srstb_drv) begin
    $display("[%0t] PS reset signals: porb=%b srstb=%b",
             $time,
             ps_porb_drv,
             ps_srstb_drv);
end

//always @(dut.clk_125) begin
//    if (dut.clk_125 === 1'b1)
//        $display("[%0t ns] clk_125 rising, rstn_0=%b, acq_start=%b",
//                 $time,
//                 dut.rstn_0,
//                 dut.acq_start);
//end

//always @(posedge dut.clk_125) begin
//    if (dut.cap_valid)
//        $display("[%0t] sample_index=%0d adc_dat_ch1=%0d",
//                  $time, dut.sample_index, $signed(dut.adc_dat_ch1));
//end

// ============================================================
// ADC clock
//
// 125 MHz = 8 ns period
// ============================================================

initial begin
    adc_clk_i = 2'b01;

    forever begin
        #4 adc_clk_i[1] = ~adc_clk_i[1];
        adc_clk_i[0] = ~adc_clk_i[0];
    end
end

// ============================================================
// Static unused inputs
// ============================================================

initial begin
    vinp_i = 5'b0;
    vinn_i = 5'b0;

    daisy_p_i = 2'b0;
    daisy_n_i = 2'b0;
end

// ============================================================
// Convert desired signed 14-bit ADC value into the raw
// 16-bit ADC representation expected by the code.
//
// DUT does:
//
// adc_dat_ch1_r <= adc_dat_i[15:2];
//
// then:
//
// adc_dat_ch1 <=
//     {adc_dat_ch1_r[13],
//      ~adc_dat_ch1_r[12:0]};
//
// Therefore this function reverses that operation.
// ============================================================

function automatic [15:0] encode_adc;
    input integer value;

    reg signed [13:0] wanted;
    reg        sign_bit;
    reg [12:0] lower;

    begin
        wanted   = value;
        sign_bit = wanted[13];
        lower    = ~wanted[12:0];

        encode_adc = {sign_bit, lower, 2'b00};
    end
endfunction

// ============================================================
// Drive one ADC sample
// ============================================================

task automatic drive_sample;
    input integer sample;

    begin
        adc_dat_i[0] = encode_adc(sample + 1);
        adc_dat_i[1] = encode_adc((sample + 1) * 10);
    end
endtask

// ============================================================
// Main test
// ============================================================

integer i;
integer expected_i;
integer expected_q;
integer errors;

initial begin

    errors = 0;
    
    $display("[%0t] TESTBENCH STARTED", $time);

    $display("[%0t] Waiting for dut.rstn_0...", $time);
    
    // --------------------------------------------------------
    // Simulation reset
    //
    // The Zynq PS reset inputs are released at 2000 ns,
    // but the generated rstn_0 inside the DUT does not
    // release in this behavioral simulation.
    //
    // For this accumulator-only test, bypass that PS reset
    // dependency and force rstn_0 high.
    // --------------------------------------------------------
    
    wait (FIXED_IO_ps_porb === 1'b1);
    wait (FIXED_IO_ps_srstb === 1'b1);
    
    $display("[%0t] PS reset inputs: porb=%b srstb=%b",
             $time,
             FIXED_IO_ps_porb,
             FIXED_IO_ps_srstb);
       
    $display("[%0t] FORCED dut.rstn_0 = %b",
             $time,
             dut.rstn_0);
    
    
    $display("[%0t] Starting acquisition test", $time);
   

// --------------------------------------------------------
// Force a clean re-synchronization right before the real
// test starts. This guarantees sample_index=0, count=0,
// and the accumulator arrays are freshly zeroed exactly
// at the moment we begin driving real varying data --
// eliminating any stale accumulation from the settle time
// above.
// --------------------------------------------------------
force dut.rstn_0 = 1'b0;
@(posedge dut.clk_125);
@(posedge dut.clk_125);
@(posedge dut.clk_125);
@(posedge dut.clk_125);
force dut.rstn_0 = 1'b1;
@(posedge dut.clk_125);   // let acq_start/counters register cleanly from this reset

drive_sample(0);

// --------------------------------------------------------
// Feed the next samples.
//
// The DUT's ADC path is pipelined, so change the ADC
// input on the negative edge. The accumulator samples
// on the positive edge.
// --------------------------------------------------------

for (integer acquisition = 0;
     acquisition < N_IPP;
     acquisition++) begin

    for (integer sample = 0;
         sample < N_SAMPLES;
         sample++) begin

        @(negedge dut.clk_125);

        drive_sample(sample);
    end

end

// --------------------------------------------------------
// Wait until your actual accumulator says it is finished.
// --------------------------------------------------------

wait (dut.acq_start == 1'b0);

$display("");
$display("==============================================");
$display(" ACTUAL red_pitaya_top ACCUMULATION TEST");
$display("==============================================");
$display("N_SAMPLES = %0d", N_SAMPLES);
$display("N_IPP     = %0d", N_IPP);
$display("");

// --------------------------------------------------------
// Wait for your actual BRAM writer.
// --------------------------------------------------------

wait (dut.bram_write_done == 1'b1);

// Give final BRAM writes time to settle.
repeat (2)
    @(posedge dut.clk_125);

// --------------------------------------------------------
// Check I and Q accumulation arrays.
//
// This checks the actual arrays inside YOUR DUT.
// --------------------------------------------------------

$display("Checking accumulation arrays...");

for (i = 0; i < N_SAMPLES; i = i + 1) begin

    expected_i = N_IPP * (i + 1);
    expected_q = N_IPP * (i + 1) * 10;

    if ($signed(dut.i_accum[i]) !== expected_i) begin

        $display(
            "FAIL I[%0d]: expected %0d, got %0d",
            i,
            expected_i,
            $signed(dut.i_accum[i])
        );

        errors = errors + 1;
    end

    if ($signed(dut.q_accum[i]) !== expected_q) begin

        $display(
            "FAIL Q[%0d]: expected %0d, got %0d",
            i,
            expected_q,
            $signed(dut.q_accum[i])
        );

        errors = errors + 1;
    end

end

// --------------------------------------------------------
// Check the BRAM interface.
//
// Your actual top-level does not contain a local BRAM
// array. It writes through the BRAM_PORTB interface.
//
// For this first test, therefore, verify the BRAM data
// bus while the writer is active and the address mapping.
// --------------------------------------------------------

$display("");
$display("Checking selected BRAM write values...");

//    // Check representative addresses in the I region.
//    check_bram_value(0,       N_IPP * 1);
//    check_bram_value(4,       N_IPP * 2);
//    check_bram_value(8,       N_IPP * 3);
//    check_bram_value(4095*4,  N_IPP * 4096);

//    // Check representative addresses in the Q region.
//    check_bram_value(4096*4,       N_IPP * 10);
//    check_bram_value(4097*4,       N_IPP * 20);
//    check_bram_value(4098*4,       N_IPP * 30);
//    check_bram_value(8191*4,       N_IPP * 40960);

    check_bram_value(0,       N_IPP * 1);
    check_bram_value(4,       N_IPP * 2);
    check_bram_value(8,       N_IPP * 3);
    check_bram_value(15*4,    N_IPP * 16);
    
    check_bram_value(16*4,    N_IPP * 10);
    check_bram_value(17*4,    N_IPP * 20);
    check_bram_value(18*4,    N_IPP * 30);
    check_bram_value(31*4,    N_IPP * 160);

    // --------------------------------------------------------
    // Final result
    // --------------------------------------------------------

    $display("");
    $display("==============================================");

    if (errors == 0) begin
        $display(" ALL ACCUMULATION TESTS PASSED");
        $display("==============================================");
    end
    else begin
        $display(
            "THE TEST FAILED: %0d errors",
            errors
        );
        $display("==============================================");
    end

    $finish;
end

// ============================================================
// BRAM monitor
//
// This watches the actual BRAM signals generated by your DUT.
// ============================================================

task automatic check_bram_value;
    input integer byte_address;
    input integer expected;

    integer word_address;

    begin
        word_address = byte_address / 4;

        if ($signed(bram_model[word_address]) !== expected) begin
            $display(
                "FAIL BRAM[%0d]: expected %0d, got %0d",
                word_address,
                expected,
                $signed(bram_model[word_address])
            );

            errors = errors + 1;
        end
        else begin
            $display(
                "PASS BRAM[%0d] = %0d",
                word_address,
                $signed(bram_model[word_address])
            );
        end
    end
endtask

// ============================================================
// Simulation model of the BRAM connected to your DUT.
//
// bram_addr is byte addressed, so divide by 4 to obtain
// the 32-bit word index.
// ============================================================

reg [31:0] bram_model [0:8191];

always @(posedge dut.clk_125) begin

    if (dut.bram_en && dut.bram_we != 0) begin

        bram_model[dut.bram_addr >> 2] <= dut.bram_din;

    end
end


endmodule

