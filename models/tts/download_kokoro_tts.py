#!/usr/bin/env python3
"""
Kokoro TTS Download Script
Downloads Kokoro TTS model for premium voice synthesis features
"""

import os
import sys
import requests
from pathlib import Path
from typing import Optional

def download_kokoro_tts_models(output_dir: str = "models/kokoro"):
    """
    Download Kokoro TTS models for premium voice synthesis
    
    Args:
        output_dir: Directory to store Kokoro TTS models
    """
    
    try:
        print("🦆 Downloading Kokoro TTS models for premium features...")
        print("=" * 55)
        
        # Create output directory
        os.makedirs(output_dir, exist_ok=True)
        
        # Kokoro TTS model information
        models_to_download = [
            {
                "name": "Kokoro 82M Base Model",
                "url": "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/model.pt",
                "filename": "kokoro_82m.pt",
                "size_mb": 330
            },
            {
                "name": "Kokoro Voice Configs",
                "url": "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/config.json",
                "filename": "kokoro_config.json",
                "size_mb": 0.001
            },
            {
                "name": "Kokoro Tokenizer",
                "url": "https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/tokenizer.json",
                "filename": "kokoro_tokenizer.json", 
                "size_mb": 2
            }
        ]
        
        total_size = sum(model["size_mb"] for model in models_to_download)
        print(f"📦 Total download size: ~{total_size:.1f} MB")
        print("⚠️  Note: Kokoro TTS is for premium features only (WiFi download)")
        print()
        
        # Download each model
        for i, model in enumerate(models_to_download, 1):
            print(f"📥 [{i}/{len(models_to_download)}] Downloading {model['name']}...")
            
            file_path = os.path.join(output_dir, model['filename'])
            
            if download_file(model['url'], file_path):
                file_size_mb = os.path.getsize(file_path) / (1024 * 1024)
                print(f"   ✅ Downloaded: {file_path} ({file_size_mb:.1f} MB)")
            else:
                print(f"   ❌ Failed to download: {model['name']}")
                return False
        
        # Create iOS-specific conversion script
        create_ios_integration_info(output_dir)
        
        # Create Android-specific integration info
        create_android_integration_info(output_dir)
        
        print("\n🎉 Kokoro TTS download complete!")
        print("💡 Integration notes:")
        print("   📱 iOS: Convert .pt to Core ML using MLX Swift framework")
        print("   🤖 Android: Use PyTorch Mobile or convert via ONNX")
        print("   🌐 WiFi Required: Models download on-demand for premium features")
        print("   💾 Cache Locally: Store in app's document directory")
        
        return True
        
    except Exception as e:
        print(f"❌ Download failed: {str(e)}")
        return False

def download_file(url: str, output_path: str) -> bool:
    """Download a file with progress indication"""
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        
        with open(output_path, 'wb') as f:
            downloaded = 0
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    
                    if total_size > 0:
                        progress = (downloaded / total_size) * 100
                        print(f"\r   Progress: {progress:.1f}%", end='', flush=True)
        
        print()  # New line after progress
        return True
        
    except Exception as e:
        print(f"\n   Error downloading {url}: {str(e)}")
        return False

def create_ios_integration_info(output_dir: str):
    """Create iOS integration information file"""
    
    ios_info = """# Kokoro TTS iOS Integration

## Model Conversion for iOS

The Kokoro TTS PyTorch model needs to be converted for iOS using MLX Swift:

### Step 1: Install MLX Swift
```bash
# Add to your iOS project dependencies
// Package.swift
.package(url: "https://github.com/ml-explore/mlx-swift", from: "0.1.0")
```

### Step 2: Convert Model
```swift
// Convert Kokoro model to MLX format
import MLX

func loadKokoroModel() async -> KokoroTTSModel? {
    guard let modelPath = Bundle.main.path(forResource: "kokoro_82m", ofType: "pt") else {
        return nil
    }
    
    // Load MLX model (specific implementation needed)
    return KokoroTTSModel(modelPath: modelPath)
}
```

### Step 3: Integration
- Model size: ~330MB (download on WiFi only)
- Cache in Documents directory
- Use for premium content creation
- Fallback to Kitten TTS if not available

### Performance Expectations
- Quality: Excellent (better than Kitten TTS)
- Speed: 400-600ms inference time
- Memory: ~500MB RAM usage
- Languages: EN, FR, KO, JA, ZH
"""
    
    with open(os.path.join(output_dir, "ios_integration.md"), 'w') as f:
        f.write(ios_info)

def create_android_integration_info(output_dir: str):
    """Create Android integration information file"""
    
    android_info = """# Kokoro TTS Android Integration

## Model Conversion for Android

The Kokoro TTS PyTorch model can be used via PyTorch Mobile:

### Step 1: Add PyTorch Mobile Dependency
```kotlin
// build.gradle
dependencies {
    implementation 'org.pytorch:pytorch_android:1.12.2'
    implementation 'org.pytorch:pytorch_android_torchvision:1.12.2'
}
```

### Step 2: Convert Model (if needed)
```python
# Convert to TorchScript for mobile
import torch

model = load_kokoro_model()
scripted_model = torch.jit.script(model)
scripted_model.save("kokoro_82m_mobile.pt")
```

### Step 3: Integration
```kotlin
// Load and use Kokoro TTS
class KokoroTTSEngine(context: Context) {
    private val module: Module
    
    init {
        val modelPath = assetFilePath(context, "kokoro_82m_mobile.pt")
        module = LiteModuleLoader.load(modelPath)
    }
    
    fun synthesize(text: String): AudioData {
        // Implementation specific to Kokoro model
    }
}
```

### Performance Expectations
- Quality: Excellent (6 language support)
- Speed: 400-600ms inference time  
- Memory: ~500MB RAM usage
- Download: WiFi required for initial download
"""
    
    with open(os.path.join(output_dir, "android_integration.md"), 'w') as f:
        f.write(android_info)

def main():
    """Main download process"""
    
    print("🚀 Kokoro TTS Premium Model Download")
    print("=" * 40)
    
    success = download_kokoro_tts_models("models/kokoro")
    
    if success:
        print("\n✅ All models downloaded successfully!")
    else:
        print("\n❌ Some downloads failed - check logs above")
        sys.exit(1)

if __name__ == "__main__":
    main()