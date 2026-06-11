import wfdb
import numpy as np
from collections import Counter

# Read ECG signal (first channel only)
record = wfdb.rdrecord('../dataset/mitbih/100')
signal = record.p_signal[:, 0]

# Read annotations
annotation = wfdb.rdann('../dataset/mitbih/100', 'atr')
samples = annotation.sample
symbols = annotation.symbol

# Allowed beat labels
allowed_symbols = ['N', 'V', 'A', 'L', 'R']

# Window settings
window_size = 200
half_window = window_size // 2

X = []
y = []

for sample, symbol in zip(samples, symbols):
    if symbol in allowed_symbols:
        start = sample - half_window
        end = sample + half_window

        # Skip if window goes out of bounds
        if start >= 0 and end <= len(signal):
            segment = signal[start:end]
            X.append(segment)
            y.append(symbol)

X = np.array(X)
y = np.array(y)

print("Labeled segments shape:", X.shape)
print("Labels shape:", y.shape)
print("Class distribution:", Counter(y))

from sklearn.preprocessing import LabelEncoder

# Encode labels
encoder = LabelEncoder()
y_encoded = encoder.fit_transform(y)

print("\nEncoded labels example:", y_encoded[:10])
print("Classes:", encoder.classes_)