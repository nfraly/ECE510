
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

double sigmoid(double x) {
    return 1.0 / (1.0 + exp(-x));
}

double sigmoid_derivative(double x) {
    return x * (1 - x);
}

double mse(double output, double target) {
    return (output - target) * (output - target);
}

void print_help(char *program_name) {
    printf("Usage: %s [--func xor|nand|and|or|nor|all]\n", program_name);
    printf("\nOptions:\n");
    printf("  --func xor     Train on XOR function (default)\n");
    printf("  --func nand    Train on NAND function\n");
    printf("  --func and     Train on AND function\n");
    printf("  --func or      Train on OR function\n");
    printf("  --func nor     Train on NOR function\n");
    printf("  --func all     Train on ALL gates sequentially (XOR last)\n");
    printf("  -h             Show help message\n");
}

void train_and_output(const char* func_name, double data[4][3], const char* filename) {
    double weight1 = 0.5, weight2 = -0.3, bias = 0.1, learning_rate = 0.1;
    int epochs = 10000, samples = 4;

    printf("Training on %s function\n", func_name);

    for (int e = 0; e < epochs; e++) {
        for (int i = 0; i < samples; i++) {
            double input1 = data[i][0], input2 = data[i][1], target = data[i][2];
            double z = (input1 * weight1) + (input2 * weight2) + bias;
            double output = sigmoid(z);
            double error = output - target;
            double delta = error * sigmoid_derivative(output);
            weight1 -= learning_rate * delta * input1;
            weight2 -= learning_rate * delta * input2;
            bias    -= learning_rate * delta;
        }
    }

    FILE *file = fopen(filename, "a");
    fprintf(file, "Function,%s\n", func_name);
    fprintf(file, "Trained Weights and Bias,\n");
    fprintf(file, "Weight1,%.6f\n", weight1);
    fprintf(file, "Weight2,%.6f\n", weight2);
    fprintf(file, "Bias,%.6f\n", bias);
    fprintf(file, "Input1,Input2,Output\n");

    for (int i = 0; i < samples; i++) {
        double input1 = data[i][0], input2 = data[i][1];
        double z = (input1 * weight1) + (input2 * weight2) + bias;
        double output = sigmoid(z);
        fprintf(file, "%.0f,%.0f,%.4f\n", input1, input2, output);
    }
    fprintf(file, "\n");
    fclose(file);
}

int main(int argc, char *argv[]) {
    double data[4][3];
    char func[10] = "xor";
    int all = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0) {
            print_help(argv[0]);
            return 0;
        } else if (strcmp(argv[i], "--func") == 0 && i + 1 < argc) {
            i++;
            if (strcmp(argv[i], "all") == 0) {
                all = 1;
            } else {
                strcpy(func, argv[i]);
            }
        }
    }

    remove("output.csv");

    const char* gates[] = {"and", "or", "nand", "nor", "xor"};
    const int gate_count = all ? 5 : 1;

    for (int g = 0; g < gate_count; g++) {
        if (!all) strcpy(func, gates[4]);
        else strcpy(func, gates[g]);

        if (strcmp(func, "and") == 0) {
            double temp[4][3] = {{0,0,0},{0,1,0},{1,0,0},{1,1,1}};
            memcpy(data, temp, sizeof(temp));
        } else if (strcmp(func, "or") == 0) {
            double temp[4][3] = {{0,0,0},{0,1,1},{1,0,1},{1,1,1}};
            memcpy(data, temp, sizeof(temp));
        } else if (strcmp(func, "nand") == 0) {
            double temp[4][3] = {{0,0,1},{0,1,1},{1,0,1},{1,1,0}};
            memcpy(data, temp, sizeof(temp));
        } else if (strcmp(func, "nor") == 0) {
            double temp[4][3] = {{0,0,1},{0,1,0},{1,0,0},{1,1,0}};
            memcpy(data, temp, sizeof(temp));
        } else {
            double temp[4][3] = {{0,0,0},{0,1,1},{1,0,1},{1,1,0}};
            memcpy(data, temp, sizeof(temp));
        }

        train_and_output(func, data, "output.csv");
    }

    printf("Training complete. Output written to output.csv\n");

    return 0;
}
