#!/usr/bin/env python3

# Send data on UART channel 1 to FPGA (ascii chars with bit #7 set)
# Assert reset: ","
# Release reset: "."
# "L": select address register
# "W": write following data to address specified in address register, autoincrement address
# "R": read byte from address specified in address register, autoincrement address
# 0-9,a-f: interpreted as hex numbers (lower case only!)
# Example strings:
# Write bytes 0x12 0xab to address 0x1234, 0x1235: "L1234W12ab"
# Read 3 bytes starting from address 0xabcd: "LabcdRRR"
# Assert reset, write byte to address 0x1234, release reset: ",L1234W12ab."


import argparse
import serial
import sys

def connect_serial(port):
    global ser
    try:
        ser = serial.Serial(port, baudrate=115200)
    except:
        print(f"ERROR: Cannot open port {port}")
        exit(1)

parser = argparse.ArgumentParser(description="Transmit data to FPGA system using channel 1 of the UartMaster protocol.")
parser.add_argument('-p', type=str, metavar='<device>', default='/dev/ttyUSB0', help='Serial device.')
parser.add_argument('-v', action='store_const', const=True, default=False, help='Print progess to stdout.')
parser.add_argument('string',help="String to send to FPGA")
args = parser.parse_args()

connect_serial(args.p)

ba=bytearray(args.string,encoding='ascii')
data = bytearray([(b | 0x80) for b in ba])

for i,d in enumerate(data):
    if args.v:
        sys.stdout.write(f"\rProgress: {100*i//len(data)} %")
    ser.write(d.to_bytes(length=1,byteorder='little'))

if args.v:
    print("\rProgress: Done.")
