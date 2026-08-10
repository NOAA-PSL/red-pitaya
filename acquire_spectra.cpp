#include "rp.h"
#include <iostream>
#include <cstdlib>

#include <chrono>
#include <ctime>
#include <sstream>
#include <iomanip>
#include <string>

int main(){
	
	//std:string process = "spectrum";
	//std:string destPath = create_filename(process);
	
	std::string command = "/opt/redpitaya/bin/spectrum -c 1 -C -v";

	int ret = system(command.c_str());

	if (ret != 0) {
		printf("Spectrum command failed\n");
		return -1;
	}

	//printf("Spectrum saved\n");

	return 0;
}