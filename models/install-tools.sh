#!/bin/bash
set -e

echo "🔧 Installing model conversion dependencies..."

# Detect Python version
if command -v python3.12 &> /dev/null; then
    PYTHON="python3.12"
elif command -v python3 &> /dev/null; then
    PYTHON="python3"
else
    echo "❌ Python 3 not found!"
    exit 1
fi

echo "Using Python: $PYTHON"

# Install core ML dependencies
echo "📦 Installing PyTorch and Transformers..."
# Skip pip upgrade if it causes issues
$PYTHON -m pip install --upgrade pip 2>/dev/null || echo "Skipping pip upgrade"
$PYTHON -m pip install torch torchvision torchaudio
$PYTHON -m pip install transformers safetensors accelerate

# Install TensorFlow for Android conversion
echo "📦 Installing TensorFlow and TFLite tools..."
$PYTHON -m pip install tensorflow
# TFLite support is platform-specific, install if available
$PYTHON -m pip install tensorflow-lite-support 2>/dev/null || echo "⚠️ TFLite support not available on this platform"
$PYTHON -m pip install tflite-model-maker 2>/dev/null || echo "⚠️ TFLite model maker not available on this platform"

# Install MediaPipe for Android
echo "📦 Installing MediaPipe..."
$PYTHON -m pip install mediapipe

# Fix CoreML tools for iOS
echo "📦 Reinstalling CoreML tools..."
$PYTHON -m pip uninstall -y coremltools 2>/dev/null || true
$PYTHON -m pip install coremltools --no-cache-dir

# Install additional utilities
echo "📦 Installing additional utilities..."
$PYTHON -m pip install numpy scipy Pillow
$PYTHON -m pip install sentencepiece protobuf

# Verify installations
echo "✅ Verifying installations..."
$PYTHON -c "import torch; print(f'✓ PyTorch {torch.__version__}')" 2>/dev/null || echo "❌ PyTorch not installed"
$PYTHON -c "import transformers; print(f'✓ Transformers {transformers.__version__}')" 2>/dev/null || echo "❌ Transformers not installed"
$PYTHON -c "import tensorflow as tf; print(f'✓ TensorFlow {tf.__version__}')" 2>/dev/null || echo "❌ TensorFlow not installed"
$PYTHON -c "import coremltools; print(f'✓ CoreML Tools {coremltools.__version__}')" 2>/dev/null || echo "❌ CoreML Tools not installed"
$PYTHON -c "import mediapipe; print(f'✓ MediaPipe installed')" 2>/dev/null || echo "⚠️ MediaPipe not installed (Android conversion may be limited)"

echo "🎉 All dependencies installed successfully!"
echo ""
echo "Next steps:"
echo "1. Convert iOS model: cd models/conversion && $PYTHON convert_gemma3n_ios.py --variant E2B"
echo "2. Convert Android model: cd models/conversion && $PYTHON convert_gemma3n_android.py --variant E2B"