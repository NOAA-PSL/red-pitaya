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

int rp_set(RPContext &ctx);

void rp_acq();

void print_voltages(RPContext &ctx);

void apply_hanning_window(std::vector<float>& signal);



std::string create_filename(std::string process);

void rp_finish(RPContext &ctx);

#endif