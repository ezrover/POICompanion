# Model Optimizer

This tool optimizes AI models for different platforms and optimization types.

## Usage

```bash
node model-optimizer <model_path> <platform> <optimization_type>
```

-   `<model_path>`: The path to the AI model file.
-   `<platform>`: The target platform (e.g., `ios`, `android`, `edge`).
-   `<optimization_type>`: The type of optimization (e.g., `quantization`, `pruning`, `conversion`).

## Example

```bash
node model-optimizer models/llm.tflite android quantization
```
