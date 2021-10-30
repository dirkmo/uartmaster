.PHONY: all clean sim wave iverilog

UNAME := $(shell uname -s)

VERILATOR_OUTPUTDIR = verilator

INCDIR=-I$(VERILATOR_OUTPUTDIR) -I/usr/share/verilator/include

DEFINES=+define+SIM=1

VFLAGS = --cc -CFLAGS "$(CXXFLAGS)" $(LDFLAGS) -trace --exe $(INCDIR) --Mdir $(VERILATOR_OUTPUTDIR) $(DEFINES) -O0
GTKWAVE := gtkwave
ifeq ($(UNAME),Darwin)
VFLAGS += --compiler clang
GTKWAVE := /Applications/gtkwave.app/Contents/MacOS/gtkwave-bin
endif

CXXFLAGS=-g -Wall
LDFLAGS=#-LDFLAGS

CXXFLAGS += -DTRACE_ON

CPPSRC=sim.cpp uart.cpp
VERILOGSRC=../rtl/UartMasterSlave.v ../rtl/UartProtocol.v ../rtl/uart_rx.v ../rtl/uart_tx.v ../rtl/fifo.v

all: top

verilator: $(CPPSRC) $(VERILOGSRC)
	verilator $(VFLAGS) $(VERILOGSRC) $(CPPSRC)

top: verilator
	make OPT_FAST="" -C $(VERILATOR_OUTPUTDIR) -j -f VUartMasterSlave.mk

sim: top
	$(VERILATOR_OUTPUTDIR)/VUartMasterSlave -t

wave: sim
	gtkwave sim.gtkw &

iverilog:
	iverilog -s UartMasterSlave *.v

clean:
	rm -f trace.vcd a.out
	rm -f $(VERILATOR_OUTPUTDIR)/*
	-rm -r $(VERILATOR_OUTPUTDIR)

