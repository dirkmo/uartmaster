# uartmaster
The Uart Master receives characters from UART and performs read / writes
accordingly. The purpose is to get easy access to the data bus via uart
for development.

The UartMaster has to registers: The address register and the data register.

If the UartMaster receives (case sensitive!)
- a 'L' character, the address register is selected
- a 'W' character, the data register is selected
- lower case hex character (0-9,a-f), it will write the nibble it to the
selected register, and then advances to the next nibble of that register.
- a 'R' character is received, it reads 8-bit of data from the configured address,
converts it to a "two-nibbled hex-string", like "6d" and sends it over the Uart.

The address register is 16-bit wide. If it has been selected, the first write goes
to the lowest nibble of the register (addr[3:0]), the next write goes into addr[7:4].

The data register is 8-bit wide, the lower nibble is also written first. If two
nibbles have been written to the register, the data is written onto the bus with
the configured address.

Each read / write does an auto-increment of the address register.
