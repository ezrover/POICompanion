#!/usr/bin/env python3
"""
Kitten TTS Android TensorFlow Lite Conversion Script
Converts Kitten TTS ONNX model to TensorFlow Lite format for Android deployment
"""

import os
import sys
import tensorflow as tf
from pathlib import Path
import tf2onnx
import onnx

def convert_kitten_tts_to_tflite(
    onnx_model_path: str,
    output_path: str,
    model_name: str = "kitten_tts_nano"
):
    """
    Convert Kitten TTS ONNX model to TensorFlow Lite format
    
    Args:
        onnx_model_path: Path to Kitten TTS ONNX model
        output_path: Output directory for TFLite model
        model_name: Name for the generated model
    """
    
    try:
        print(f"🐱 Converting Kitten TTS ONNX to TensorFlow Lite...")
        print(f"Input: {onnx_model_path}")
        print(f"Output: {output_path}/{model_name}.tflite")
        
        # Load ONNX model
        onnx_model = onnx.load(onnx_model_path)
        
        # Convert ONNX to TensorFlow
        print("📋 Step 1: Converting ONNX to TensorFlow...")
        tf_model_path = f"{output_path}/temp_tf_model"
        
        tf2onnx.convert.from_onnx(
            onnx_model,
            output_path=tf_model_path,
            opset=11
        )
        
        # Load TensorFlow model
        print("📋 Step 2: Loading TensorFlow model...")
        converter = tf.lite.TFLiteConverter.from_saved_model(tf_model_path)
        
        # Configure converter for mobile optimization
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS  # Allow some TF ops if needed
        ]
        
        # CPU optimization (Kitten TTS is CPU-optimized)
        converter.target_spec.supported_types = [tf.float32]
        
        # Enable quantization for smaller size
        converter.representative_dataset = create_representative_dataset
        converter.target_spec.supported_types = [tf.int8]
        converter.inference_input_type = tf.int8
        converter.inference_output_type = tf.int8
        
        # Convert to TensorFlow Lite
        print("📋 Step 3: Converting to TensorFlow Lite...")
        tflite_model = converter.convert()
        
        # Ensure output directory exists
        os.makedirs(output_path, exist_ok=True)
        
        # Save TFLite model
        tflite_path = f"{output_path}/{model_name}.tflite"
        with open(tflite_path, 'wb') as f:
            f.write(tflite_model)
        
        # Clean up temporary files
        import shutil
        if os.path.exists(tf_model_path):
            shutil.rmtree(tf_model_path)
        
        # Verify model size
        model_size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
        
        print(f"✅ TensorFlow Lite conversion successful!")
        print(f"📱 Model size: {model_size_mb:.1f} MB")
        print(f"🎯 Target: <25MB (✅ Achieved)" if model_size_mb < 25 else f"⚠️  Model exceeds 25MB target")
        print(f"💾 Saved to: {tflite_path}")
        
        return tflite_path
        
    except Exception as e:
        print(f"❌ Conversion failed: {str(e)}")
        return None

def create_representative_dataset():
    """Generate representative dataset for quantization"""
    # Sample text inputs for quantization calibration
    sample_texts = [
        "Welcome to POI Companion",
        "This hidden gem offers amazing food",
        "Turn left at the next intersection",
        "You could earn free roadtrips from this discovery",
        "The restaurant has excellent reviews"
    ]
    
    for text in sample_texts:
        # Create dummy inputs matching model's expected format
        # This would need to be adjusted based on actual model input requirements
        text_input = tf.constant([text], dtype=tf.string)
        voice_id = tf.constant([0], dtype=tf.int32)
        speed = tf.constant([1.0], dtype=tf.float32)
        pitch = tf.constant([0.0], dtype=tf.float32)
        
        yield [text_input, voice_id, speed, pitch]

def download_kitten_tts_model(output_dir: str = "models/onnx"):
    """Download Kitten TTS ONNX model from Hugging Face"""
    try:
        from huggingface_hub import hf_hub_download
        
        print("📥 Downloading Kitten TTS model from Hugging Face...")
        
        os.makedirs(output_dir, exist_ok=True)
        
        model_path = hf_hub_download(
            repo_id="KittenML/kitten-tts-nano-0.1",
            filename="model.onnx",
            local_dir=output_dir,
            local_dir_use_symlinks=False
        )
        
        print(f"✅ Downloaded Kitten TTS model to: {model_path}")
        return model_path
        
    except Exception as e:
        print(f"❌ Download failed: {str(e)}")
        print("💡 Please download manually from: https://huggingface.co/KittenML/kitten-tts-nano-0.1")
        return None

def main():
    """Main conversion process"""
    
    print("🚀 Kitten TTS Android TensorFlow Lite Conversion")
    print("=" * 55)
    
    # Check if ONNX model exists, download if not
    onnx_path = "models/onnx/kitten_tts_nano.onnx"
    
    if not os.path.exists(onnx_path):
        print(f"📁 ONNX model not found at {onnx_path}")
        downloaded_path = download_kitten_tts_model("models/onnx")
        if downloaded_path:
            onnx_path = downloaded_path
        else:
            print("❌ Cannot proceed without ONNX model")
            sys.exit(1)
    
    # Convert to TensorFlow Lite
    tflite_path = convert_kitten_tts_to_tflite(
        onnx_model_path=onnx_path,
        output_path="android/app/src/main/assets/models",
        model_name="kitten_tts_nano"
    )
    
    if tflite_path:
        print("\n🎉 Kitten TTS Android integration ready!")
        print("💡 Next steps:")
        print("   1. Build Android project")
        print("   2. Test TTS integration with TensorFlow Lite")
        print("   3. Verify <350ms latency target")
        print("   4. Test NNAPI acceleration if available")
    else:
        print("❌ Conversion failed - check logs above")
        sys.exit(1)

if __name__ == "__main__":
    main()