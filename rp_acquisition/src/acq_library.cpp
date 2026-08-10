/*
 * Red Pitaya acquisition on CH1 LOW returning a spectra file
 */

#include "acq_library.h"
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fstream>
#include <vector>
#include <cmath>
#include <complex>
#include <fftw3.h>
#include "rp.h"

#define BUFFER_SIZE 16384
#define SAMPLING_RATE 125000000.0

int rp_set(RPContext &ctx){
	
    ctx.buff_size = BUFFER_SIZE;
	ctx.buffer.resize(ctx.buff_size);

    int ret = rp_Init();

    if (ret != RP_OK) {
        return -1;
    }

	/* Reset acquisition */
	rp_AcqReset();

	/* keep 125 MS/s ADC rate*/
	rp_AcqSetDecimation(RP_DEC_1);

	/*Set input range*/
	rp_AcqSetGain(RP_CH_1, RP_LOW);

	/* Trigger level*/
	rp_AcqSetTriggerLevel(RP_T_CH_1, 0.0);


	/*Trigger delay*/
	rp_AcqSetTriggerDelay(0);
	
	return 0;
}

void rp_acq(){

	/*Start acquisition*/
	rp_AcqStart();

	/*Trigger on positive edge CH1*/
	rp_AcqSetTriggerSrc(RP_TRIG_SRC_CHA_PE);


	/*Wait for trigger*/
	rp_acq_trig_state_t state;

	do {
		rp_AcqGetTriggerState(&state);
		usleep(1000);
	} while(state != RP_TRIG_STATE_TRIGGERED);

	/*Stop acquisition*/
	rp_AcqStop();
	
}
	
void print_voltages(RPContext &ctx){
	
	/*Read buffer*/
    int ret = rp_AcqGetOldestDataV(
        RP_CH_1,
        &ctx.buff_size,
        ctx.buffer.data());

    if (ret != RP_OK) {
        printf("Read failed: %s\n", rp_GetError(ret));
        return;
    }
	/*print out samples to stout*/
    for (uint32_t i = 0; i < ctx.buff_size; i++)
        printf("%u,%e\n", i, ctx.buffer[i]);

}

std::string create_filename(std::string process){
	
	// Get current time
    auto now = std::chrono::system_clock::now();
    std::time_t now_time = std::chrono::system_clock::to_time_t(now);

    // Format time
    std::stringstream ss;
    ss << std::put_time(std::localtime(&now_time), "%Y-%m-%d_%H-%M-%S");
    std::string time = ss.str();

    // Build filename and path
    std::string destName = process + time + ".txt";
    std::string destPath = "../../data/" + destName;

    return destPath;
}


void rp_finish(){
	
	rp_Release();
}
