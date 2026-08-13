`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2026 07:43:16 PM
// Design Name: 
// Module Name: red_pitaya_pll_sim
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

module red_pitaya_pll (
input  wire clk,
input  wire rstn,


output wire clk_dac_1x,
output wire clk_dac_2x,
output wire clk_dac_2p,

output wire pll_locked


);


// For behavioral simulation we use the same 125 MHz clock.
// The DAC clock frequencies are not important for testing
// the accumulator.

assign clk_dac_1x = clk;
assign clk_dac_2x = clk;
assign clk_dac_2p = clk;

assign pll_locked = rstn;


endmodule

