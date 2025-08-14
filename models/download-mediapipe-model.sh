#!/bin/bash
set -e

echo "📥 Downloading MediaPipe Gemma model for mobile..."

cd /Users/naderrahimizad/Projects/AI/POICompanion/models/llm/mediapipe

# Download the actual MediaPipe Gemma-2B model (INT4 quantized)
echo "Downloading Gemma-2B INT4 model (~1.4GB)..."
curl -L -o gemma-2b-it-cpu-int4.bin \
  "https://storage.googleapis.com/mediapipe-models/genai/gemma-2b-it/gpu-int4/gemma-2b-it-gpu-int4.bin"

echo "✅ Download complete!"
echo "Model saved to: models/llm/mediapipe/gemma-2b-it-cpu-int4.bin"
echo ""
echo "This model can be used directly with MediaPipe on Android."