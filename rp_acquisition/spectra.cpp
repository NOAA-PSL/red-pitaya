/*tis is just a testof a manual fft*/
    int ret = rp_AcqGetOldestDataV(
        RP_CH_1,
        &ctx.buff_size,
        ctx.buffer.data());

    if (ret != RP_OK) {
        printf("Read failed: %s\n", rp_GetError(ret));
        return;
    }
	
	/*pre-processing*/
	apply_hanning_window(ctx.buffer);
	
	int fft_size = BUFFER_SIZE / 2 + 1;
    std::vector<double> spectrum_magnitude(fft_size, 0.0);

    std::cout << "Computing spectrum frequencies..." << std::endl;
    for (int k = 0; k < fft_size; ++k) {
        std::complex<double> sum(0.0, 0.0);
        for (int n = 0; n < BUFFER_SIZE; ++n) {
            double angle = 2.0 * M_PI * k * n / BUFFER_SIZE;
            sum += std::complex<double>(time_buffer[n] * cos(angle), -time_buffer[n] * sin(angle));
        }
        /* Normalize amplitude relative to buffer size */
        spectrum_magnitude[k] = std::abs(sum) / (BUFFER_SIZE / 2.0);
    }

    /* Save to CSV Spectrum File */
    std::ofstream output_file(destPath);
    if (!output_file.is_open()) {
        std::cerr << "Failed to open output file!" << std::endl;
        return -1;
    }

    output_file << "# Frequency (Hz), Magnitude (V)\n";
    for (int k = 0; k < fft_size; ++k) {
        double frequency = (k * SAMPLING_RATE) / BUFFER_SIZE;
        output_file << frequency << ", " << spectrum_magnitude[k] << "\n";
    }

    output_file.close();
    std::cout << "Spectrum file saved to spectrum_data.csv successfully." << std::endl;

    return 0;
	
	void apply_hanning_window(std::vector<float>& signal) {
    int n = signal.size();
    for (int i = 0; i < n; ++i) {
        float multiplier = 0.5 * (1.0 - cos(2.0 * M_PI * i / (n - 1)));
        signal[i] *= multiplier;
    }
}
