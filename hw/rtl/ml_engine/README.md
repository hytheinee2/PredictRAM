# ML Model 

---

Dataset used: mcelog.csv includes the DRAM errors collected via mcelog in 8 columns.  
<img width="940" height="460" alt="image" src="https://github.com/user-attachments/assets/ba2936d4-e7bb-4f21-8156-b5ea24fe0d94" />  
https://tianchi.aliyun.com/dataset/132973/  
<br>
<br>
<img width="940" height="140" alt="image" src="https://github.com/user-attachments/assets/3918eef9-2fc8-445a-bce3-e3463a566587" />

The datatype of error_time in the dataset is in format YYYY-MM-DD hh:mm:ss. The datatype was changed to string and sorted by ascending order. Time index (time_idx) was assigned.                         
<br>
<img width="559" height="95" alt="image" src="https://github.com/user-attachments/assets/77465b55-e744-4355-973e-8b26c9f013cd" />  \
The dataset is grouped by: sid(Server ID), memoryid, rankid, bankid. The for loop will loop through each group that have unique sid, memoryid, rankid and bankid. Each group is sorted by time_idx.  
<br>
<img width="723" height="436" alt="image" src="https://github.com/user-attachments/assets/f1331541-58c5-4a14-b13f-c621f602746b" />
<img width="402" height="309" alt="image" src="https://github.com/user-attachments/assets/7cf95dc7-a72b-4206-b635-85ac3779e393" />  

These are the features of the ml model. 
- row_counts and col_counts are the number times each unique row/column appears.
-	unique_rows and unique_cols are the number of distinct row/column that had errors
-	max_row_hits and max_col_hits finds the highest number of errors in a single row/column.
-	error_rate is the error over time for a group of unique sid, memoryid, rankid, bankid
<br>
<img width="714" height="202" alt="image" src="https://github.com/user-attachments/assets/814ba01a-8e02-495b-9dd2-57dbb88201d6" />
<img width="578" height="134" alt="image" src="https://github.com/user-attachments/assets/8258a612-1b74-410f-8996-d8afb0b4a590" />
<br>
<br>
Normalise the features (Values between 0 and 1)  
<img width="816" height="402" alt="image" src="https://github.com/user-attachments/assets/76a62add-8b86-4230-8aed-48d47bcdf36a" />

3-layer fully connected neural network.
First layer:
-	16 neurons
-	ReLU activation function
-	Input shape = number of features in X_norm (9)
Second layer:
-	8 neurons
-	ReLU activation
Third layer:
-	3 neurons (Corresponds to 3 classes, Scrub, Refresh, No Action)
-	Softmax activation (Converts 3 classes into probability which sum to 1)
<br>

## Training of the ml model:
<img width="667" height="455" alt="image" src="https://github.com/user-attachments/assets/29c8eabe-ddb8-4c24-9cf7-3d339731778c" />  


The data was divided to 20% test data, 80% training data. 

Decision logic 
An array with 3 elements is the output of the ml model. 
-	First element: Probability of no action taken (p_no_action)
-	Second element: Probability of Scrub (p_scrub)
-	Third element: Probability of Refresh (p_refresh)  

if (p_scrub   > p_no_action && p_scrub > p_refresh) \
    action = SCRUB; \
else if (p_refresh > p_scrub && p_refresh > p_no_action) \
    action = REFRESH; \
else  \
    action = NO_ACTION;




# PredictRAM: Hybrid ML Engine for DRAM Error Mitigation

PredictRAM is a hardware-software co-designed system that utilizes a Hybrid Machine Learning Engine to dynamically predict, manage, and mitigate DRAM memory errors. By combining the adaptive predictive power of a Random Forest classifier with a hard-coded "Safety Layer" of expert rules, the engine determines the optimal memory maintenance action in real-time.

## Project Overview

Modern DRAM faces challenges like Rowhammer and variable retention times. PredictRAM addresses this by monitoring error rates, hit counts, and unique access patterns to issue commands like `SCRUB` or `REFRESH`.

The system trains a machine learning model on memory error logs (such as `mcelog`), exports the learned decision trees directly into SystemVerilog, and wraps them in deterministic hardware rules to guarantee system reliability.

## Repository Contents

* **`ml_model.py` & `ml_model_RF.py**`: Python scripts used to process DRAM error datasets, train neural network and Random Forest classification models, and automatically generate the SystemVerilog hardware description.
* **`ML_engine_RF.sv`**: The generated SystemVerilog core module. It contains multiple parallel decision trees, majority voter logic, and the safety rule layer.


* 
**`ML_engine_RF_tb.sv`**: The SystemVerilog testbench used to validate the module against boundary conditions and pure ML-domain decisions.


* 
**`simulation_transcript_ML_engine_modelsim_altera.txt`**: The simulation transcript verifying the design compiles and simulates with zero errors or warnings.



---

## Hardware Interface (`ML_engine_RF.sv`)

The core engine takes in 16-bit performance and error metrics and outputs a 2-bit decision.

**Inputs:**

* 
`total_errors`: Total logged errors for a given memory group.


* 
`read_errors`: Number of read-related errors.


* 
`write_errors`: Number of write-related errors.


* 
`scrub_errors`: Number of scrub-related errors.


* 
`unique_rows`: Count of unique rows accessed.


* 
`unique_cols`: Count of unique columns accessed.


* 
`max_row_hits`: Maximum hits on a single row (Rowhammer indicator).


* 
`max_col_hits`: Maximum hits on a single column.


* 
`error_rate_int`: Calculated error rate over time.



**Outputs:**

* 
`final_action`: The 2-bit mitigation decision.


* 
`0`: NO_ACTION.


* 
`1`: SCRUB.


* 
`2`: REFRESH.



---

## Architecture: The Hybrid Approach

The engine achieves high reliability by running two decision paths in parallel:

1. 
**Parallel Expert Rules (Safety Layer)**: Hard-coded thresholds evaluate conditions critical to memory integrity. For example, if `max_row_hits` is 64 or greater, or if the ratio of unique rows to total errors triggers a threshold, the system will force a `SCRUB` action. If the error rate is high alongside multiple unique column hits, it forces a `REFRESH`.


2. 
**ML Majority Voter Logic**: If the hard-coded rules are not triggered, the Random Forest model takes over. It runs the input parameters through parallel decision trees (Tree 0 to Tree 4) and uses a majority voting system to determine the final action.



The hard rules will always override the ML vote if triggered, guaranteeing system reliability even in unpredictable edge cases.

---

## Simulation & Testing

The module was successfully compiled and tested using ModelSim - Intel FPGA Edition vlog 2020.1.

The testbench validates the logic across several distinct scenarios:

* 
**All Zeros**: Validates baseline behavior.


* 
**RowHits Edge (64)**: Tests the exact boundary for a forced scrub.


* 
**Ratio Rule (<0.2)**: Tests the integer-math unique rows vs. total errors rule.


* 
**Ratio Edge (=0.2)**: Tests the boundary condition of the ratio rule.


* 
**Rate+Col Edge**: Tests the boundary for a forced refresh.


* 
**High Rate/Low Col**: Verifies the hand-off to the ML logic when a hard rule is narrowly missed.


* 
**ML pure decision**: Evaluates the Random Forest output under low-level noise conditions.


---


