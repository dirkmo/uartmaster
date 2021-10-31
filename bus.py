#!/usr/bin/env python3
import sys, os
import argparse
import serial

ser = 0
port = "/dev/ttyUSB0"

def handle_args():
    global port
    parser = argparse.ArgumentParser(description="FPGA Bus communication via serial port")
    parser.add_argument('-p', type=str, default='/dev/ttyUSB0', help='serial device')
    args = parser.parse_args()
    port = args["p"]

def connect_serial():
    global ser
    try:
        ser = serial.Serial(port)
        # ser.write(b'Hallo')
        # ser.close()
    except:
        print(f"ERROR: Cannot open port {port}")
        exit(1)

def main():
    handle_args()
    connect_serial()



   



main()