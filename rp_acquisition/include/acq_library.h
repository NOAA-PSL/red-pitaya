#ifndef ACQ_LIBRARY_H
#def ACQ_LIBRARY_H

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "rp.h"

struct RPContext {
	uint32_t buff_size = 16384;
    std::vector<float> buffer;
};

// initializes rp for acquisition*
int rp_set(RPContext &ctx);

// acquires data and stores it in the rp buffer
void rp_acq();

// reads raw samples from buffer and prints them to stdout
void print_voltages(RPContext &ctx);

// creates a filename and path to store the collected samples to
std::string create_filename(std::string process);

// releases the rp (must call this after acquisition)
void rp_finish(RPContext &ctx);

#endif
