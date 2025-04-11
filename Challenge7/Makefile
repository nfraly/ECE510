
CC=gcc
CFLAGS=-lm

TARGET=neuron
SRC=neuron_trainable_all_gates_training_logs.c

FUNC?=all
GATES=and or nand nor xor

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) --func $(FUNC)

plots:
	@for gate in $(GATES); do \
		echo "Generating plot for $$gate..."; \
		gnuplot -e "gate='$$gate'" plot_training.gnuplot; \
	done

clean:
	rm -f $(TARGET) *.png *.csv

help:
	@echo "Makefile Options:"
	@echo "  make            - Compile the neuron program"
	@echo "  make run        - Run training for selected gate (default: all gates)"
	@echo "      Example: make run FUNC=nand"
	@echo "  make plots      - Generate all plots from training logs"
	@echo "  make clean      - Remove binary, plots, and output files"
