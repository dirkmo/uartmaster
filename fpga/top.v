`default_nettype none

module top(
    input  clk100mhz,
    input  reset_n,
    inout  [7:0]  data,
    output [17:0] addr,
    output we_n,
    output oe_n,
    output cs_n,
    input  uart_rx,
    output uart_tx,
    output led1,
    output led2
);

wire [7:0] i_data;
wire [7:0] o_data;
wire clk25mhz;
wire pll_locked;

assign addr[17:16] = 2'b00;
wire we, cs, oe;

assign we_n = ~we;
assign oe_n = we;
assign cs_n = ~cs;

// icepll -i 100 -o 25 -m -f pll.v
pll pll0(clk100mhz, clk25mhz, pll_locked);

genvar i;
generate
    for (i=0; i<8; i=i+1) begin
        SB_IO #(
            .PIN_TYPE(6'b 1010_01),
            // .PULLUP(1'b 0)
        ) io_block_inst0 (
            .PACKAGE_PIN(data[i]),
            .OUTPUT_ENABLE(we),
            .D_OUT_0(o_data[i]),
            .D_IN_0(i_data[i])
        );
    end
endgenerate

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

// heartbeat
reg [23:0] counter;
always @(posedge clk25mhz)
begin
    counter <= counter + 1;
end

assign led1 = counter[23];
assign led2 = 0;

endmodule
