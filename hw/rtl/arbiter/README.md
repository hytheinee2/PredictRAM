# Arbiter
# Arbiter Module

## Overview
The Arbiter module is responsible for selecting which command is sent to the FSM for execution.

It ensures correct command priority and prevents multiple commands from being issued simultaneously.

## Arbitration Priority
1. REFRESH (highest priority)
2. SCRUB
3. FIFO commands (READ / WRITE)

## Functionality
- Accepts command requests from:
  - FIFO (normal READ/WRITE)
  - Refresh timer
  - ML engine (Scrub request)
- Issues only one command at a time
- Waits for FSM to indicate readiness before sending next command
- Pops FIFO only when a FIFO command is accepted

## Interface
Inputs:
- fifo_valid
- fifo_cmd
- refresh_req
- scrub_req
- out_ready (from FSM)

Outputs:
- out_valid
- out_cmd
- fifo_pop

## Verification
Simulated using ModelSim Intel FPGA Edition 20.1.
Waveforms verified for:
- Correct priority handling
- Proper handshake with FSM
