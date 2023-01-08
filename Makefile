DESIGN=hp300
TARGET=xc5vlx110t-2-ff1136
INTSTYLE=-intstyle silent

PROMGENFLAGS=-w -p mcs -c FF
MAPFLAGS=-cm speed -pr b -c 100 -w
NGDFLAGS=-nt timestamp -uc rtl/$(DESIGN).ucf -uc rtl/ddr2.ucf -dd build
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
	rtl/ddr2/ddr2_chipscope.vhd \
	rtl/ddr2/ddr2_controller.vhd \
	rtl/ddr2/ddr2_ctrl.vhd \
	rtl/ddr2/ddr2_idelay_ctrl.vhd \
	rtl/ddr2/ddr2_infrastructure.vhd \
	rtl/ddr2/ddr2_mem_if_top.vhd \
	rtl/ddr2/ddr2_phy_calib.vhd \
	rtl/ddr2/ddr2_phy_ctl_io.vhd \
	rtl/ddr2/ddr2_phy_dm_iob.vhd \
	rtl/ddr2/ddr2_phy_dq_iob.vhd \
	rtl/ddr2/ddr2_phy_dqs_iob.vhd \
	rtl/ddr2/ddr2_phy_init.vhd \
	rtl/ddr2/ddr2_phy_io.vhd \
	rtl/ddr2/ddr2_phy_top.vhd \
	rtl/ddr2/ddr2_phy_write.vhd \
	rtl/ddr2/ddr2_top.vhd \
	rtl/ddr2/ddr2_usr_addr_fifo.vhd \
	rtl/ddr2/ddr2_usr_rd.vhd \
	rtl/ddr2/ddr2_usr_top.vhd \
	rtl/ddr2/ddr2_usr_wr.vhd \
	rtl/videorom.vhd \
	rtl/hp300.vhd \
	rtl/sdram.vhd \
	rtl/ptm6840.vhd \
	rtl/hif.vhd \
	rtl/fb.vhd \
	rtl/topcat.vhd \
	rtl/dvienc.vhd \
	videoram.vhd \
	chipscope_icon.vhd \
	chipscope_ila.vhd \
	rtl/ps2.vhd


SIMFILES=sim/conversions.vhd \
	sim/gen_utils.vhd \
	sim/bootrom_d_sim.vhd \
	sim/tb_top.vhd

VSIMFILES=sim/ddr2/ddr2_model.v

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
		echo -e "run\n-ifn build/$(DESIGN).prj\n-ifmt mixed\n-top $(DESIGN)\n-ofn build/$(DESIGN)\n-ofmt NGC\n-p $(TARGET)\n-opt_mode speed\n-opt_level 1\n" >$@

build/$(DESIGN).ngc:  $(FILES) $(CPU_FILES) Makefile build/$(DESIGN).xst
		xst -ifn build/$(DESIGN).xst

build/$(DESIGN).jed: build/$(DESIGN).ncd
		hprep6 -i top

build/$(DESIGN).prj: Makefile
		mkdir -p build
		rm -f build/$(DESIGN).prj
		IFS=" " echo " $(FILES) $(CPU_FILES)"|sed 's/ \([^ ]*\)/vhdl work \1\n/g' >>build/$(DESIGN).prj

clean:
		rm -rf build work xst unisim netlist.lst top.*\
		$(DESIGN)_map.xrpt $(DESIGN)_par.xrpt \
		flashsim_tb output.txt xilinx_device_details.xml _xmsgs xlnx_auto_*xdb \
		$(DESIGN)_build.xml $(DESIGN)_pad.csv

#$(DESIGN)_tb.ghw:	$(FILES) $(SIMFILES) Makefile
#		rm -rf work unisim
#		mkdir -p work unisim
#		ghdl -c -g -Punisim --workdir=work src/*.vhd sim/*.vhd -r $(DESIGN)_tb --stop-time=500us --wave=work/$(DESIGN).ghw

modelsim:
	rm -rf work
	vlib work
	vcom -2008 -vopt -O1 -suppress 8891 $(CPU_FILES)
	vcom -2008 -vopt -O5 -suppress 8891 $(FILES) $(SIMFILES)
	vlog -vopt -O5 -suppress 2902,8891,13388 +incdir+. +define+x512Mb +define+sg5 +define+x16 $(VSIMFILES)
	vsim -t ps -vopt +notimingchecks work.tb_top $(VSIM_ARGS) -do sim/sim.do -suppress 1127,8891

modelsim_dvienc:
	rm -rf work
	vlib work
	vcom -2008 -vopt -O5 rtl/dvienc.vhd sim/tb_dvienc.vhd
	vsim work.tb_dvienc $(VSIM_ARGS) -do sim/sim_dvienc.do -suppress 1127

modelsim_ps2:
	rm -rf work
	vlib work
	vcom -2008 -vopt -O5 rtl/ps2.vhd sim/tb_ps2.vhd
	vsim work.tb_ps2 $(VSIM_ARGS) -do sim/sim_ps2.do -suppress 1127

download: build/$(DESIGN).bit
	echo -e "setmode -bs\nsetcable -p auto\nidentify\nassignfile -p 5 -file build/$(DESIGN).bit\nprogram -p 5\nquit" >build/impact.txt
	impact -batch build/impact.txt
