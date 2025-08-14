#!/usr/bin/env python3
"""
Kitten TTS iOS Core ML Conversion Script
Converts Kitten TTS ONNX model to Core ML format for iOS deployment
"""

import os
import sys
import coremltools as ct
import numpy as np
from pathlib import Path

def convert_kitten_tts_to_coreml(
    onnx_model_path: str,
    output_path: str,
    model_name: str = "kitten_tts_nano"
):
    """
    Convert Kitten TTS ONNX model to Core ML format
    
    Args:
        onnx_model_path: Path to Kitten TTS ONNX model
        output_path: Output directory for Core ML model
        model_name: Name for the generated model
    """
    
    try:
        print(f"🐱 Converting Kitten TTS ONNX to Core ML...")
        print(f"Input: {onnx_model_path}")
        print(f"Output: {output_path}/{model_name}.mlmodelc")
        
        # Load ONNX model and convert to Core ML
        model = ct.convert(
            model=onnx_model_path,
            source='onnx',
            minimum_deployment_target=ct.target.iOS14,
            compute_units=ct.ComputeUnit.CPU_ONLY,  # Kitten TTS is CPU-optimized
            convert_to='mlprogram'
        )
        
        # Set model metadata
        model.short_description = "Kitten TTS - Ultra-lightweight CPU-only text-to-speech"
        model.author = "KittenML Team"
        model.license = "Apache 2.0"
        model.version = "0.1"
        
        # Add input descriptions
        model.input_description['text'] = 'Input text to synthesize'
        model.input_description['voice_id'] = 'Voice ID (0-7 for 8 available voices)'
        model.input_description['speed'] = 'Speech speed (0.5-2.0, default 1.0)'
        model.input_description['pitch'] = 'Pitch adjustment (-1.0 to 1.0, default 0.0)'
        
        # Add output description
        model.output_description['audio'] = 'Generated audio waveform (22050 Hz)'
        
        # Ensure output directory exists
        os.makedirs(output_path, exist_ok=True)
        
        # Save Core ML model
        model_path = f"{output_path}/{model_name}.mlmodelc"
        model.save(model_path)
        
        # Verify model size
        model_size_mb = get_directory_size(model_path) / (1024 * 1024)
        
        print(f"✅ Core ML conversion successful!")
        print(f"📱 Model size: {model_size_mb:.1f} MB")
        print(f"🎯 Target: <25MB (✅ Achieved)" if model_size_mb < 25 else f"⚠️  Model exceeds 25MB target")
        print(f"💾 Saved to: {model_path}")
        
        return model_path
        
    except Exception as e:
        print(f"❌ Conversion failed: {str(e)}")
        return None

def get_directory_size(path: str) -> int:
    """Calculate total size of directory in bytes"""
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(path):
        for filename in filenames:
            file_path = os.path.join(dirpath, filename)
            if os.path.exists(file_path):
                total_size += os.path.getsize(file_path)
    return total_size

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
    
    print("🚀 Kitten TTS iOS Core ML Conversion")
    print("=" * 50)
    
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
    
    # Convert to Core ML
    coreml_path = convert_kitten_tts_to_coreml(
        onnx_model_path=onnx_path,
        output_path="ios/Roadtrip-Copilot/Roadtrip-Copilot/Resources/Models",
        model_name="kitten_tts_nano"
    )
    
    if coreml_path:
        print("\n🎉 Kitten TTS iOS integration ready!")
        print("💡 Next steps:")
        print("   1. Build iOS project")
        print("   2. Test TTS integration")
        print("   3. Verify <350ms latency target")
    else:
        print("❌ Conversion failed - check logs above")
        sys.exit(1)

if __name__ == "__main__":
    main()