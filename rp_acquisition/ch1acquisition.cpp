/*
 * Red Pitaya acquisition on CH1 LOW
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "rp.h"


int main(int argc, char **argv)
{
    uint32_t buff_size = 16384;
    float *buffer = (float *)malloc(buff_size * sizeof(float));

    if (!buffer)  {
        printf("Memory allocation failed\n");
        return -1;
    }

    int ret = rp_Init();

    if (ret != RP_OK){
        printf("rp_Init failed: %s\n", rp_GetError(ret));
        return -1;
    }

    /* Reset acquisition */
    rp_AcqReset();


    /*125 MS/s ADC rate*/
    rp_AcqSetDecimation(RP_DEC_1);

    /*Set input range*/
    rp_AcqSetGain(RP_CH_1, RP_LOW);

    /* Trigger level*/
    rp_AcqSetTriggerLevel(RP_T_CH_1, 0.0);


    /*Trigger delay*/
    rp_AcqSetTriggerDelay(0);

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

    /*Read buffer*/
    ret = rp_AcqGetOldestDataV(
		RP_CH_1,
		&buff_size,
		buffer);

    if(ret != RP_OK) {
        printf("Read failed: %s\n", rp_GetError(ret));
    }

	/*print out samples to stout*/
	for(uint32_t i=0; i<buff_size; i++){
				printf("%u,%e\n",i,buffer[i]);
		}

    /*printf("Captured %u samples\n",
          # buff_size); */


    free(buffer);
    rp_Release();

    return 0;
}