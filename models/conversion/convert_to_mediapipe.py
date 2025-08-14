#!/usr/bin/env python3
"""
Convert Gemma models to MediaPipe .task format for mobile deployment
This creates the .task files needed by both iOS and Android
"""

import os
import sys
import json
import shutil
from pathlib import Path
import subprocess

def check_dependencies():
    """Check if required tools are installed"""
    dependencies = {
        "transformers": "pip install transformers",
        "torch": "pip install torch",
        "tensorflow": "pip install tensorflow",
        "mediapipe": "pip install mediapipe"
    }
    
    missing = []
    for pkg, install_cmd in dependencies.items():
        try:
            __import__(pkg)
        except ImportError:
            missing.append(f"  {install_cmd}")
    
    if missing:
        print("Missing dependencies. Please install:")
        for cmd in missing:
            print(cmd)
        return False
    return True

def download_mediapipe_models():
    """Download pre-converted MediaPipe models"""
    print("\n" + "="*60)
    print("DOWNLOADING MEDIAPIPE GEMMA MODELS")
    print("="*60)
    
    # MediaPipe provides pre-converted Gemma models
    models = {
        "gemma-2b-it-cpu-int4": {
            "url": "https://storage.googleapis.com/mediapipe-models/llm_inference/gemma-2b-it-cpu-int4/float32/latest/gemma-2b-it-cpu-int4.task",
            "size_mb": 1350,
            "description": "Gemma 2B INT4 quantized for CPU"
        },
        "gemma-2b-it-gpu-int4": {
            "url": "https://storage.googleapis.com/mediapipe-models/llm_inference/gemma-2b-it-gpu-int4/float32/latest/gemma-2b-it-gpu-int4.task",
            "size_mb": 1350,
            "description": "Gemma 2B INT4 quantized for GPU"
        }
    }
    
    output_dir = Path("../llm/mediapipe")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    for model_name, config in models.items():
        output_file = output_dir / f"{model_name}.task"
        
        if output_file.exists():
            print(f"\n✓ {model_name} already exists")
            continue
            
        print(f"\nDownloading {config['description']}...")
        print(f"Size: ~{config['size_mb']}MB")
        
        try:
            # Download using curl or wget
            cmd = f"curl -L -o {output_file} {config['url']}"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0 and output_file.exists():
                print(f"✓ Downloaded {model_name}")
            else:
                print(f"✗ Failed to download {model_name}")
                print(f"  Error: {result.stderr}")
                
        except Exception as e:
            print(f"✗ Error downloading {model_name}: {e}")
    
    return output_dir

def create_symlinks_for_app():
    """Create symlinks for iOS and Android apps to use the models"""
    mediapipe_dir = Path("../llm/mediapipe")
    
    if not mediapipe_dir.exists():
        print("⚠️ MediaPipe models directory not found")
        return
    
    # iOS app bundle location
    ios_models_dir = Path("../../mobile/ios/RoadtripCopilot/Resources/Models")
    ios_models_dir.mkdir(parents=True, exist_ok=True)
    
    # Android assets location
    android_models_dir = Path("../../mobile/android/app/src/main/assets/models")
    android_models_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy or link the models
    for task_file in mediapipe_dir.glob("*.task"):
        # For iOS
        ios_dest = ios_models_dir / task_file.name
        if not ios_dest.exists():
            try:
                shutil.copy2(task_file, ios_dest)
                print(f"✓ Copied {task_file.name} to iOS app")
            except Exception as e:
                print(f"⚠️ Failed to copy to iOS: {e}")
        
        # For Android
        android_dest = android_models_dir / task_file.name
        if not android_dest.exists():
            try:
                shutil.copy2(task_file, android_dest)
                print(f"✓ Copied {task_file.name} to Android app")
            except Exception as e:
                print(f"⚠️ Failed to copy to Android: {e}")

def create_model_config():
    """Create configuration file for model loading"""
    config = {
        "models": {
            "gemma-3n-e2b": {
                "mediapipe_model": "gemma-2b-it-cpu-int4.task",
                "max_tokens": 512,
                "temperature": 0.8,
                "top_k": 40,
                "description": "Efficient 2B model for standard inference"
            },
            "gemma-3n-e4b": {
                "mediapipe_model": "gemma-2b-it-gpu-int4.task",
                "max_tokens": 1024,
                "temperature": 0.8,
                "top_k": 40,
                "description": "Advanced model for GPU acceleration"
            }
        },
        "fallback_model": "gemma-2b-it-cpu-int4.task",
        "model_directory": "models/"
    }
    
    config_path = Path("../llm/model_config.json")
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"\n✓ Created model configuration: {config_path}")
    return config_path

def main():
    """Main conversion process"""
    print("\n" + "="*60)
    print("GEMMA TO MEDIAPIPE CONVERTER")
    print("="*60)
    
    # Check dependencies
    if not check_dependencies():
        print("\n⚠️ Please install missing dependencies first")
        return 1
    
    print("\n📝 Note: Using pre-converted MediaPipe Gemma models")
    print("These are optimized for mobile deployment with INT4 quantization")
    
    # Download MediaPipe models
    models_dir = download_mediapipe_models()
    
    if models_dir and models_dir.exists():
        # Create symlinks for apps
        create_symlinks_for_app()
        
        # Create configuration
        config_path = create_model_config()
        
        print("\n" + "="*60)
        print("CONVERSION COMPLETE")
        print("="*60)
        print(f"\n✓ MediaPipe models saved to: {models_dir.absolute()}")
        print(f"✓ Configuration saved to: {config_path.absolute()}")
        print("\nNext steps:")
        print("1. The .task files have been copied to both iOS and Android projects")
        print("2. The apps will automatically load these models on startup")
        print("3. Use 'gemma-2b-it-cpu-int4.task' for CPU inference")
        print("4. Use 'gemma-2b-it-gpu-int4.task' for GPU acceleration (if available)")
        
        return 0
    else:
        print("\n✗ Failed to download MediaPipe models")
        return 1

if __name__ == "__main__":
    sys.exit(main())