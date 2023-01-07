quietly set StdArithNoWarnings 1
#delete wave *
#force /tb_top/hp300/ps2_key 0 0ns, 11'h65a 4000ms

add wave -radix hex /tb_top/led_s
add wave -radix hex /tb_top/dut/clk_i
add wave -radix hex /tb_top/dut/cpu_i/PC
add wave -group cpu -radix hex -r /tb_top/dut/cpu_i/*
#add wave -group hp300 /tb_top/dut/*
add wave -group hp300 /tb_top/dut/bus_state_s
add wave -group hp300 -radix hex /tb_top/dut/cpu_addr_s
add wave -group hp300 -radix hex /tb_top/dut/cpu_data_in_s
add wave -group hp300 -radix hex /tb_top/dut/cpu_data_out_s
add wave -group hp300 /tb_top/dut/cpu_as_n_s
add wave -group hp300 /tb_top/dut/cpu_rw_n_s
add wave -group hp300 /tb_top/dut/cpu_dsack_n_s
add wave -group hp300 /tb_top/dut/cpu_berr_n_s
add wave -group hp300 /tb_top/dut/ptm_cs_s
#add wave -group hp300 /tb_top/dut/pmmu_cs_s
add wave -group hp300 /tb_top/dut/videorom_cs_s
add wave -group hp300 /tb_top/dut/fb_cs_s
add wave -group hp300 /tb_top/dut/hif_cs_s
add wave -group hp300 /tb_top/dut/bootrom_cs_s
add wave -group sram -r -radix hex /tb_top/dut/sram_i/*
add wave /tb_top/dut/sram_we_s
add wave /tb_top/dut/sram_cs_s
#add wave -radix hex -group hif /tb_top/hp300/human_interface/*
#add wave -group ptm -radix hex -r /tb_top/dut/ptm_i/*
#add wave -group hif -radix hex -r /tb_top/dut/hif_i/*
add wave  -group fb -radix hex -r /tb_top/dut/fb_i/topcat_i/*
#add wave -group bootrom -radix hex -r /tb_top/bootrom_i/*
configure wave -namecolwidth 355 
configure wave -valuecolwidth 208 
configure wave -justifyvalue left
configure wave -signalnamewidth 0
update
run 1000ms
#wave zoom full
#quit
#mem save -o test.mem -f mti -data binary -addr hex /tb_top/hp300/fb/vram

