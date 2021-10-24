module top(
    input  clk100mhz,
    input  reset_n,
    inout  [7:0]  data,
    output [17:0] addr,
    output we,
    output oe,
    output cs,
    input  uart_rx,
    output uart_tx
);

wire [7:0] i_data;
wire [7:0] o_data;
wire clk25mhz;
wire pll_locked;

assign addr[17:16] = 2'b00;
assign oe = ~we;

// icepll -i 100 -o 25 -m -f pll.v
pll pll0(clk100mhz, clk25mhz, pll_locked);

SB_IO #(
    .PIN_TYPE(6'b 1010_01),
    // .PULLUP(1'b 0)
) io_block_inst0 (
    .PACKAGE_PIN(data),
    .OUTPUT_ENABLE(we),
    .D_OUT_0(o_data),
    .D_IN_0(i_data)
);

UartMaster master(
    .i_clk(clk25mhz),
    .i_reset(~reset_n),
    .i_data(i_data),
    .o_data(o_data),
    .o_addr(addr[15:0]),
    .i_ack(1'b1),
    .o_we(we),
    .o_cs(cs),
    .i_uart_rx(uart_rx),
    .o_uart_tx(uart_tx)
);

endmodule
