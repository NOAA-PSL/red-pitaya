#!/usr/bin/python3
import numpy as np
import sys

sys.path.append(
    r"D:\Red Pitaya\red-pitaya\rpsa_client-3.00-803-d383a7e37-win\python_lib"
)

import streaming

# Simple callback to collect data
class DataCollector(streaming.ADCCallback):
    def __init__(self):
        super().__init__()
        self.data_ch1 = []
        self.data_ch2 = []

    def receivePack(self, client, pack):
        """Called automatically when new data arrives"""
        self.data_ch1.extend(pack.channel1.raw)
        self.data_ch2.extend(pack.channel2.raw)
        print(f"Received {len(pack.channel1.raw)} samples")

# Create streaming client
client = streaming.ADCStreamClient()
collector = DataCollector()
client.setReceiveDataFunction(collector.__disown__())

# Connect to Red Pitaya (auto-discovery)
print("Connecting to Red Pitaya...")
if not client.connect():
    print("ERROR: Cannot connect!")
    exit(1)

# Configure streaming
client.sendConfig('adc_decimation', '256')      # 125 MS/s ÷ 256 = 488 kS/s
client.sendConfig('channel_state_1', 'ON')      # Enable channel 1
client.sendConfig('channel_state_2', 'ON')      # Enable channel 2

# Start streaming
print("Starting acquisition...")
client.startStreaming()

# Wait for completion (or use Ctrl+C to stop)
try:
    client.wait()
except KeyboardInterrupt:
    print("\nStopping...")

# Show results
print(f"\nCollected {len(collector.data_ch1):,} samples per channel")
print(f"Channel 1 range: {min(collector.data_ch1)} to {max(collector.data_ch1)}")
print(f"Channel 2 range: {min(collector.data_ch2)} to {max(collector.data_ch2)}")