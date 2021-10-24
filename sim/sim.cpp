#include <stdint.h>
#include <string.h>
#include <verilated_vcd_c.h>
#include "VUartMaster.h"
#include "VUartMaster_UartMaster.h"
#include "verilated.h"
#include "uart.h"

using namespace std;

VerilatedVcdC *pTrace = NULL;
VUartMaster *pCore;

uint64_t tickcount = 0;
uint64_t ts = 1000;

uint8_t mem[0x10000];

void handle(VUartMaster *pCore);


void opentrace(const char *vcdname) {
    if (!pTrace) {
        pTrace = new VerilatedVcdC;
        pCore->trace(pTrace, 99);
        pTrace->open(vcdname);
    }
}

void tick() {
    tickcount += ts;
    if ((tickcount % (ts*2)) == 0) {
        pCore->i_clk = !pCore->i_clk;
    }
    pCore->eval();
    if(pTrace) pTrace->dump(static_cast<vluint64_t>(tickcount));
}

void fasttick(int n) {
    n = n*2;
    while (n--) {
        handle(pCore);
        tick();
    }
}

void reset() {
    pCore->i_reset = 1;
    fasttick(4);
    pCore->i_reset = 0;
}

void handle(VUartMaster *pCore) {
    static int uart_wait = 0;
    static int clk = -1;
    if (clk != pCore->i_clk && pCore->i_clk) {
        if (pCore->o_cs) {
            if (pCore->o_we) {
                mem[pCore->o_addr] = pCore->o_data;
                printf("mem write: %04x <-- %02x\n", pCore->o_addr, mem[pCore->o_addr]);
            } else {
                pCore->i_data = mem[pCore->o_addr];
                printf("mem read: %04x --> %02x\n", pCore->o_addr, mem[pCore->o_addr]);
            }
        } else {
            pCore->i_data = 0;
        }
        pCore->i_ack = pCore->o_cs;
    }
    clk = pCore->i_clk;
    
    int rxbyte;
    int ret = uart_handle(&rxbyte);
    if (ret) {
        printf("uart: '%c'\n", rxbyte);
    }
}

int main(int argc, char *argv[]) {
    Verilated::traceEverOn(true);
    pCore = new VUartMaster();

#if defined(TRACE_ON)
    opentrace("trace.vcd");
#endif

    uart_init(&pCore->i_uart_rx, &pCore->o_uart_tx, &pCore->i_clk, pCore->UartMaster->SYS_FREQ/pCore->UartMaster->BAUDRATE);

    reset();
    for ( int i = 0; i < sizeof(mem); i++ ) {
        mem[i] = i & 0xff;
    }

    uart_send("L1234RWa4");

    while(tickcount < 100000 * ts) {
        handle(pCore);
        tick();
    }

    pCore->final();
    delete pCore;

    if (pTrace) {
        pTrace->close();
        delete pTrace;
    }

    return 0;
}
