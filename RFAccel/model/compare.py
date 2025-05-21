import torch
import time
import csv
import statistics
from rfdetr import RFDETRBase

def extract_addmm_times(model, input_tensor, num_iters=1000):
    times = []
    with torch.no_grad():
        for _ in range(num_iters):
            start = time.time()
            _ = model.transformer.decoder.layers[0].linear1(input_tensor)  # FFN input layer (addmm)
            end = time.time()
            times.append((end - start) * 1000.0)  # ms
    return times

def load_c_sim_times(path):
    times = []
    with open(path, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            times.append(float(row["Inference_ms"]))
    return times

def write_comparison_csv(pytorch_times, c_model_times, out_path="compare_rfdetr_vs_bsnn.csv"):
    with open(out_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["Iteration", "RFDETR_Addmm_ms", "BSNN_C_Inference_ms"])
        for i, (pt, ct) in enumerate(zip(pytorch_times, c_model_times)):
            writer.writerow([i, f"{pt:.6f}", f"{ct:.6f}"])
    print(f"Comparison CSV written to {out_path}")

if __name__ == "__main__":
    device = torch.device("cpu")
    model = RFDETRBase().model.model
    model = model.to(device).eval()

    dummy_input = torch.randn(1, 256).to(device)

    pytorch_times = extract_addmm_times(model, dummy_input, num_iters=1000)
    c_model_times = load_c_sim_times("bsnn_rfdetr_scaled.csv")

    write_comparison_csv(pytorch_times, c_model_times)

    print(f"Avg RFDETR addmm: {statistics.mean(pytorch_times):.4f} ms")
    print(f"Avg BSNN C-model: {statistics.mean(c_model_times):.4f} ms")

