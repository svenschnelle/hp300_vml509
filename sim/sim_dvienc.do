quietly set StdArithNoWarnings 1
#delete wave *
#force /tb_top/hp300/ps2_key 0 0ns, 11'h65a 4000ms

add wave -r -radix hex *
configure wave -namecolwidth 355 
configure wave -valuecolwidth 208 
configure wave -justifyvalue left
configure wave -signalnamewidth 0
update
run 1ms
wave zoom full
#quit

