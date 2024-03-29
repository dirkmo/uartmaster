`default_nettype none

module UartProtocol (
    input i_clk,
    input i_reset,
    input i_ack,
    input [7:0] i_dat,
    output [7:0] o_dat,
    output [15:0] o_addr,
    output o_we,
    output o_cs,

    input i_uart_received_pulse,
    input [7:0] i_uart_dat,

    input i_uart_send_ready,
    output o_uart_send_pulse,
    output [7:0] o_uart_dat,

    output o_reset
);

// Protocol:
// L<addr>: Set address
// R: Read from address and auto-increment
// W: Write to address and auto-increment
// ,: assert reset
// .: release reset

// "L1a00W4d00": Writes 0x4d 0x00 to address 0x1a00, 0x1a01
// "L1234RR":    Reads two bytes from address 0x1234, 0x1235


// hex characters are lower case

localparam
    MODE_ADDRESS = 0,
    MODE_WRITE   = 1;

reg r_mode;

// ascii values L: 76, R: 82, W: 87, 0: 48, a: 97

wire address_pulse = i_uart_received_pulse && (i_uart_dat == "L");
wire write_pulse = i_uart_received_pulse && (i_uart_dat == "W");
wire perform_read_pulse = i_uart_received_pulse && (i_uart_dat == "R");

always @(posedge i_clk)
begin
    if (address_pulse || i_reset)
        r_mode <= MODE_ADDRESS;
    if (write_pulse)
        r_mode <= MODE_WRITE;
end

wire nibble_valid;

reg [1:0] r_nibble_idx;
always @(posedge i_clk)
begin
    if (address_pulse || write_pulse || perform_write_pulse || perform_read_pulse || i_reset)
        r_nibble_idx <= 0;
    else if (nibble_valid)
        r_nibble_idx <= r_nibble_idx + 1'b1;
end

// 76 ('L') 01001100
// 87 ('W') 01010111
// 82 ('R') 01010010
wire nibble_09_valid = (i_uart_dat[7:4] == 4'b0011); // 48 ('0') = 0011 0000
wire nibble_af_valid = (i_uart_dat[7:4] == 4'b0110); // 97 ('a') = 0110 0000
wire [3:0] nibble    = nibble_af_valid ? (i_uart_dat[3:0]+4'd9) : i_uart_dat[3:0];

assign nibble_valid = i_uart_received_pulse && (nibble_09_valid || nibble_af_valid);

wire perform_write_pulse = (r_mode == MODE_WRITE) && nibble_valid && r_nibble_idx[0];
reg [7:0] r_data;
always @(posedge i_clk)
begin
    if (r_mode == MODE_WRITE) begin
        if (nibble_valid) begin
            case (r_nibble_idx[0])
                0: r_data[7:4] <= nibble[3:0];
                1: r_data[3:0] <= nibble[3:0];
            endcase
        end
    end
    if (read_done_pulse) begin
        r_data <= i_dat;
    end
end

// write to bus state machine
reg r_wstate;
always @(posedge i_clk)
begin
    case (r_wstate)
        0: if (perform_write_pulse) r_wstate <= 1;
        1: if (i_ack) r_wstate <= 0;
    endcase
    if (i_reset) begin
        r_wstate <= 0;
    end
end

wire write_done_pulse = r_wstate && i_ack;


// read from bus state machine
reg [1:0] r_rstate;
always @(posedge i_clk)
begin
    case (r_rstate)
        0: if (perform_read_pulse) r_rstate <= 1;
        1: if (i_ack)              r_rstate <= 2;
        2: if (i_uart_send_ready)  r_rstate <= 3;
        3: if (i_uart_send_ready)  r_rstate <= 0;
    endcase
    if(i_reset) begin
        r_rstate <= 0;
    end
end

wire [3:0] nibble_read  = (r_rstate == 2) ? r_data[7:4] : r_data[3:0];
wire [7:0] ascii_nibble = { 4'd0, nibble_read } + ((nibble_read > 9) ? 8'd87 : 8'd48);

assign o_uart_dat = ascii_nibble;

assign o_uart_send_pulse = r_rstate[1] && i_uart_send_ready;

wire read_done_pulse = (r_rstate==1) && i_ack;


reg [15:0] r_address;
always @(posedge i_clk)
begin
    if (r_mode == MODE_ADDRESS) begin
        if (nibble_valid) begin
            case (r_nibble_idx)
                0: r_address[15:12] <= nibble[3:0];
                1: r_address[11:8] <= nibble[3:0];
                2: r_address[7:4] <= nibble[3:0];
                3: r_address[3:0] <= nibble[3:0];
            endcase
        end
    end
    if (read_done_pulse || write_done_pulse) begin
        // auto-incrementr_data <= i_dat;
        r_address <= r_address + 1'b1;
    end
end

// bus interface
assign o_cs = r_wstate || (r_rstate == 1);
assign o_we = r_wstate;
assign o_addr = r_address;
assign o_dat = r_data;


// reset generation
// assert reset:  ','  8'b0010_1100'
// release reset: '.'  8'b0010_1110'

reg r_reset;
always @(posedge i_clk)
    if (i_uart_received_pulse) begin
        if ({i_uart_dat[7:2],i_uart_dat[0]} == 7'b0010110)
        begin
            r_reset <= ~i_uart_dat[1];
        end
    end

assign o_reset = r_reset;

endmodule
