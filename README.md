# PredictRAM 🧠💾
**ML-Enhanced SECDED Memory Controller with Adaptive Error Management for DDR4 Systems**

[![Version](https://img.shields.io/badge/version-0.1_alpha-blue.svg)](#version-log)
[![Status](https://img.shields.io/badge/status-PoC_Verified-success.svg)](#current-state--achievements)

## 📖 Project Overview
As DDR4 memory modules push the boundaries of cell density, physical scaling makes them highly susceptible to 'noisy neighbor' interference (Rowhammer) and Variable Retention Time (VRT) degradation. Traditional memory controllers rely on reactive Error Correction Codes (ECC)—acting like an airbag that only deploys *after* a crash (data corruption).

**PredictRAM** introduces a paradigm shift: an ultra-low-area, hardware-accelerated diagnostic engine that acts as a predictive "Check Engine" light. By combining a side-band telemetry pipeline with a custom-transpiled Machine Learning (Random Forest) inference engine, PredictRAM identifies at-risk memory rows and issues preemptive restoration commands before uncorrectable Double-Bit Errors (DBEs) can occur.

---

## 🏗️ System Architecture & Modules
PredictRAM is built on a **Decoupled Diagnostic Topology**. To ensure predictive maintenance does not bottleneck standard memory operations, the system separates the primary data path from the analytical path across three functional domains:

1. **The Primary Datapath (Baseline Controller)**
   * Handles standard memory read/write transactions (AXI4 to DFI PHY) and standard JEDEC Auto-Refresh (`tREFI`).
   * *Note: For the v0.1 PoC, the primary standard datapath is abstracted (black-boxed) to isolate and validate the custom diagnostic silicon.*
2. **Sequential Stage 1: Side-Band SEC-DED Telemetry Engine**
   * A fully pipelined hardware block sitting transparently between the AXI4 frontend and DFI backend. 
   * Uses a mathematically balanced Hsiao (72, 64) code matrix to correct Single-Bit Errors (SBEs) on the fly and extract cycle-accurate error flags (`ml_err_sbe`, `ml_err_dbe`).
   * **Latency:** Introduces exactly 1 clock cycle of delay, with zero latency overhead to valid read cycles.
3. **Combinational Stage 2: Adaptive Error Management Core**
   * **Accumulator (Testbench Emulated in v0.1):** Aggregates raw ECC flags into multi-dimensional macro-counters (e.g., `max_row_hits`, `unique_rows`).
   * **Hybrid ML-Rule Inference Engine:** A purely combinational block that evaluates the aggregated fault patterns. It features parallel deterministic safety rules (for worst-case boundaries) and a 16-bit quantized Random Forest majority voter to trigger preemptive `SCRUB` or `REFRESH` commands.



---

## 🛠️ Tools & Tech Stack
* **Hardware Description:** SystemVerilog (IEEE 1800-2012)
* **Logic Synthesis & Timing Analysis:** Intel Quartus Prime (Targeting Cyclone V `5CGXFC7` for unconstrained I/O routing synthesis; physical deployment targets Terasic DE2-115).
* **RTL Simulation & Verification:** Siemens ModelSim-Altera
* **Machine Learning Pipeline:** Python 3, `pandas`, `scikit-learn` (Random Forest Classifier).
* **Custom Tooling:** Custom Python-to-SystemVerilog transpiler for direct RTL mapping of decision trees.

---

## 📂 Repository Navigation
```text
PredictRAM/
├── hw/                         # Hardware Development Directory
│   ├── rtl/                    # Synthesizable SystemVerilog modules
│   │   ├── ecc_engine/         # Stage 1: Side-band Hsiao (72,64) Telemetry Engine
│   │   │   ├── ecc_engine.sv   # Top-level sequential pipeline
│   │   │   ├── ecc_encoder.sv  # Data encoding sub-module
│   │   │   └── ecc_decoder.sv  # Data decoding and error flagging sub-module
│   │   └── ML_engine/          # Stage 2: Hybrid ML-Rule Inference Logic
│   │       └── ML_engine_RF.sv # Auto-transpiled combinational SV logic (5-tree Random Forest)
│   ├── sim/                    # Verification Environment
│   │   ├── ecc_engine_tb.sv    # 1-cycle handshake verification testbench
│   │   ├── ML_engine_RF_tb.sv  # Priority multiplexing verification testbench
│   │   └── transcripts/        # ModelSim simulation logs and results
│   └── quartus/                # Intel Quartus Prime synthesis project files
│       └── reports/            # .map.rpt and .sta.rpt timing/area reports
├── ml/                         # Software and Machine Learning Directory
│   └── training/               # Python ML training pipeline & custom SV transpiler script
│       └── ml_model_RF.py
├── docs/                       # Technical specifications and Micron Memory Awards proposal
│   └── Correctability_PredictRAM_Proposal.pdf 
└── README.md                   # Project documentation and version logs
