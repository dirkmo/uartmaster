#!/usr/bin/env python3
import sys, os
import argparse
import serial

ser = 0
port = "/dev/ttyUSB0"

def connect_serial():
    global ser
    try:
        ser = serial.Serial(port, baudrate=115200)
        # ser.write(b'Hallo')
    except:
        print(f"ERROR: Cannot open port {port}")
        exit(1)


parser = argparse.ArgumentParser(description="Transmit file to FPGA system using channel 1 of the UartMaster protocol.")
parser.add_argument('-p', type=str, metavar='<device>', default='/dev/ttyUSB0', help='Serial device.')
parser.add_argument('-f', type=str, metavar='<file>', default="", help='File name for reading/writing.')
parser.add_argument('-o', type=str, metavar='<offset>', default="0", help='Offset address in device.')
parser.add_argument('-c', action='store_const', const=True, default=False, help='Perform readback after write.')
# parser.add_argument('-r', type=str, default=False, help='Perform read from device.')
parser.add_argument('-w', action='store_const', const=True, default=False, help='Perform write to device.')
parser.add_argument('-R', action='store_const', const=True, default=False, help='Reset FPGA')
args = parser.parse_args()



if args.f != "":
    print(f"Reading {args.f} with {os.path.getsize(args.f)} bytes")
    with open(args.f,'rb') as f:
        bytes = f.read()

connect_serial()

offset = args.o.upper()
if (offset[0:2] == '0X'):
    addr = int(offset[2:],16)
else:
    addr = int(args.o)

channel = 1 # or 0

saddr = f'{addr:04x}L'[::-1]

if args.R:
    sys.stdout.write("Asserting reset...")
    rba = bytearray([ord(',') | 0x80])
    print(rba)
    ser.write(rba)
    print("done.")

if (args.f != "") and (args.w == 1):
    sys.stdout.write("Writing data to device...")

    data = saddr + "W"

    for b in bytes:
        nibbles = f"{b:02x}"[::-1]
        data += nibbles

    if channel == 0:
        ba = bytearray(data,'ascii')
    else:
        iba = [(ord(b) | 0x80) for b in data]
        ba = bytearray(iba)

    ser.write(ba)
    print("done.")
    if args.c == 1:
        # readback tbd
        pass

import time
time.sleep(1)

if args.R:
    sys.stdout.write("Releasing reset...")
    rba = bytearray([ord('.') | 0x80])
    print(rba)
    ser.write(rba)
    print("done.")
