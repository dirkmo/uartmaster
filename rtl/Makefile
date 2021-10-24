PROJ = top
PIN_DEF = UartMaster.pcf
DEVICE = hx8k
SOURCES = top.v UartMaster.v UartProtocol.v uart_rx.v uart_tx.v
all: $(PROJ).rpt $(PROJ).bin

%.blif: %.v
	yosys -p 'synth_ice40 -top top -blif $@' $(SOURCES)

%.asc: $(PIN_DEF) %.blif
	arachne-pnr -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^ -P ct256

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

prog: $(PROJ).bin
	sudo iceprogduino $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprogduino $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).bin $(PROJ).rpt

.PHONY: all prog clean
