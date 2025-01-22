vlib work

vcom -mixedsvvh -2008 src/rtl/payload_aligner.vhd

vlog -sv src/sim/packet_intf.sv
vlog -sv src/sim/payload_aligner_tb.sv

vsim -voptargs="+acc" work.payload_aligner_tb
add wave -position insertpoint sim:/payload_aligner_tb/dut/inner/*
run -all