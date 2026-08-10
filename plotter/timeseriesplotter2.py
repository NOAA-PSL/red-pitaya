##########################################################################
##                                                                      ##
## Plots data in file argument, with title in from second argument      ##
##                                                                      ##
##########################################################################

import sys
import matplotlib.pyplot as plt
import numpy as np

filename = sys.argv[1]
title = sys.argv[2]
plotname = f"{title}.png"
print(f"file name is {filename}")
print(f"title is {title}")

x=[]
y=[]

with open(filename, "r") as file:
    data_string = file.read()
  
for line in data_string.splitlines():
  
    number, value = line.split(",")
    x.append(int(number))
    y.append(float(value))


plt.plot(x[9500:10000],y[9500:10000])
plt.title(title)
plt.savefig(f"../plots/{plotname}")
print(f"Saved {plotname}", file=sys.stderr)