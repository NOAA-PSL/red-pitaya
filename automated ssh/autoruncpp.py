
##########################################################################
## Run local red pitaya API scripts without copying or ssh into machine ##
## Takes file to be ran, optional -dest filename to save data to        ##
## Saves all data to ./file/                                            ##
## python ./autoruncpp.py [-h] [-dest] filepath                         ##
##   ex. Python ./autoruncpp.py cpp_feedback_loop.cpp                   ##
## This will create a file with a dated name in the data folder of the  ##
## repo. Otherwise, input an optional file name.                        ##
##########################################################################

import os
import sys
import argparse
import subprocess
from datetime import datetime

pscp = r"C:\Program Files\PuTTY\pscp.exe"
plink = r"C:\Program Files\PuTTY\plink.exe"

remote_dir = "/root/radar"
ssh_host = "root@rp-f0f84f.local"
ssh_user = "root"
ssh_pass = "root"

parser = argparse.ArgumentParser(description='Run Red Pitaya program over SSH')
parser.add_argument('filepath', action="store", type=str, help='filepath of script to be ran')
parser.add_argument('output', action="store", type=int, help=' 1 for output spectrum or 2 for raw voltage file')
parser.add_argument('-dest', help='name of new destination file')

args = parser.parse_args()

if not os.path.exists(args.filepath):
    print(f"Error: Local script file not found at {args.filepath}")
    sys.exit()
   
#get file name without cpp   
cpp_file = os.path.basename(args.filepath)
program = os.path.splitext(cpp_file)[0]
   
# Check for Makefile
makefile = os.path.join(os.path.dirname(args.filepath), "Makefile")
if not os.path.exists(makefile):
    print("Error: Makefile not found")
    sys.exit()


if (output == 1): process = "raw_voltage_"
else process = "spectrum_"

#construct destination filepath
if args.dest is None:

    now = datetime.now()
    time = now.strftime("%Y-%m-%d_%H-%M-%S")
    destname = f"{process}{time}.txt"
    destpath = f"../data/{destname}"
    
else:
    destpath = f"../data/{args.dest}"
    
#copy cpp file and makefile over to red pitaya
for file in [args.filepath, makefile]:
    cmd = [
        pscp,
        "-pw",
        ssh_pass,
        file,
        f"{ssh_host}:{remote_dir}/"
    ]
    
    result = subprocess.run(cmd)

    if result.returncode != 0:
        print("File copy failed")
        sys.exit()

#connect to Red Pitaya and run script 
remote_cmd = (
    f"cd {remote_dir} && "
    f"make -s {program} && "
    f"./{program}"
)
command = [
    plink,
    "-ssh",
    ssh_host,
    "-batch",
    "-pw", ssh_pass, 
    remote_cmd
    ]

with open(destpath, "w") as output_file:
    result = subprocess.run(
        command,
        stdout = output_file,
        stderr = subprocess.PIPE,
        text=True
    )
print("plink finished")
print("return code:", result.returncode)
print("stderr:", result.stderr)
    
if result.returncode == 0:
    print(f"Red Pitaya run success. Output saved to {destpath}.")
else:
    print(f"Error occurred (exit code {result.returncode}):")
    print(result.stderr)
    




