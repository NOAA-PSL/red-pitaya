#include "include/acq_library.h"
#include <iostream>

int main() {
	
	RPContext ctx;
	
	/* set up for acq, return if failure*/
	int status = rp.set(ctx);
	if (status != 0) return 1;
	
	/*start acq signal*/
	rp_acq();
	
	/*print voltages*/
	print_voltages(ctx);
	
	/* realease rp hardware */
	rp_finish(ctx);
	
	return 0;
	
}
