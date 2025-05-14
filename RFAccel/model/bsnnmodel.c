
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define INPUT_SIZE 256
#define HIDDEN_SIZE 2048
#define OUTPUT_SIZE 256

#define WORDS_INPUT (INPUT_SIZE / 32)
#define WORDS_HIDDEN (HIDDEN_SIZE / 32)
#define WORDS_OUTPUT (OUTPUT_SIZE / 32)

#define THRESHOLD1 (INPUT_SIZE / 2)
#define THRESHOLD2 (HIDDEN_SIZE / 2)

uint8_t accelerator_mem[256 * 1024];

// MMIO and DMA Simulation
void pci_mmio_write(uint32_t offset, uint32_t value) {
    *(uint32_t *)(accelerator_mem + offset) = value;
}
uint32_t pci_mmio_read(uint32_t offset) {
    return *(uint32_t *)(accelerator_mem + offset);
}
void pci_dma_write(uint32_t dst_offset, const void* src, size_t size) {
    memcpy(accelerator_mem + dst_offset, src, size);
}

// Utility functions
int popcount(uint32_t x) {
    int count = 0;
    while (x) { count += x & 1; x >>= 1; }
    return count;
}
int matching_bits(uint32_t *a, uint32_t *b, int words) {
    int sum = 0;
    for (int i = 0; i < words; i++) {
        sum += popcount(~(a[i] ^ b[i]));
    }
    return sum;
}
void bsnn_layer(uint32_t *input, int input_words,
                uint8_t *weight_base, int num_neurons,
                int threshold, uint32_t *output) {
    for (int n = 0; n < num_neurons; n++) {
        uint32_t *weight_ptr = (uint32_t *)(weight_base + n * input_words * 4);
        int match = matching_bits(input, weight_ptr, input_words);
        int fire = (match >= threshold) ? 1 : 0;
        int word = n / 32;
        int bit = n % 32;
        if (fire) output[word] |= (1U << bit);
    }
}
void run_accelerator_inference() {
    uint32_t *input = (uint32_t *)(accelerator_mem + 0x0000);
    uint8_t *weights1 = accelerator_mem + 0x0100;
    uint8_t *weights2 = accelerator_mem + 0x10100;
    uint32_t *output = (uint32_t *)(accelerator_mem + 0x20100);
    uint32_t hidden[WORDS_HIDDEN] = {0};
    bsnn_layer(input, WORDS_INPUT, weights1, HIDDEN_SIZE, THRESHOLD1, hidden);
    bsnn_layer(hidden, WORDS_HIDDEN, weights2, OUTPUT_SIZE, THRESHOLD2, output);
    pci_mmio_write(0x3000, 1);
}

// Timing helper
double get_elapsed_ms(struct timespec t1, struct timespec t2) {
    return (t2.tv_sec - t1.tv_sec) * 1e3 + (t2.tv_nsec - t1.tv_nsec) / 1e6;
}

int main() {
    srand((unsigned)time(NULL));
    FILE *csv = fopen("bsnn_inference_with_transfer.csv", "w");
    fprintf(csv, "Iteration,Transfer_ms,Inference_ms,Total_ms\n");

    uint32_t input[WORDS_INPUT];
    uint32_t weights1[HIDDEN_SIZE][WORDS_INPUT];
    uint32_t weights2[OUTPUT_SIZE][WORDS_HIDDEN];
    uint32_t output[WORDS_OUTPUT];

    for (int i = 0; i < WORDS_INPUT; i++) input[i] = rand();
    for (int i = 0; i < HIDDEN_SIZE; i++)
        for (int j = 0; j < WORDS_INPUT; j++)
            weights1[i][j] = rand();
    for (int i = 0; i < OUTPUT_SIZE; i++)
        for (int j = 0; j < WORDS_HIDDEN; j++)
            weights2[i][j] = rand();

    pci_dma_write(0x0100, weights1, sizeof(weights1));
    pci_dma_write(0x10100, weights2, sizeof(weights2));

    int num_iters = 1000;
    double total_total = 0, total_transfer = 0, total_infer = 0;

    for (int i = 0; i < num_iters; i++) {
        memset(output, 0, sizeof(output));
        pci_mmio_write(0x3000, 0);

        struct timespec t1, t2, t3;

        clock_gettime(CLOCK_MONOTONIC, &t1);
        pci_dma_write(0x0000, input, sizeof(input));
        clock_gettime(CLOCK_MONOTONIC, &t2);
        run_accelerator_inference();
        clock_gettime(CLOCK_MONOTONIC, &t3);

        double transfer_ms = get_elapsed_ms(t1, t2);
        double infer_ms = get_elapsed_ms(t2, t3);
        double total_ms = get_elapsed_ms(t1, t3);

        fprintf(csv, "%d,%.6f,%.6f,%.6f\n", i, transfer_ms, infer_ms, total_ms);

        total_transfer += transfer_ms;
        total_infer += infer_ms;
        total_total += total_ms;

        memcpy(output, accelerator_mem + 0x20100, sizeof(output));
    }

    fclose(csv);

    printf("BSNN Accelerator (1000 runs):\n");
    printf("  Avg Transfer: %.4f ms\n", total_transfer / num_iters);
    printf("  Avg Inference: %.4f ms\n", total_infer / num_iters);
    printf("  Avg Total: %.4f ms\n", total_total / num_iters);

    return 0;
}

