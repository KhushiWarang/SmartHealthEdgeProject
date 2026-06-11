import numpy as np
import wfdb
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from collections import Counter
import joblib

import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv1D, MaxPooling1D, Flatten, Dense

# -------- Load data --------
record = wfdb.rdrecord('../dataset/mitbih/100')
signal = record.p_signal[:, 0]

annotation = wfdb.rdann('../dataset/mitbih/100', 'atr')
samples = annotation.sample
symbols = annotation.symbol

allowed_symbols = ['N', 'V', 'A']

window_size = 200
half_window = window_size // 2

X = []
y = []

for sample, symbol in zip(samples, symbols):
    if symbol in allowed_symbols:
        start = sample - half_window
        end = sample + half_window

        if start >= 0 and end <= len(signal):
            segment = signal[start:end]
            X.append(segment)
            y.append(symbol)

X = np.array(X)
y = np.array(y)

print("Original class distribution:", Counter(y))

# -------- Encode labels --------
encoder = LabelEncoder()
y_encoded = encoder.fit_transform(y)

# -------- Normalize --------
X = X / np.max(np.abs(X))

# -------- Reshape for CNN --------
X = X.reshape(X.shape[0], X.shape[1], 1)

# -------- Train-test split --------
X_train, X_test, y_train, y_test = train_test_split(
    X, y_encoded, test_size=0.2, random_state=42
)

np.save("X_test.npy", X_test)
np.save("y_test.npy", y_test)
joblib.dump(encoder, "label_encoder.pkl")

# -------- Model --------
model = Sequential([
    Conv1D(32, 3, activation='relu', input_shape=(200,1)),
    MaxPooling1D(2),
    Conv1D(64, 3, activation='relu'),
    MaxPooling1D(2),
    Flatten(),
    Dense(64, activation='relu'),
    Dense(len(np.unique(y_encoded)), activation='softmax')
])

model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# -------- Train --------
model.fit(X_train, y_train, epochs=10, batch_size=32)

# -------- Evaluate --------
loss, acc = model.evaluate(X_test, y_test)
print("Test Accuracy:", acc)

# -------- Save model --------
model.save("ecg_model.h5")