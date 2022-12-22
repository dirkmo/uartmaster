#!/usr/bin/env python3
import sys, os
import argparse
import serial
import termios
import tty

ser = 0
port = "/dev/ttyUSB0"

def handle_args():
    global port
    parser = argparse.ArgumentParser(description="FPGA Bus communication via serial port")
    parser.add_argument('-p', type=str, default='/dev/ttyUSB0', help='serial device')
    args = parser.parse_args()
    port = args.p
    

def connect_serial():
    global ser
    try:
        ser = serial.Serial(port)
        # ser.write(b'Hallo')
        # ser.close()
    except:
        print(f"ERROR: Cannot open port {port}")
        exit(1)

def getch():
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(sys.stdin.fileno())
        ch = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    return ch


BSP = "\x7f"
ESC = "\x1b"

def main():
    handle_args()
    connect_serial()

    ch = 0
    while ch != ESC:
        ch = getch()


main()