`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2026 03:11:33 PM
// Design Name: 
// Module Name: tb_coherent_integrator
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

`timescale 1ns/1ps

module tb_coherent_integrator;


reg clk;
reg rstn;

reg signed [13:0] adc_i;
reg signed [13:0] adc_q;

reg integrate_start;

wire signed [39:0] sum_i;
wire signed [39:0] sum_q;

wire valid;

// sine generator variables
parameter N = 1000;
real phase;
real phase_step;
integer amplitude;

always @(posedge clk)
begin
    if(!rstn)
    begin
        adc_i <= 14'sd0;
        adc_q <= 14'sd0;
        phase = 0.0;
    end
    else
    begin
        adc_i <= $rtoi(amplitude * $cos(phase));
        adc_q <= $rtoi(amplitude * $sin(phase));

        phase = phase + phase_step;
    end
end

always @(posedge clk)
begin
    if(rstn)
        $strobe("t=%0t I=%d Q=%d",$time,adc_i,adc_q);
end


coherent_integrator #(
    .INT_LENGTH(N)
)
dut
(
    .clk(clk),
    .rstn(rstn),

    .adc_i(adc_i),
    .adc_q(adc_q),

    .integrate_start(integrate_start),

    .sum_i(sum_i),
    .sum_q(sum_q),

    .valid(valid)
);



//
// 125 MHz clock
// 8 ns period
//
always begin
    #4 clk = ~clk;
end

initial
begin

    clk = 0;
    rstn = 0;

    adc_i = 0;
    adc_q = 0;

    integrate_start = 0;

    //
    //initialize sine generator
    //
    phase = 0.0;
    amplitude = 8000;
    // 10 complete cycles during one integration period
    phase_step = 2.0 * 3.14159265358979 * 10.0 / N;

    // reset
    #50;

    rstn = 1;
    
    // allow sine generator to run
    repeat(10) @(posedge clk);

    //
    // start integration
    //

    @(posedge clk);

    integrate_start <= 1;

    @(posedge clk);

    integrate_start <= 0;

    //
    // Wait for integration
    //

    $display("Starting integration");

    wait(valid);
    
    $display("Valid asserted at time %t", $time);
    


    //
    // Check result
    //

    if ((sum_i < 20) && (sum_i > -20))
        $display("I SUM PASS");
    else
        $display("I SUM FAIL: %d", sum_i);
    
    
    if ((sum_q < 20) && (sum_q > -20))
        $display("Q SUM PASS");
    else
        $display("Q SUM FAIL: %d", sum_q);



    #100;

    $finish;

end


endmodule

