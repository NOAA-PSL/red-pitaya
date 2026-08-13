`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2026 07:44:27 PM
// Design Name: 
// Module Name: system_sim
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

module system (

inout  logic [14:0] DDR_addr,
inout  logic [2:0]  DDR_ba,
inout  logic        DDR_cas_n,
inout  logic        DDR_ck_n,
inout  logic        DDR_ck_p,
inout  logic        DDR_cke,
inout  logic        DDR_cs_n,
inout  logic [3:0]  DDR_dm,
inout  logic [31:0] DDR_dq,
inout  logic [3:0]  DDR_dqs_n,
inout  logic [3:0]  DDR_dqs_p,
inout  logic        DDR_odt,
inout  logic        DDR_ras_n,
inout  logic        DDR_reset_n,
inout  logic        DDR_we_n,

inout  logic        FIXED_IO_ddr_vrn,
inout  logic        FIXED_IO_ddr_vrp,
inout  logic [53:0] FIXED_IO_mio,
inout  logic        FIXED_IO_ps_clk,
inout  logic        FIXED_IO_ps_porb,
inout  logic        FIXED_IO_ps_srstb,

output logic        FCLK_CLK0,
output logic        FCLK_CLK1,
output logic        FCLK_CLK2,
output logic        FCLK_CLK3,

output logic        FCLK_RESET0_N,
output logic        FCLK_RESET1_N,
output logic        FCLK_RESET2_N,
output logic        FCLK_RESET3_N,

input  logic        trig_in,
input  logic        gpio_trig,
output logic        trig_out,
input  logic        clksel,
input  logic        daisy_slave,

output logic        adc_clk,
output logic        clk_out,
output logic        rstn_out,

output logic [15:0] dac_dat_a,
output logic [15:0] dac_dat_b,

inout  logic [7:0]  gpio_p,
inout  logic [7:0]  gpio_n,

input logic [3:0]   loopback_sel,
input logic signed [13:0] adc_data_ch1,
input logic signed [13:0] adc_data_ch2,

input  logic [31:0] BRAM_PORTB_0_addr,
input  logic        BRAM_PORTB_0_clk,
input  logic [31:0] BRAM_PORTB_0_din,
output logic [31:0] BRAM_PORTB_0_dout,
input  logic        BRAM_PORTB_0_en,
input  logic        BRAM_PORTB_0_rst,
input  logic [3:0]  BRAM_PORTB_0_we


);


// ------------------------------------------------------------
// Simulation clock: 125 MHz
// ------------------------------------------------------------

initial begin
    clk_out = 1'b0;

    forever
        #4 clk_out = ~clk_out;
end

// The PLL in the DUT uses adc_clk_in as its reference.
assign adc_clk = clk_out;

// ------------------------------------------------------------
// Reset
// ------------------------------------------------------------

initial begin
    rstn_out = 1'b0;

    repeat (10)
        @(posedge clk_out);

    rstn_out = 1'b1;
end

// ------------------------------------------------------------
// Other outputs
// ------------------------------------------------------------

always_comb begin

    FCLK_CLK0 = clk_out;
    FCLK_CLK1 = clk_out;
    FCLK_CLK2 = clk_out;
    FCLK_CLK3 = clk_out;

    FCLK_RESET0_N = rstn_out;
    FCLK_RESET1_N = rstn_out;
    FCLK_RESET2_N = rstn_out;
    FCLK_RESET3_N = rstn_out;

    trig_out = 1'b0;

    dac_dat_a = 16'b0;
    dac_dat_b = 16'b0;

    BRAM_PORTB_0_dout = 32'b0;

end


endmodule
