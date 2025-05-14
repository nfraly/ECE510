#!/bin/bash

ENV_NAME="rfprof_env"
SCRIPT_NAME="profile_callstack.py"
REQUIREMENTS_FILE="requirements.txt"
RFDETR_REPO="https://github.com/roboflow/rf-detr.git"
RFDETR_DIR="rf-detr"

# ✅ Step 1: Create virtual environment if it doesn't exist
if [ ! -d "$ENV_NAME" ]; then
    echo "🔧 Creating virtual environment: $ENV_NAME"
    python3 -m venv $ENV_NAME
fi

# ✅ Step 2: Activate the virtual environment
source $ENV_NAME/bin/activate
echo "✅ Activated environment: $ENV_NAME"

# ✅ Step 3: Install core Python packages
echo "📦 Installing PyTorch and core libraries..."
pip install --upgrade pip
pip install torch==2.3.0 torchvision==0.18.0 torchaudio==2.3.0 tensorboard==2.15.1

# ✅ Step 4: Install rf-detr (if not already cloned)
if [ ! -d "$RFDETR_DIR" ]; then
    echo "📥 Cloning rf-detr..."
    git clone --depth=1 $RFDETR_REPO
fi

echo "🧩 Installing rf-detr..."
pip install -e $RFDETR_DIR

# ✅ Step 5: Run the profiling script
if [ -f "$SCRIPT_NAME" ]; then
    echo "🚀 Running $SCRIPT_NAME"
    python $SCRIPT_NAME --input-size 672 672 --logdir logs
else
    echo "❌ $SCRIPT_NAME not found. Please ensure it exists in this directory."
fi

