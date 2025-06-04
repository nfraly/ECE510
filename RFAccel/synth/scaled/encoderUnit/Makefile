all: sim

sim:
	vlog spike_encoder.v tb_spike_encoder.v
	vsim -c -do "run -all; quit" tb_spike_encoder

clean:
	rm -f transcript *.log *.vcd work

