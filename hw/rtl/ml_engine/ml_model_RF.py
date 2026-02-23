import os
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

# ==========================================
# 1. DATA PREPARATION (WITH FAILSAFE)
# ==========================================
csv_path = 'D:\data\mcelog\mcelog.csv'

try:
    print(f"Attempting to load data from {csv_path}...")
    df = pd.read_csv(csv_path, low_memory=False, nrows=1_000_000)
    df['error_time'] = df['error_time'].astype(str)
    df = df.sort_values('error_time')
    df['time_idx'] = range(len(df))
    df = df.drop_duplicates(
        subset=['sid','memoryid','rankid','bankid','row','col','error_time','error_type']
    )
    print("Data loaded successfully.")
except FileNotFoundError:
    print("WARNING: mcelog.csv not found. Generating synthetic DRAM error data to proceed...")
    # Synthetic data generation so the script NEVER fails
    np.random.seed(42)
    n_samples = 5000
    df = pd.DataFrame({
        'sid': np.random.randint(0, 2, n_samples),
        'memoryid': np.random.randint(0, 4, n_samples),
        'rankid': np.random.randint(0, 2, n_samples),
        'bankid': np.random.randint(0, 16, n_samples),
        'row': np.random.randint(0, 65536, n_samples),
        'col': np.random.randint(0, 1024, n_samples),
        'error_type': np.random.choice([1, 2, 3], n_samples),
        'time_idx': np.sort(np.random.randint(0, 100000, n_samples))
    })

features, labels = [], []
grp = ['sid', 'memoryid', 'rankid','bankid']

for _, g in df.groupby(grp):
    g = g.sort_values('time_idx')
    total_errors = len(g)
    read_errors  = (g['error_type'] == 1).sum()
    scrub_errors = (g['error_type'] == 2).sum()
    write_errors = (g['error_type'] == 3).sum()

    row_counts  = g['row'].value_counts()
    col_counts = g['col'].value_counts()

    unique_rows   = row_counts.size
    unique_cols  = col_counts.size
    max_row_hits  = row_counts.max()
    max_col_hits = col_counts.max()

    time_span = g['time_idx'].max() - g['time_idx'].min() + 1
    error_rate_int = int((total_errors / time_span) * 1000) 

    if max_row_hits >= 64 or (unique_rows/total_errors) < 0.2:
        label = 1  # SCRUB
    elif error_rate_int >= 50 and unique_cols >= 8:
        label = 2  # REFRESH
    else:
        label = 0  # NO_ACTION

    features.append([
        total_errors, read_errors, write_errors, scrub_errors,
        unique_rows, unique_cols, max_row_hits, max_col_hits, error_rate_int
    ])
    labels.append(label)

X = np.array(features)
y = np.array(labels)

# ==========================================
# 2. TRAIN RANDOM FOREST (NO NORMALIZATION)
# ==========================================
print("\nTraining Random Forest Model...")
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Added class_weight='balanced' to prevent the model from ignoring the REFRESH label
# Increased max_depth slightly to give error_rate a chance to be evaluated
rf_model = RandomForestClassifier(n_estimators=5, max_depth=6, class_weight='balanced', random_state=42)
rf_model.fit(X_train, y_train)

print(f"Model Accuracy on Test Set: {rf_model.score(X_test, y_test):.4f}")

from sklearn.metrics import classification_report
y_pred = rf_model.predict(X_test)
print(classification_report(y_test, y_pred, target_names=['NO_ACTION', 'SCRUB', 'REFRESH']))

# ==========================================
# 3. EXPORT TO SYSTEMVERILOG / VERILOG
# ==========================================
feature_names = [
    "total_errors", "read_errors", "write_errors", "scrub_errors",
    "unique_rows", "unique_cols", "max_row_hits", "max_col_hits", "error_rate_int"
]

def tree_to_sv(tree, feature_names, tree_id):
    tree_ = tree.tree_
    feature_name = [feature_names[i] if i != -2 else "undefined!" for i in tree_.feature]
    
    lines = [f"// Tree {tree_id}"]
    lines.append(f"always_comb begin")  # Upgraded to SystemVerilog always_comb
    
    def recurse(node, depth):
        indent = "  " * (depth + 1)
        if tree_.feature[node] != -2:
            threshold = int(tree_.threshold[node])
            name = feature_name[node]
            lines.append(f"{indent}if ({name} <= {threshold}) begin")
            recurse(tree_.children_left[node], depth + 1)
            lines.append(f"{indent}end else begin")
            recurse(tree_.children_right[node], depth + 1)
            lines.append(f"{indent}end")
        else:
            class_idx = np.argmax(tree_.value[node][0])
            lines.append(f"{indent}vote_{tree_id} = 2'd{class_idx};")

    recurse(0, 0)
    lines.append("end\n")
    return "\n".join(lines)

def generate_rf_sv(rf, feature_names, filename="ML_engine_RF.sv"):
    num_trees = len(rf.estimators_)
    print(f"\nGenerating SystemVerilog hardware description: {filename}")
    
    with open(filename, "w") as f:
        f.write("module ML_engine_RF (\n")
        # Upgraded inputs to SV 'logic' type
        for name in feature_names:
            f.write(f"    input  logic [15:0] {name},\n")
        f.write("    output logic [1:0]  final_action\n")
        f.write(");\n\n")
        
        # Upgraded internal signals to SV 'logic'
        for i in range(num_trees):
            f.write(f"logic [1:0] vote_{i};\n")
        f.write("\n")
        
        for i, tree in enumerate(rf.estimators_):
            f.write(tree_to_sv(tree, feature_names, i))
            
        f.write("// Majority Voter Logic\n")
        f.write("logic [3:0] count_0, count_1, count_2;\n")
        f.write("logic [1:0] hard_rule_action;\n")
        f.write("logic [1:0] ml_vote;\n")
        f.write("always_comb begin\n")
        f.write("  count_0 = 4'd0; count_1 = 4'd0; count_2 = 4'd0;\n")
        
        for i in range(num_trees):
            # Added 4'd1 to fix the 32-bit truncation warning!
            f.write(f"  if (vote_{i} == 2'd0) count_0 = count_0 + 4'd1;\n")
            f.write(f"  if (vote_{i} == 2'd1) count_1 = count_1 + 4'd1;\n")
            f.write(f"  if (vote_{i} == 2'd2) count_2 = count_2 + 4'd1;\n")
            
        f.write("\n  // --- PARALLEL EXPERT RULES (SAFETY LAYER) ---\n")
        
        f.write("  // Note: (unique_rows/total_errors) < 0.2 converted to integer math to avoid division\n")
        f.write("  if (max_row_hits >= 64 || (unique_rows * 5 < total_errors)) begin\n")
        f.write("    hard_rule_action = 2'd1; // SCRUB\n")
        f.write("  end else if (error_rate_int >= 50 && unique_cols >= 8) begin\n")
        f.write("    hard_rule_action = 2'd2; // REFRESH\n")
        f.write("  end else begin\n")
        f.write("    hard_rule_action = 2'd0; // NO_ACTION\n")
        f.write("  end\n\n")

        f.write("  // --- FINAL DECISION MULTIPLEXER ---\n")
        
        f.write("  if (count_1 >= count_0 && count_1 >= count_2)\n")
        f.write("    ml_vote = 2'd1; // SCRUB\n")
        f.write("  else if (count_2 >= count_0 && count_2 >= count_1)\n")
        f.write("    ml_vote = 2'd2; // REFRESH\n")
        f.write("  else\n")
        f.write("    ml_vote = 2'd0; // NO_ACTION\n\n")

        f.write("  // Hard rules override ML if triggered, guaranteeing reliability\n")
        f.write("  final_action = (hard_rule_action != 2'd0) ? hard_rule_action : ml_vote;\n")
        f.write("end\n\n")
        f.write("endmodule\n")

    print(f"Success! SystemVerilog file '{filename}' is ready.")

# Make sure to call the new function at the very end of your script!
generate_rf_sv(rf_model, feature_names, filename="ML_engine_RF.sv")