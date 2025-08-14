# Install missing dependencies
pip install torch transformers tensorflow mediapipe
pip install tensorflow-lite-support safetensors

# Fix CoreML tools
pip uninstall coremltools
pip install coremltools --no-cache-dir

# Then run conversions
cd models/conversion
python convert_gemma3n_ios.py --variant E2B
python convert_gemma3n_android.py --variant E2B