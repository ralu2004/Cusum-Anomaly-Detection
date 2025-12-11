# Cusum-Anomaly-Detection

![Language](https://img.shields.io/badge/languages-VHDL%20%7C%20Python-blue)
![Status](https://img.shields.io/badge/status-active-green)

## 📌 Overview
A hardware-software co-design of the **CUSUM (Cumulative Sum)** streaming anomaly detector. This repository includes:
* **Hardware Modules:** A synthesizable VHDL implementation of the CUSUM algorithm.
* **Software Reference:** A Python implementation serving as the "golden model."
* **Validation Tools:** Scripts to compare hardware simulation outputs against software results to verify correctness.

The system is designed to detect anomalies in streaming time-series data (e.g., temperature measurements) by monitoring deviations from a target mean.

## 📂 Repository Structure

```text
Cusum-Anomaly-Detection/
├── comparison/                  # Validation tools
│   ├── hardware_detection_output/ # Output logs from VHDL simulation
│   ├── software_detection_outputs/# Output logs from Python script
│   └── compare_outputs.py       # Script to cross-verify HW vs SW results
│
├── hardware_sources/            # VHDL Design Files (Vivado Project Structure)
│   └── sources_1/new/
│       ├── top.vhd              # Top-level module connecting components
│       ├── cusum.vhd            # Core CUSUM algorithm logic
│       ├── cusum_with_feedback.vhd
│       ├── counter.vhd          # Address counter for ROM/Data stream
│       ├── rom_memory.vhd       # Stores test data (temperature values)
│       ├── threashold_comp.vhd  # Logic for threshold comparison
│       └── max.vhd              # Max function implementation
│
├── software_sources/            # Python Reference Implementation
│   ├── binary_values/           # Converted binary data for HW testing
│   ├── integer_values/          # Standard integer data
│   ├── 04-12-22_temperature_measurements.csv # Raw dataset
│   ├── convert_to_binary.py     # Tool to convert CSV data to binary for VHDL
│   └── cusum.py                 # Pure Python CUSUM implementation
│
└── README.md
