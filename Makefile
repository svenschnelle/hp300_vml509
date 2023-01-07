DESIGN=hp300
TARGET=xc5vlx110t-2-ff1136
INTSTYLE=-intstyle silent

PROMGENFLAGS=-w -p mcs -c FF
MAPFLAGS=-cm area -pr b -c 100 -w
NGDFLAGS=-nt timestamp -uc rtl/$(DESIGN).ucf -dd build
PARFLAGS=-w -ol std

CPU_FILES=rtl/68K30L/wf68k30L_pkg.vhd \
	rtl/68K30L/wf68k30L_opcode_decoder.vhd

FILES=	rtl/68K30L/wf68k30L_pkg.vhd \
	rtl/68K30L/wf68k30L_address_registers.vhd \
	rtl/68K30L/wf68k30L_alu.vhd \
	rtl/68K30L/wf68k30L_bus_interface.vhd \
	rtl/68K30L/wf68k30L_control.vhd \
	rtl/68K30L/wf68k30L_data_registers.vhd \
	rtl/68K30L/wf68k30L_exception_handler.vhd \
	rtl/68K30L/wf68k30L_top.vhd \
	rtl/bootrom.vhd \
	rtl/videorom.vhd \
	rtl/hp300.vhd \
	rtl/sdram.vhd \
	rtl/ptm6840.vhd \
	rtl/hif.vhd \
	rtl/fb.vhd \
	rtl/topcat.vhd \
	videoram.vhd \
	sram.vhd


SIMFILES=sim/conversions.vhd \
	sim/gen_utils.vhd \
	sim/tb_top.vhd


.PHONY: sim mkbuilddir

all: build/$(DESIGN).mcs

sim: $(DESIGN)_tb.ghw
		gtkwave work/$(DESIGN).ghw sim/$(DESIGN)_tb.sav

build/$(DESIGN).mcs:		build/$(DESIGN).bit
		promgen $(PROMGENFLAGS) -o $@ -u 0 $< -s 4096

build/$(DESIGN).bit:		build/$(DESIGN)_par.ncd
		bitgen -w $< $@

build/$(DESIGN)_par.ncd:	build/$(DESIGN).ncd
		par $(PARFLAGS) $< $@

build/$(DESIGN).ncd:		build/$(DESIGN).ngd
		map -p $(TARGET) $(MAPFLAGS) -o $@ $<
		#cpldfit -p $(TARGET) $(CPLDFITFLAGS) $<
build/$(DESIGN).ngd:		build/$(DESIGN).ngc rtl/$(DESIGN).ucf
		ngdbuild -p $(TARGET) $(NGDFLAGS) $< $@

build/$(DESIGN).xst:  build/$(DESIGN).prj Makefile
		echo -e "run\n-ifn build/$(DESIGN).prj\n-ifmt mixed\n-top $(DESIGN)\n-ofn build/$(DESIGN)\n-ofmt NGC\n-p $(TARGET)\n-opt_mode Area\n-opt_level 2\n" >$@

build/$(DESIGN).ngc:  $(FILES) Makefile build/$(DESIGN).xst
		xst -ifn build/$(DESIGN).xst

build/$(DESIGN).jed: build/$(DESIGN).ncd
		hprep6 -i top

build/$(DESIGN).prj: Makefile
		mkdir -p build
		rm -f build/$(DESIGN).prj
		IFS=" " echo " $(FILES)"|sed 's/ \([^ ]*\)/vhdl work \1\n/g' >>build/$(DESIGN).prj

clean:
		rm -rf build work xst unisim netlist.lst top.*\
		$(DESIGN)_map.xrpt $(DESIGN)_par.xrpt \
		flashsim_tb output.txt xilinx_device_details.xml _xmsgs xlnx_auto_*xdb \
		$(DESIGN)_build.xml $(DESIGN)_pad.csv

download:	build/$(DESIGN).bit
		xc3sprog $<

#$(DESIGN)_tb.ghw:	$(FILES) $(SIMFILES) Makefile
#		rm -rf work unisim
#		mkdir -p work unisim
#		ghdl -c -g -Punisim --workdir=work src/*.vhd sim/*.vhd -r $(DESIGN)_tb --stop-time=500us --wave=work/$(DESIGN).ghw

modelsim:
	rm -rf work
	vlib work
#	vmap -modelsim_quiet xilinxcorelib_ver C:/Modeltech_pe_edu_10.4a/xilinxcorelib/xilinxcorelib_ver
#	vmap -modelsim_quiet unisims_ver C:/Modeltech_pe_edu_10.4a/xilinxcorelib/unisims_ver
	vcom -source -93 -vopt -explicit -work xilinxcorelib  /opt/Xilinx/14.7/ISE_DS/ISE/vhdl/src/XilinxCoreLib/BLK_MEM_GEN_V7_3.vhd
	vcom -2008 -vopt -O1 $(CPU_FILES)
	vcom -2008 -vopt -O5 $(FILES) $(SIMFILES)
	vsim work.tb_top $(VSIM_ARGS) -do sim/sim.do -suppress 1127
