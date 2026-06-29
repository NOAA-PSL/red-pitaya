##########################################################################
##                                                                      ##
## Plots data in file argument, with title in from second argument      ##
##                                                                      ##
##########################################################################

import sys
import matplotlib.pyplot as plt

filename = sys.argv[1]
title = sys.argv[2]
plotname = f"{title}.png"
print(f"file name is {filename}")
print(f"title is {title}")

with open(filename, "r") as file:
    data_string = file.read()
    
data = [float(datapt) for datapt in data_string.split()]

plt.plot(data)
plt.title(title)
plt.savefig(f"./plots/{plotname}")
print(f"Saved {plotname}", file=sys.stderr)