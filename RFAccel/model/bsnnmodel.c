
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define IMG_WIDTH 672
#define IMG_HEIGHT 672
#define IMG_CHANNELS 3
#define INPUT_SIZE_BYTES (IMG_WIDTH * IMG_HEIGHT * IMG_CHANNELS)

#define OUTPUT_OBJECTS 100
#define OUTPUT_FEATURES_PER_OBJ 5
#define OUTPUT_SIZE_BYTES (OUTPUT_OBJECTS * OUTPUT_FEATURES_PER_OBJ * sizeof(float))

#define NUM_ITERS 1000

#define PCIe_BANDWIDTH_MBps 1500
#define DRAM_BANDWIDTH_MBps 5000

#define FAULT_RATE 0.01
#define MAX_FAULT_DELAY_MS 20.0

uint8_t accelerator_mem[2 * 1024 * 1024];

void delay_for_bandwidth_faulty(size_t size_bytes, double nominal_MBps) {
    double jitter = 1.0 + (((rand() % 201) - 100) / 1000.0);
    double effective_MBps = nominal_MBps * jitter;
    double time_sec = size_bytes / (effective_MBps * 1024.0 * 1024.0);

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

void pci_mmio_write(uint32_t offset, uint32_t value) {
    *(uint32_t *)(accelerator_mem + offset) = value;
}
uint32_t pci_mmio_read(uint32_t offset) {
    return *(uint32_t *)(accelerator_mem + offset);
}

double get_elapsed_ms(struct timespec t1, struct timespec t2) {
    return (t2.tv_sec - t1.tv_sec) * 1e3 + (t2.tv_nsec - t1.tv_nsec) / 1e6;
}


void run_accelerator_inference(uint8_t* input_tensor, float* output_tensor) {
    // Simulate proportional compute based on image size (MAC-like behavior)
    static float weights[IMG_CHANNELS] = {0.5f, -0.25f, 0.75f};
    // Use input_tensor and output_tensor

    // Simulated DRAM access delay
    size_t dram_transfer = INPUT_SIZE_BYTES + OUTPUT_SIZE_BYTES;
    double jitter = 1.0 + (((rand() % 201) - 100) / 1000.0);
    double effective_MBps = DRAM_BANDWIDTH_MBps * jitter;
    double time_sec = dram_transfer / (effective_MBps * 1024.0 * 1024.0);
    if ((rand() / (double)RAND_MAX) < FAULT_RATE) {
        double fault_delay_ms = (rand() / (double)RAND_MAX) * MAX_FAULT_DELAY_MS;
        time_sec += fault_delay_ms / 1000.0;
        printf("⚠️  Simulated DRAM fault: extra %.2f ms delay\n", fault_delay_ms);
    }
    struct timespec delay;
    delay.tv_sec = (time_t)time_sec;
    delay.tv_nsec = (long)((time_sec - delay.tv_sec) * 1e9);
    nanosleep(&delay, NULL);

    // Simulated MAC loop over image
    for (int obj = 0; obj < OUTPUT_OBJECTS; obj++) {
        for (int feat = 0; feat < OUTPUT_FEATURES_PER_OBJ; feat++) {
            float acc = 0.0f;
            for (int px = 0; px < IMG_WIDTH * IMG_HEIGHT; px += 64) {
                int base = px * IMG_CHANNELS;
                acc += input_tensor[base + 0] * weights[0];
                acc += input_tensor[base + 1] * weights[1];
                acc += input_tensor[base + 2] * weights[2];
            }
            output_tensor[obj * OUTPUT_FEATURES_PER_OBJ + feat] = acc / (IMG_WIDTH * IMG_HEIGHT / 64);
        }
    }

    // output_tensor is already final buffer; no copy needed
    pci_mmio_write(0x3000, 1);

    // Use input_tensor and output_tensor

    delay_for_bandwidth_faulty(INPUT_SIZE_BYTES + OUTPUT_SIZE_BYTES, DRAM_BANDWIDTH_MBps);

    for (int i = 0; i < OUTPUT_OBJECTS * OUTPUT_FEATURES_PER_OBJ; i++) {
        output_tensor[i] = (float)(input_tensor[i % INPUT_SIZE_BYTES]) / 255.0f;
    }

    // output_tensor is already final buffer; no copy needed
    pci_mmio_write(0x3000, 1);
}

int main() {
    srand((unsigned)time(NULL));
    FILE *csv = fopen("bsnn_rfdetr_scaled.csv", "w");
    fprintf(csv, "Iteration,TransferIn_ms,Inference_ms,TransferOut_ms,Total_ms\n");

    uint8_t input[INPUT_SIZE_BYTES];
    float output[OUTPUT_OBJECTS * OUTPUT_FEATURES_PER_OBJ];

    for (int i = 0; i < INPUT_SIZE_BYTES; i++) input[i] = rand() % 256;

    double total_transfer_in = 0, total_transfer_out = 0, total_infer = 0, total_total = 0;

    for (int i = 0; i < NUM_ITERS; i++) {
        pci_mmio_write(0x3000, 0);

        struct timespec t1, t2, t3, t4;

        clock_gettime(CLOCK_MONOTONIC, &t1);
        pci_dma_write(0x0000, input, INPUT_SIZE_BYTES);
        clock_gettime(CLOCK_MONOTONIC, &t2);
        run_accelerator_inference(input, output);
        clock_gettime(CLOCK_MONOTONIC, &t3);
        pci_dma_write(0x1F0000, output, OUTPUT_SIZE_BYTES);
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

    printf("RFDETR-Scaled BSNN Accelerator (%d runs):\n", NUM_ITERS);
    printf("  Avg Transfer In:  %.4f ms\n", total_transfer_in / NUM_ITERS);
    printf("  Avg Inference:    %.4f ms\n", total_infer / NUM_ITERS);
    printf("  Avg Transfer Out: %.4f ms\n", total_transfer_out / NUM_ITERS);
    printf("  Avg Total:        %.4f ms\n", total_total / NUM_ITERS);

    return 0;
}

