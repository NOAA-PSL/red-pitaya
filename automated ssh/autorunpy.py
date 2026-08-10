
##########################################################################
## Run local red pitaya API scripts without copying or ssh into machine ##
## Takes file to be ran, optional -dest filename to save data to        ##
## Saves all data to ./file/                                            ##
## python ./autorun.py [-h] [-dest] filepath                            ##
##   ex. Python ./autorun.py api_feedback_loop.py                       ##
## This will create a file with a dated name in the data folder of the  ##
## repo. Otherwise, input an optional file name.                        ##
##########################################################################

import os
import sys
import argparse
import subprocess
from datetime import datetime

ssh_host = "root@rp-f0f84f.local"
ssh_user = "root"
ssh_pass = "root"

parser = argparse.ArgumentParser(description='Run Red Pitaya program over SSH')
parser.add_argument('filepath', action="store", type=str, help='filepath of script to be ran')
parser.add_argument('-dest', help='name of new destination file')

args = parser.parse_args()

if not os.path.exists(args.filepath):
    print(f"Error: Local script file not found at {args.filepath}")
    sys.exit()

#construct filepath
if args.dest is None:

    radar = 'radarx'
    now = datetime.now()
    time = now.strftime("%Y-%m-%d_%H-%M-%S")
    destname = f"{radar}{time}.txt"
    destpath = f"../data/{destname}"
    
else:
    destpath = f"../data/{args.dest}"
    
#connect to Red Pitaya and run script  
command = [
    r"C:\Program Files\PuTTY\plink.exe",
    "-ssh",
    "root@rp-f0f84f.local",
    "-batch",
    "-pw", ssh_pass, 
    "PYTHONPATH=/opt/redpitaya/lib/python python3 -"
    ]
    

with open(args.filepath, "rb") as script_file, open(destpath, "w") as output_file:
    result = subprocess.run(
        command,
        stdin = script_file,
        stdout = output_file,
        stderr = subprocess.PIPE
    )
    
if result.returncode == 0:
    print(f"Red Pitaya run success. Output saved to {destpath}.")
else:
    print(f"Error occurred (exit code {result.returncode}):")
    print(result.stderr)
    




