
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
    printf("Options:\n");
    printf("  --func xor, nand, and, or, nor, all\n");
}

void output_points(const char *gate, double data[4][3]) {
    char filename[64];
    snprintf(filename, sizeof(filename), "points_%s.csv", gate);
    FILE *fp = fopen(filename, "w");
    fprintf(fp, "Input1,Input2,Target\n");
    for (int i = 0; i < 4; i++) {
        fprintf(fp, "%.0f,%.0f,%.0f\n", data[i][0], data[i][1], data[i][2]);
    }
    fclose(fp);
}

void train_and_output(const char* gate, double data[4][3]) {
    double w1 = 0.5, w2 = -0.3, b = 0.1, lr = 0.1;
    int epochs = 10000;

    char filename[64];
    snprintf(filename, sizeof(filename), "lines_%s.csv", gate);
    FILE *lines = fopen(filename, "w");
    char logname[64];
    snprintf(logname, sizeof(logname), "training_log_%s.csv", gate);
    FILE *log = fopen(logname, "w");
    fprintf(log, "Epoch,Weight1,Weight2,Bias\n");
    fprintf(lines, "Epoch,Slope,Intercept\n");

    for (int e = 0; e < epochs; e++) {
        for (int i = 0; i < 4; i++) {
            double in1 = data[i][0], in2 = data[i][1], target = data[i][2];
            double z = in1 * w1 + in2 * w2 + b;
            double output = sigmoid(z);
            double error = output - target;
            double delta = error * sigmoid_derivative(output);
            w1 -= lr * delta * in1;
            w2 -= lr * delta * in2;
            b  -= lr * delta;
        }
        double slope = -w1 / w2;
        double intercept = -b / w2;
        fprintf(lines, "%d,%.6f,%.6f\n", e, slope, intercept);
        fprintf(log, "%d,%.6f,%.6f,%.6f\n", e, w1, w2, b);
    }
    fclose(lines);
    fclose(log);
}

int main(int argc, char *argv[]) {
    char func[10] = "xor";
    int all = 0;
    double data[4][3];

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0) {
            print_help(argv[0]);
            return 0;
        } else if (strcmp(argv[i], "--func") == 0 && i + 1 < argc) {
            i++;
            if (strcmp(argv[i], "all") == 0) all = 1;
            else strcpy(func, argv[i]);
        }
    }

    const char* gates[] = {"and", "or", "nand", "nor", "xor"};
    int gate_count = all ? 5 : 1;

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

        output_points(func, data);
        train_and_output(func, data);
    }

    return 0;
}
