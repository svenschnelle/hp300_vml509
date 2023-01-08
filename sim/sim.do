set NumericStdNoWarnings 1
set StdArithNoWarnings 1
#delete wave *
#force /tb_top/hp300/ps2_key 0 0ns, 11'h65a 4000ms

add wave -radix hex /tb_top/led_s
add wave -radix hex /tb_top/dut/clk_i
add wave -radix hex /tb_top/dut/clk_s
add wave -radix hex /tb_top/dut/clk200_n
add wave -radix hex /tb_top/dut/clk200_p
add wave -radix hex /tb_top/dut/clk_s
add wave -radix hex /tb_top/dut/reset_s
add wave -radix hex /tb_top/dut/cpu_i/PC

add wave -group cpu -radix hex -r /tb_top/dut/cpu_i/*
add wave -group ddr2 -r /tb_top/dut/ddr2_*
#add wave -group ddr2_model -r /tb_top/ddr2_model_i0/*
add wave -group -r ddr2_cont /tb_top/dut/ddr2_i/*
#add wave -group hp300 /tb_top/dut/addr_decode/bus_state_s

#add wave -group hp300 /tb_top/dut/addr_decode/bus_state_s
add wave -group hp300 /tb_top/dut/sdram_read_req_s
add wave -group hp300 /tb_top/dut/sdram_read_ack_s
add wave -group hp300 /tb_top/dut/sdram_write_req_s
add wave -group hp300 /tb_top/dut/sdram_write_ack_s
add wave -group hp300 /tb_top/dut/sdram_read_data_s
add wave -group hp300 /tb_top/dut/rd_data_valid_s
add wave -group hp300 /tb_top/dut/rd_data_fifo_out_s
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
add wave -group bootrom -r -radix hex /tb_top/bootrom_i/*
add wave -group dvi /tb_top/dut/dvi_xclk_n
add wave -group dvi /tb_top/dut/dvi_xclk_p
add wave -group dvi -radix hex /tb_top/dut/dvi_d
add wave -group dvi /tb_top/dut/dvi_de
add wave -group dvi /tb_top/dut/dvi_h
add wave -group dvi /tb_top/dut/dvi_v
add wave -group dvi /tb_top/dut/dvi_reset_b
add wave -group dvi /tb_top/dut/iic_sda_video
add wave -group dvi /tb_top/dut/iic_scl_video

#add wave -radix hex -group hif /tb_top/hp300/human_interface/*
add wave -group ptm -radix hex -r /tb_top/dut/ptm_i/*
#add wave -group hif -radix hex -r /tb_top/dut/hif_i/*
#add wave  -group fb -radix hex -r /tb_top/dut/fb_i/topcat_i/*
#add wave -group bootrom -radix hex -r /tb_top/bootrom_i/*
configure wave -namecolwidth 355 
configure wave -valuecolwidth 208 
configure wave -justifyvalue left
configure wave -signalnamewidth 0
update
run 5ms
wave zoom full
#quit
#mem save -o test.mem -f mti -data binary -addr hex /tb_top/hp300/fb/vram

