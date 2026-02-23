# -*- coding: utf-8 -*-
"""
Created on Tue Feb 10 13:37:41 2026

@author: Acer
"""

import numpy as np
import pandas as pd
import tensorflow as tf
df = pd.read_csv(
    "D:/dramdata/data/mcelog/mcelog.csv",
    low_memory=False,
    nrows=1_000_000  # start with a chunk
)
df['error_time'] = df['error_time'].astype(str)
df = df.sort_values('error_time')
df['time_idx'] = range(len(df))
df = df.drop_duplicates(
    subset=['sid','memoryid','rankid','bankid','row','col','error_time','error_type']
)

features = []
labels = []

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
    error_rate = total_errors / time_span

    # ---------- LABEL LOGIC ----------
    if max_row_hits >= 64 or (unique_rows/total_errors)<0.2:
        label = 1  # SCRUB
    elif error_rate >= 0.05 and unique_cols >= 8:
        label = 2  # REFRESH
    else:
        label = 0  # NO_ACTION
        
    features.append([
                  total_errors,
                    read_errors,
                    write_errors,
                    scrub_errors,
                    unique_rows,
                    unique_cols,
                    max_row_hits,
                    max_col_hits,
                    error_rate
                ])
    labels.append(label)
X = np.array(features)
y = np.array(labels)
X_min = X.min(axis=0)
X_max = X.max(axis=0)
X_norm = (X - X_min) / (X_max - X_min + 1e-6)
np.save("X_min.npy", X_min)
np.save("X_max.npy", X_max)

from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense
from tensorflow.keras.utils import to_categorical
model = Sequential([
    Dense(16, activation='relu', input_shape=(X_norm.shape[1],)),
    Dense(8, activation='relu'),
    Dense(3, activation='softmax')
])

model.compile(
    optimizer='adam',
    loss='categorical_crossentropy',
    metrics=['accuracy']
)


from sklearn.model_selection import train_test_split
y_cat = to_categorical(y, num_classes=3)
X_train, X_test, y_train, y_test = train_test_split(
    X_norm, y_cat, test_size=0.2, random_state=42
)

model.fit(
    X_train,
    y_train,
    epochs=10,
    batch_size=256,
    validation_data=(X_test, y_test)
)

loss, acc = model.evaluate(X_test, y_test)
print("Test Accuracy:", acc)
