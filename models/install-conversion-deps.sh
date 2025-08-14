#!/bin/bash
set -e

echo "🔧 Installing model conversion dependencies..."

# Use Python 3.12 which has the packages
PYTHON="python3.12"

echo "📦 Installing TensorFlow for TFLite conversion..."
$PYTHON -m pip install tensorflow --quiet 2>/dev/null || {
    echo "⚠️ TensorFlow installation failed, trying alternative..."
    $PYTHON -m pip install tensorflow-macos --quiet 2>/dev/null || echo "TensorFlow not available"
}

echo "📦 Installing ONNX for intermediate format..."
$PYTHON -m pip install onnx onnxruntime --quiet

echo "📦 Installing conversion utilities..."
$PYTHON -m pip install tf2onnx onnx2tf --quiet 2>/dev/null || echo "Some conversion tools unavailable"

echo "📦 Ensuring CoreML tools are installed..."
$PYTHON -m pip install coremltools --upgrade --quiet

echo "📦 Installing quantization tools..."
$PYTHON -m pip install onnxruntime-tools --quiet 2>/dev/null || echo "ONNX tools unavailable"

echo "✅ Checking installed packages..."
$PYTHON -c "import torch; print(f'✓ PyTorch {torch.__version__}')" 2>/dev/null || echo "❌ PyTorch missing"
$PYTHON -c "import coremltools; print(f'✓ CoreML Tools {coremltools.__version__}')" 2>/dev/null || echo "❌ CoreML Tools missing"
$PYTHON -c "import onnx; print(f'✓ ONNX {onnx.__version__}')" 2>/dev/null || echo "❌ ONNX missing"
$PYTHON -c "import tensorflow as tf; print(f'✓ TensorFlow {tf.__version__}')" 2>/dev/null || echo "⚠️ TensorFlow missing (TFLite conversion limited)"

echo "🎉 Dependencies check complete!"