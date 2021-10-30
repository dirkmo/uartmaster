#include <stdint.h>
#include <string.h>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VUartMasterSlave.h"
#include "VUartMasterSlave_UartMasterSlave.h"
#include "uart.h"

using namespace std;

VerilatedVcdC *pTrace = NULL;
VUartMasterSlave *pCore;

uint64_t tickcount = 0;
uint64_t ts = 1000;

uint8_t mem[0x10000];

void handle(VUartMasterSlave *pCore);


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

void handle(VUartMasterSlave *pCore) {
    static int uart_wait = 0;
    static int clk = -1;
    if (clk != pCore->i_clk && pCore->i_clk) {
        if (pCore->o_master_cs) {
            if (pCore->o_master_we) {
                mem[pCore->o_master_addr] = pCore->o_master_data;
                printf("mem write: %04x <-- %02x\n", pCore->o_master_addr, mem[pCore->o_master_addr]);
            } else {
                pCore->i_master_data = mem[pCore->o_master_addr];
                printf("mem read: %04x --> %02x\n", pCore->o_master_addr, mem[pCore->o_master_addr]);
            }
        } else {
            pCore->i_master_data = 0;
        }
        pCore->i_master_ack = pCore->o_master_cs;
    }
    clk = pCore->i_clk;
    
    int rxbyte;
    int ret = uart_handle(&rxbyte);
    if (ret) {
        if (rxbyte & 0x80) {
            printf("uart ch1: '%c'\n", rxbyte & 0x7f);
        } else {
            printf("uart ch0: '%c'\n", rxbyte);
        }
    }
}

void wait_for_posedge(void) {
    static int clk = -1;
    if (clk != pCore->i_clk && pCore->i_clk) {
        tick();
        handle(pCore);
    }
}

void bus_write(uint16_t addr, uint8_t dat) {
    printf("write!\n");
    wait_for_posedge();
    pCore->i_slave_data = dat;
    pCore->i_slave_addr = addr;
    pCore->i_slave_cs = 1;
    pCore->i_slave_we = 1;
    while(!pCore->o_slave_ack) {
        handle(pCore);
        tick();
    }
    wait_for_posedge();
    pCore->i_slave_data = 0;
    pCore->i_slave_addr = 0;
    pCore->i_slave_cs = 0;
    pCore->i_slave_we = 0;
}

uint8_t bus_read(uint16_t addr) {
    wait_for_posedge();
    pCore->i_slave_addr = addr;
    pCore->i_slave_cs = 1;
    pCore->i_slave_we = 0;
    while(!pCore->o_slave_ack) {
        handle(pCore);
        tick();
    }
    wait_for_posedge();
    pCore->i_slave_data = 0;
    pCore->i_slave_addr = 0;
    pCore->i_slave_cs = 0;
    pCore->i_slave_we = 0;
    return pCore->o_slave_data;
}

int main(int argc, char *argv[]) {
    Verilated::traceEverOn(true);
    pCore = new VUartMasterSlave();

    if (argc > 1) {
        if( string(argv[1]) == "-t" ) {
            printf("Trace enabled\n");
            opentrace("trace.vcd");
        }
    }
    uart_init(&pCore->i_uart_rx, &pCore->o_uart_tx, &pCore->i_clk, pCore->UartMasterSlave->SYS_FREQ/pCore->UartMasterSlave->BAUDRATE);

    reset();
    for ( int i = 0; i < sizeof(mem); i++ ) {
        mem[i] = i & 0xff;
    }

    tick();

    printf("Status: %02x\n", bus_read(0));
    for( const char *c = "abc"; *c; bus_write(1, *c++));
    printf("Status: %02x\n", bus_read(0));

    uart_send(1, "L432aRWa4");

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
