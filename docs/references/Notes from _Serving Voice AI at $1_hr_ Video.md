# Notes from "Serving Voice AI at $1/hr" Video

## Introduction to Gabber and Real-Time AI
- Gabber provides a backend platform for AI personas (companions, NPCs, tutors).
- Focus on low latency and continuity for real-time voice AI.
- Goal: $1 per hour cost for serving voice AI.

## Technical Challenges and Solutions
### Initial Problem: Head-of-Line Silence
- Used open-source Orpheus TTS model.
- Encountered 600ms of initial silence, negatively impacting real-time experience.

### Solution 1: LoRa Fine-tuning
- Successfully fine-tuned to remove silence, reducing latency to ~350ms.
- Enabled high-fidelity, emotive voice clones from small datasets.

### Solution 2: Efficient Inference with vLLM
- Utilized vLLM on L40S GPUs for efficient and affordable inference.
- Supports batch inference with multiple different LoRAs.
- Achieved >100 tokens/second using FP8 dynamic quantization, faster than real-time on cost-effective hardware.

### Solution 3: Load Balancing with Consistent Hash Ring
- Implemented a consistent hash ring for sticky sessions.
- Ensures sessions with specific cloned voices (LoRa) remain on the same server.
- Prevents latency spikes from loading LoRAs on new servers.

## Key Takeaways
- Open-source tools and techniques enable small teams to build and host high-quality, low-latency voice AI.
- Shoutouts to Swyx, CanopyLabs, LiveKit, and vLLM for their contributions.

