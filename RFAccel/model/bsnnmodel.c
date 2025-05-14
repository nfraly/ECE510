
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define INPUT_SIZE 256
#define HIDDEN_SIZE 2048
#define OUTPUT_SIZE 256
#define NUM_ITERS 1000

#define WORDS_INPUT (INPUT_SIZE / 32)
#define WORDS_HIDDEN (HIDDEN_SIZE / 32)
#define WORDS_OUTPUT (OUTPUT_SIZE / 32)

#define THRESHOLD1 (INPUT_SIZE / 2)
#define THRESHOLD2 (HIDDEN_SIZE / 2)

#define PCIe_BANDWIDTH_MBps 1500
#define DRAM_BANDWIDTH_MBps 5000

#define FAULT_RATE 0.01  // 1% chance per transfer to simulate fault
#define MAX_FAULT_DELAY_MS 20.0  // Fault-induced delay cap

uint8_t accelerator_mem[512 * 1024];

void pci_mmio_write(uint32_t offset, uint32_t value) {
    *(uint32_t *)(accelerator_mem + offset) = value;
}
uint32_t pci_mmio_read(uint32_t offset) {
    return *(uint32_t *)(accelerator_mem + offset);
}

void delay_for_bandwidth_faulty(size_t size_bytes, double nominal_MBps) {
    double jitter = 1.0 + (((rand() % 201) - 100) / 1000.0);  // ±10%
    double effective_MBps = nominal_MBps * jitter;
    double time_sec = size_bytes / (effective_MBps * 1024.0 * 1024.0);

    // Inject fault (extra delay)
    if ((rand() / (double)RAND_MAX) < FAULT_RATE) {
        double fault_delay_ms = (rand() / (double)RAND_MAX) * MAX_FAULT_DELAY_MS;
        time_sec += fault_delay_ms / 1000.0;
        printf("⚠️  Simulated fault: extra %.2f ms delay\n", fault_delay_ms);
    }

    struct timespec delay;
    delay.tv_sec = (time_t)time_sec;
    delay.tv_nsec = (long)((time_sec - delay.tv_sec) * 1e9);
    nanosleep(&delay, NULL);
}

void pci_dma_write(uint32_t dst_offset, const void* src, size_t size) {
    delay_for_bandwidth_faulty(size, PCIe_BANDWIDTH_MBps);
    memcpy(accelerator_mem + dst_offset, src, size);
}

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
    delay_for_bandwidth_faulty(num_neurons * input_words * 4, DRAM_BANDWIDTH_MBps);
    for (int n = 0; n < num_neurons; n++) {
        uint32_t *weight_ptr = (uint32_t *)(weight_base + n * input_words * 4);
        int match = matching_bits(input, weight_ptr, input_words);
        int fire = (match >= threshold) ? 1 : 0;
        int word = n / 32;
        int bit = n % 32;
        if (fire) output[word] |= (1U << bit);
    }
}

void run_accelerator_inference(uint32_t input_batch[WORDS_INPUT],
                               uint32_t output_batch[WORDS_OUTPUT]) {
    uint32_t *input = (uint32_t *)(accelerator_mem + 0x0000);
    uint8_t *weights1 = accelerator_mem + 0x0100;
    uint8_t *weights2 = accelerator_mem + 0x10100;
    uint32_t *output = (uint32_t *)(accelerator_mem + 0x20100);
    uint32_t hidden[WORDS_HIDDEN] = {0};

    bsnn_layer(input, WORDS_INPUT, weights1, HIDDEN_SIZE, THRESHOLD1, hidden);
    bsnn_layer(hidden, WORDS_HIDDEN, weights2, OUTPUT_SIZE, THRESHOLD2, output);

    memcpy(output_batch, output, sizeof(uint32_t) * WORDS_OUTPUT);
    pci_mmio_write(0x3000, 1);
}

double get_elapsed_ms(struct timespec t1, struct timespec t2) {
    return (t2.tv_sec - t1.tv_sec) * 1e3 + (t2.tv_nsec - t1.tv_nsec) / 1e6;
}

int main() {
    srand((unsigned)time(NULL));
    FILE *csv = fopen("bsnn_fault_injection.csv", "w");
    fprintf(csv, "Iteration,TransferIn_ms,Inference_ms,TransferOut_ms,Total_ms\n");

    uint32_t weights1[HIDDEN_SIZE][WORDS_INPUT];
    uint32_t weights2[OUTPUT_SIZE][WORDS_HIDDEN];
    for (int i = 0; i < HIDDEN_SIZE; i++)
        for (int j = 0; j < WORDS_INPUT; j++)
            weights1[i][j] = rand();
    for (int i = 0; i < OUTPUT_SIZE; i++)
        for (int j = 0; j < WORDS_HIDDEN; j++)
            weights2[i][j] = rand();

    pci_dma_write(0x0100, weights1, sizeof(weights1));
    pci_dma_write(0x10100, weights2, sizeof(weights2));

    double total_transfer_in = 0, total_transfer_out = 0, total_infer = 0, total_total = 0;

    for (int i = 0; i < NUM_ITERS; i++) {
        uint32_t input[WORDS_INPUT], output[WORDS_OUTPUT] = {0};
        for (int j = 0; j < WORDS_INPUT; j++) input[j] = rand();

        pci_mmio_write(0x3000, 0);

        struct timespec t1, t2, t3, t4;

        clock_gettime(CLOCK_MONOTONIC, &t1);
        pci_dma_write(0x0000, input, sizeof(input));
        clock_gettime(CLOCK_MONOTONIC, &t2);
        run_accelerator_inference(input, output);
        clock_gettime(CLOCK_MONOTONIC, &t3);
        pci_dma_write(0x30100, output, sizeof(output));
        clock_gettime(CLOCK_MONOTONIC, &t4);

        double t_in = get_elapsed_ms(t1, t2);
        double t_inf = get_elapsed_ms(t2, t3);
        double t_out = get_elapsed_ms(t3, t4);
        double t_total = get_elapsed_ms(t1, t4);

        fprintf(csv, "%d,%.6f,%.6f,%.6f,%.6f\n", i, t_in, t_inf, t_out, t_total);

        total_transfer_in += t_in;
        total_infer += t_inf;
        total_transfer_out += t_out;
        total_total += t_total;
    }

    fclose(csv);

    printf("BSNN Accelerator (with Fault Injection, %d runs):\n", NUM_ITERS);
    printf("  Avg In Transfer:  %.4f ms\n", total_transfer_in / NUM_ITERS);
    printf("  Avg Inference:    %.4f ms\n", total_infer / NUM_ITERS);
    printf("  Avg Out Transfer: %.4f ms\n", total_transfer_out / NUM_ITERS);
    printf("  Avg Total:        %.4f ms\n", total_total / NUM_ITERS);

    return 0;
}

