#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <float.h>

#define INPUT_SIZE 256
#define HIDDEN_SIZE 2048
#define OUTPUT_SIZE 256
#define NUM_ITERS 1000

#define THRESHOLD1 (INPUT_SIZE / 2)
#define THRESHOLD2 (HIDDEN_SIZE / 2)

#define WORDS_INPUT (INPUT_SIZE / 32)
#define WORDS_HIDDEN (HIDDEN_SIZE / 32)
#define WORDS_OUTPUT (OUTPUT_SIZE / 32)

// Popcount for a 32-bit word
int popcount(uint32_t x) {
    int count = 0;
    while (x) {
        count += x & 1;
        x >>= 1;
    }
    return count;
}

// Bitwise match using XNOR
int matching_bits(uint32_t *a, uint32_t *b, int words) {
    int sum = 0;
    for (int i = 0; i < words; i++) {
        sum += popcount(~(a[i] ^ b[i]));
    }
    return sum;
}

// Generate random binary spike vector
void random_spike_vector(uint32_t *vec, int words) {
    for (int i = 0; i < words; i++) {
        vec[i] = rand();
    }
}

// BSNN Layer: XNOR-popcount-threshold
void bsnn_layer(uint32_t *input, int input_words,
                uint32_t **weights, int num_neurons,
                uint32_t *output, int threshold) {
    for (int n = 0; n < num_neurons; n++) {
        int match = matching_bits(input, weights[n], input_words);
        int fired = (match >= threshold) ? 1 : 0;
        int word_index = n / 32;
        int bit_index = n % 32;
        if (fired) output[word_index] |= (1U << bit_index);
        else output[word_index] &= ~(1U << bit_index);
    }
}

// Nanosecond-precision timer
uint64_t timestamp_ns() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ((uint64_t)ts.tv_sec * 1000000000ULL) + ts.tv_nsec;
}

int main() {
    srand((unsigned int) time(NULL));

    // Allocate and initialize input
    uint32_t input[WORDS_INPUT];
    random_spike_vector(input, WORDS_INPUT);

    // Allocate Layer 1 weights (2048 x 256 bits)
    uint32_t **weights1 = malloc(HIDDEN_SIZE * sizeof(uint32_t *));
    for (int i = 0; i < HIDDEN_SIZE; i++) {
        weights1[i] = malloc(WORDS_INPUT * sizeof(uint32_t));
        random_spike_vector(weights1[i], WORDS_INPUT);
    }

    // Allocate Layer 2 weights (256 x 2048 bits)
    uint32_t **weights2 = malloc(OUTPUT_SIZE * sizeof(uint32_t *));
    for (int i = 0; i < OUTPUT_SIZE; i++) {
        weights2[i] = malloc(WORDS_HIDDEN * sizeof(uint32_t));
        random_spike_vector(weights2[i], WORDS_HIDDEN);
    }

    // Output spike buffers
    uint32_t hidden[WORDS_HIDDEN];
    uint32_t output[WORDS_OUTPUT];

    double total_ms = 0;
    double min_ms = DBL_MAX;
    double max_ms = 0;

    for (int iter = 0; iter < NUM_ITERS; iter++) {
        memset(hidden, 0, sizeof(hidden));
        memset(output, 0, sizeof(output));

        uint64_t start = timestamp_ns();

        bsnn_layer(input, WORDS_INPUT, weights1, HIDDEN_SIZE, hidden, THRESHOLD1);
        bsnn_layer(hidden, WORDS_HIDDEN, weights2, OUTPUT_SIZE, output, THRESHOLD2);

        uint64_t end = timestamp_ns();
        double elapsed_ms = (end - start) / 1e6;

        total_ms += elapsed_ms;
        if (elapsed_ms < min_ms) min_ms = elapsed_ms;
        if (elapsed_ms > max_ms) max_ms = elapsed_ms;
    }

    printf("BSNN FFN (256→2048→256), %d runs:\n", NUM_ITERS);
    printf("  Average time: %.4f ms\n", total_ms / NUM_ITERS);
    printf("  Minimum time: %.4f ms\n", min_ms);
    printf("  Maximum time: %.4f ms\n", max_ms);

    // Cleanup
    for (int i = 0; i < HIDDEN_SIZE; i++) free(weights1[i]);
    free(weights1);
    for (int i = 0; i < OUTPUT_SIZE; i++) free(weights2[i]);
    free(weights2);

    return 0;
}

