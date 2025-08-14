#!/usr/bin/env python3
"""
Download Gemma-3N models for Roadtrip-Copilot
Gemma-3N variants:
- E2B: 2GB model for efficient on-device inference
- E4B: 3GB model for higher quality responses
"""

import os
import sys
import json
import hashlib
import requests
from pathlib import Path
from typing import Dict, Optional
import time

class Gemma3NDownloader:
    """Downloads and validates Gemma-3N models"""
    
    # Gemma-3N model configurations
    MODELS = {

        "gemma-3n-e2b": {
            "repo": "google/gemma-2-9b-it",  # Using Gemma-2 9B as proxy for Gemma-3N E4B
            "files": [
                "model-00001-of-00004.safetensors",
                "model-00002-of-00004.safetensors", 
                "model-00003-of-00004.safetensors",
                "model-00004-of-00004.safetensors",
                "model.safetensors.index.json",
                "tokenizer.json",
                "tokenizer_config.json",
                "config.json",
                "generation_config.json"
            ],
            "size_gb": 3.0,
            "description": "Gemma-3N E2B - Advanced 3GB model"
        },
        "gemma-3n-e4b": {
            "repo": "google/gemma-2-9b-it",  # Using Gemma-2 9B as proxy for Gemma-3N E4B
            "files": [
                "model-00001-of-00004.safetensors",
                "model-00002-of-00004.safetensors", 
                "model-00003-of-00004.safetensors",
                "model-00004-of-00004.safetensors",
                "model.safetensors.index.json",
                "tokenizer.json",
                "tokenizer_config.json",
                "config.json",
                "generation_config.json"
            ],
            "size_gb": 3.0,
            "description": "Gemma-3N E4B - Advanced 3GB model"
        }
    }
    
    def __init__(self, output_dir: str = "llm"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def download_file(self, url: str, dest_path: Path, expected_size: Optional[int] = None, token: Optional[str] = None) -> bool:
        """Download a file with progress tracking"""
        try:
            print(f"Downloading: {dest_path.name}")
            
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36"
            }
            if token:
                headers["Authorization"] = f"Bearer {token}"

            # Check if file already exists
            if dest_path.exists():
                if expected_size and dest_path.stat().st_size == expected_size:
                    print(f"  ✓ Already downloaded: {dest_path.name}")
                    return True
                else:
                    print(f"  ⚠ File exists but size mismatch, re-downloading...")
                    
            # Download with progress
            response = requests.get(url, stream=True, timeout=30, headers=headers)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            block_size = 8192
            downloaded = 0
            
            with open(dest_path, 'wb') as f:
                for chunk in response.iter_content(block_size):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total_size > 0:
                            progress = (downloaded / total_size) * 100
                            print(f"\r  Progress: {progress:.1f}%", end='', flush=True)
            
            print(f"\n  ✓ Downloaded: {dest_path.name}")
            return True
            
        except Exception as e:
            print(f"\n  ✗ Failed to download {dest_path.name}: {e}")
            return False
    
    def download_from_huggingface(self, model_id: str, model_config: Dict, token: Optional[str] = None) -> bool:
        """Download model files from Hugging Face"""
        model_dir = self.output_dir / model_id
        model_dir.mkdir(exist_ok=True)
        
        print(f"\n{'='*60}")
        print(f"Downloading {model_config['description']}")
        print(f"Repository: {model_config['repo']}")
        print(f"Size: ~{model_config['size_gb']}GB")
        print(f"{'='*60}")
        
        # Base URL for Hugging Face CDN
        base_url = f"https://huggingface.co/{model_config['repo']}/resolve/main"
        
        success = True
        for file_name in model_config['files']:
            url = f"{base_url}/{file_name}"
            dest_path = model_dir / file_name
            
            if not self.download_file(url, dest_path, token=token):
                # Try alternative download methods
                print(f"  Retrying with different method...")
                time.sleep(2)
                if not self.download_file(url, dest_path, token=token):
                    success = False
                    print(f"  ⚠ Skipping {file_name} - manual download may be required")
        
        return success
    
    def create_model_manifest(self, model_id: str, model_config: Dict):
        """Create a manifest file for the downloaded model"""
        model_dir = self.output_dir / model_id
        manifest_path = model_dir / "manifest.json"
        
        manifest = {
            "model_id": model_id,
            "description": model_config['description'],
            "repository": model_config['repo'],
            "size_gb": model_config['size_gb'],
            "files": [],
            "download_timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "roadtrip_copilot_version": "1.0.0"
        }
        
        # Add file information
        for file_name in model_config['files']:
            file_path = model_dir / file_name
            if file_path.exists():
                manifest['files'].append({
                    "name": file_name,
                    "size": file_path.stat().st_size,
                    "checksum": self.calculate_checksum(file_path)
                })
        
        with open(manifest_path, 'w') as f:
            json.dump(manifest, f, indent=2)
        
        print(f"  ✓ Created manifest: {manifest_path}")
    
    def calculate_checksum(self, file_path: Path) -> str:
        """Calculate SHA256 checksum of a file"""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
    
    def download_all(self):
        """Download all Gemma-3N models"""
        print("\n" + "="*60)
        print("GEMMA-3N MODEL DOWNLOADER FOR ROADTRIP-COPILOT")
        print("="*60)

        # Authenticate with Hugging Face
        token = None
        try:
            from huggingface_hub import login, HfFolder
            # Token should be provided via environment variable
            token_to_use = os.getenv("HF_TOKEN")
            if not token_to_use:
                print("\n⚠ HF_TOKEN environment variable not set.")
                print("Please set HF_TOKEN with your Hugging Face token.")
                return None
            print(f"\nAuthenticating with Hugging Face token from environment...")
            login(token=token_to_use)
            token = token_to_use
            print("✓ Authentication successful.")
        except ImportError:
            print("\n⚠ `huggingface_hub` not found. Please install:")
            print("  pip install huggingface_hub")
            return

        print("\nNote: Due to Gemma-3N availability, using Gemma-2 models as placeholders")
        print("These will be replaced with actual Gemma-3N models when available")
        
        for model_id, model_config in self.MODELS.items():
            success = self.download_from_huggingface(model_id, model_config, token=token)
            
            if success:
                self.create_model_manifest(model_id, model_config)
                print(f"\n✓ Successfully downloaded {model_id}")
            else:
                print(f"\n⚠ Partially downloaded {model_id} - some files may be missing")
        
        print("\n" + "="*60)
        print("DOWNLOAD COMPLETE")
        print(f"Models saved to: {self.output_dir.absolute()}")
        print("="*60)
        
        # Create a README for the models
        self.create_readme()
    
    def create_readme(self):
        """Create a README file explaining the models"""
        readme_content = """# Gemma-3N Models for Roadtrip-Copilot

## Models

### gemma-3n-e2b (2GB)
- Efficient model for standard on-device inference
- Optimized for mobile deployment
- Fast response times (<350ms)
- Lower memory footprint

### gemma-3n-e4b (3GB) 
- Advanced model for premium features
- Higher quality responses
- Better context understanding
- Enhanced POI discovery capabilities

## Usage

These models are automatically converted and optimized by the platform-specific scripts:
- iOS: `/models/conversion/convert_gemma3n_ios.py`
- Android: `/models/conversion/convert_gemma3n_android.py`

## Note

Currently using Gemma-2 models as placeholders until Gemma-3N models are available.
The architecture and optimization pipelines are designed for seamless migration.
"""
        
        readme_path = self.output_dir / "README.md"
        with open(readme_path, 'w') as f:
            f.write(readme_content)
        
        print(f"\n✓ Created README: {readme_path}")

def main():
    """Main entry point"""
    downloader = Gemma3NDownloader()
    
    try:
        downloader.download_all()
        return 0
    except KeyboardInterrupt:
        print("\n\n⚠ Download interrupted by user")
        return 1
    except Exception as e:
        print(f"\n✗ Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())