`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2026 06:54:54 PM
// Design Name: 
// Module Name: tb_accumulator
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

module tb_accumulator;

    // ============================================================
    // Small simulation parameters
    // ============================================================

    localparam N_SAMPLES = 16;
    localparam N_IPP     = 4;

    // ============================================================
    // Testbench signals
    // ============================================================

    logic clk_125;
    logic rstn_0;

    logic acq_start;

    logic signed [13:0] adc_dat_ch1;
    logic signed [13:0] adc_dat_ch2;

    // Accumulation arrays
    logic signed [31:0] i_accum [0:N_SAMPLES-1];
    logic signed [31:0] q_accum [0:N_SAMPLES-1];

    logic [$clog2(N_SAMPLES)-1:0] sample_index;
    logic [$clog2(N_IPP)-1:0]     count;

    // ============================================================
    // BRAM simulation memory
    // ============================================================

    logic [31:0] bram [0:8191];

    logic [12:0] bram_write_index;
    logic        bram_write_active;
    logic        bram_write_done;

    logic [31:0] bram_din;

    // ============================================================
    // Clock
    // 125 MHz equivalent
    // 8 ns period
    // ============================================================

    initial begin
        clk_125 = 1'b0;
        forever #4 clk_125 = ~clk_125;
    end

    // ============================================================
    // Accumulation logic
    // ============================================================

    integer i;

    always @(posedge clk_125) begin

        if (!rstn_0) begin

            count       <= 0;
            sample_index <= 0;
            acq_start   <= 1'b1;

            for (i = 0; i < N_SAMPLES; i = i + 1) begin
                i_accum[i] <= 32'sd0;
                q_accum[i] <= 32'sd0;
            end

        end

        else if (acq_start) begin

            // Accumulate ADC samples
            i_accum[sample_index] <=
                i_accum[sample_index] + adc_dat_ch1;

            q_accum[sample_index] <=
                q_accum[sample_index] + adc_dat_ch2;

            // End of one acquisition
            if (sample_index == N_SAMPLES-1) begin

                sample_index <= 0;

                // Finished all acquisitions
                if (count == N_IPP-1) begin
                    count     <= 0;
                    acq_start <= 1'b0;
                end

                else begin
                    count <= count + 1'b1;
                end

            end

            else begin
                sample_index <= sample_index + 1'b1;
            end

        end
    end

    // ============================================================
    // BRAM write logic
    //
    // First N_SAMPLES locations = I
    // Next N_SAMPLES locations  = Q
    // ============================================================

    always @(posedge clk_125) begin

        if (!rstn_0) begin

            bram_write_index  <= 0;
            bram_write_active <= 1'b0;
            bram_write_done   <= 1'b0;

        end

        else begin

            // Start BRAM transfer when accumulation finishes
            if (!acq_start &&
                !bram_write_done &&
                !bram_write_active) begin

                bram_write_index  <= 0;
                bram_write_active <= 1'b1;

            end

            // Write BRAM
            if (bram_write_active) begin

                if (bram_write_index == (2*N_SAMPLES)-1) begin

                    bram_write_active <= 1'b0;
                    bram_write_done   <= 1'b1;

                end

                else begin

                    bram_write_index <= bram_write_index + 1'b1;

                end

            end

        end
    end

    // ============================================================
    // BRAM input data
    // ============================================================

    always_comb begin

        if (bram_write_index < N_SAMPLES)
            bram_din = i_accum[bram_write_index];

        else
            bram_din =
                q_accum[bram_write_index - N_SAMPLES];

    end

    // ============================================================
    // Actually store the BRAM data
    // ============================================================

    always @(posedge clk_125) begin

        if (bram_write_active) begin
            bram[bram_write_index] <= bram_din;
        end

    end

    // ============================================================
    // TEST
    // ============================================================

    initial begin

        // Initialize
        rstn_0 = 1'b0;

        adc_dat_ch1 = 0;
        adc_dat_ch2 = 0;

        // Hold reset for a few clocks
        repeat (5)
            @(posedge clk_125);

        rstn_0 = 1'b1;

        // --------------------------------------------------------
        // Feed 4 acquisitions.
        //
        // ADC1:
        //   sample 0 = 1
        //   sample 1 = 2
        //   sample 2 = 3
        //   ...
        //
        // ADC2:
        //   sample 0 = 10
        //   sample 1 = 20
        //   sample 2 = 30
        //   ...
        // --------------------------------------------------------

        for (int acquisition = 0;
             acquisition < N_IPP;
             acquisition++) begin

            for (int sample = 0;
                 sample < N_SAMPLES;
                 sample++) begin

                @(negedge clk_125);

                adc_dat_ch1 = sample + 1;
                adc_dat_ch2 = (sample + 1) * 10;

            end

        end

        // Wait for accumulation to finish
        wait (acq_start == 1'b0);

        // Wait for BRAM write to finish
        wait (bram_write_done == 1'b1);

        // Give final writes time to settle
        repeat (2)
            @(posedge clk_125);

        // --------------------------------------------------------
        // Display results
        // --------------------------------------------------------

        $display("");
        $display("========================================");
        $display(" ACCUMULATION RESULTS");
        $display("========================================");

        for (int sample = 0;
             sample < N_SAMPLES;
             sample++) begin

            $display(
                "sample %0d : I = %0d   Q = %0d",
                sample,
                bram[sample],
                bram[N_SAMPLES + sample]
            );

        end

        // --------------------------------------------------------
        // Automatic checks
        // --------------------------------------------------------

        for (int sample = 0;
             sample < N_SAMPLES;
             sample++) begin

            // Four acquisitions of (sample + 1)
            if (bram[sample] !=
                4 * (sample + 1)) begin

                $error(
                    "I[%0d] WRONG: expected %0d, got %0d",
                    sample,
                    4 * (sample + 1),
                    bram[sample]
                );

            end

            // Four acquisitions of (sample + 1)*10
            if (bram[N_SAMPLES + sample] !=
                4 * (sample + 1) * 10) begin

                $error(
                    "Q[%0d] WRONG: expected %0d, got %0d",
                    sample,
                    4 * (sample + 1) * 10,
                    bram[N_SAMPLES + sample]
                );

            end

        end

        $display("");
        $display("========================================");
        $display(" TEST COMPLETE");
        $display("========================================");

        $finish;

    end

endmodule


