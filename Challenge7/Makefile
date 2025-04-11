
CC=gcc
CFLAGS=-lm

TARGET=neuron
SRC=neuron_trainable_all_gates_training_logs.c

FUNC?=all
SKIP?=1
DELAY?=5
GATES=and or nand nor xor

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS)

run: $(TARGET)
	./$(TARGET) --func $(FUNC)

plots:
	@for gate in $(GATES); do \
		echo "Generating static plot for $$gate..."; \
		gnuplot -e "gate='$$gate'" plot_training.gnuplot; \
	done

animations:
	@for gate in $(GATES); do \
		echo "Generating animation for $$gate with SKIP=$(SKIP) DELAY=$(DELAY)..."; \
		gnuplot -e "gate='$$gate'; SKIP=$(SKIP)+0; DELAY=$(DELAY)+0" animate_training.gnuplot; \
	done

clean:
	rm -f $(TARGET) *.png *.gif *.csv

help:
	@echo "Makefile Options:"
	@echo "  make            - Compile the neuron program"
	@echo "  make run        - Train all gates"
	@echo "  make plots      - Generate static plots for each gate"
	@echo "  make animations SKIP=n DELAY=m - Generate animations skipping every n frames with m delay (default SKIP=1, DELAY=5)"
	@echo "  make clean      - Remove all generated files"
