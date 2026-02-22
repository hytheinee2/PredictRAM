# Controller FSM
# FSM Module (DDR Timing Control)

## Overview
The FSM (Finite State Machine) controls DDR-style command sequencing and enforces timing constraints.

It generates DFI command signals for ACT, READ, WRITE, PRECHARGE, and REFRESH operations.

## FSM Flow

### READ / WRITE / SCRUB
IDLE → ACT → WAIT_TRCD → RD/WR → WAIT_CL → PRE → WAIT_TRP → IDLE

### REFRESH
IDLE → REF → WAIT_TRFC → IDLE

## Features
- Command latching in IDLE state
- DDR timing counters:
  - tRCD
  - CL
  - tRP
  - tRFC
- DFI signal generation:
  - CS#
  - RAS#
  - CAS#
  - WE#
  - CKE

## Design Assumptions
- Single-bank simplified model (for initial proof-of-concept)
- Conservative timing parameters used for simulation

## Verification
- Simulated using ModelSim Intel FPGA Edition 20.1
- State transitions verified via waveform
- DFI command encoding confirmed correct
