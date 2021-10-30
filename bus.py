#!/usr/bin/env python3
import sys, os
import argparse
import serial


def main():
    parser = argparse.ArgumentParser(description="FPGA Bus communication via serial port")
    parser.add_argument('-f', type=str, help="Source file")
    parser.add_argument('-p', type=str, default='/dev/ttyUSB0', help='serial device')
    parser.add_argument('-o', type=str, default='0')
    args = parser.parse_args()
    print(args)

   
    exit(0)
    if len(sys.argv) < 2:
        print("Error: Missing arguments")
        #exit(1)


    port = "/dev/ttyUSB0"
    try:
        ser = serial.Serial(port)
        ser.write(b'Hallo')
        ser.close()
    except:
        print(f"Cannot open port {port}")
        exit(1)

main()