import torch
from rfdetr import RFDETRBase
import argparse
from torch.profiler import profile, record_function, ProfilerActivity
from torch.utils.tensorboard import SummaryWriter
import time
import os
import shutil
from datetime import datetime

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--device', default='cpu')
    parser.add_argument('--input-size', type=int, nargs=2, default=[672, 672])
    parser.add_argument('--logdir', type=str, default='logs', help='TensorBoard log directory')
    parser.add_argument('--trace-out', default='trace.json', help='Chrome trace output path')
    args = parser.parse_args()

    device = torch.device(args.device)
    detector = RFDETRBase()
    model = detector.model.model.to(device)
    dummy_input = torch.randn(1, 3, *args.input_size).to(device)

    print(f"🧠 Profiling on: {device}")
    os.makedirs(args.logdir, exist_ok=True)
    writer = SummaryWriter(log_dir=args.logdir)

    with profile(
        activities=[ProfilerActivity.CPU],
        record_shapes=True,
        with_stack=True
    ) as prof:
        with torch.no_grad():
            with record_function("model_inference"):
                start = time.perf_counter()
                model(dummy_input)
                end = time.perf_counter()
                duration_ms = (end - start) * 1000
                writer.add_scalar("Execution/Total_Inference_Time_ms", duration_ms, 0)
                print(f"⏱️ Inference time: {duration_ms:.2f} ms")
            prof.step()

    # 🖨️ Console summary of ops (top 20 by self CPU time)
    print("\n📊 Top ops by self CPU time:")
    profile_table = prof.key_averages().table(sort_by="self_cpu_time_total", row_limit=20)
    print(profile_table)

    # 🧵 Console + file output for top call stacks
    print("\n🧵 Top call stacks by self CPU time:")
    callstack_table = prof.key_averages(group_by_stack_n=5).table(
        sort_by="self_cpu_time_total", row_limit=10
    )
    print(callstack_table)

    # 📁 Save both outputs to file
    with open(os.path.join(args.logdir, "profile_summary.txt"), "w") as f:
        f.write(profile_table)
    with open(os.path.join(args.logdir, "callstack_summary.txt"), "w") as f:
        f.write(callstack_table)
    print("📝 Top ops and call stacks written to profile_summary.txt and callstack_summary.txt")

    # Save Chrome trace
    trace_path = os.path.join(args.logdir, "trace.json")
    prof.export_chrome_trace(trace_path)
    print(f"✅ Chrome trace written to {trace_path}")

    # Plugin directory
    run_id = datetime.now().strftime("run_%Y%m%d_%H%M%S")
    plugin_dir = os.path.join(args.logdir, "plugins", "profile", run_id)
    os.makedirs(plugin_dir, exist_ok=True)
    shutil.copyfile(trace_path, os.path.join(plugin_dir, "local.trace"))
    print(f"📁 Copied trace to: {plugin_dir}/local.trace")

    writer.flush()
    writer.close()
    print(f"\n🚀 Done. Run: tensorboard --logdir={args.logdir} --port=6006")

if __name__ == "__main__":
    main()

