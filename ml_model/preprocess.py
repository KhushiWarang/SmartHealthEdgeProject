import wfdb
import numpy as np

# Record read
record = wfdb.rdrecord('../dataset/mitbih/100')
signal = record.p_signal[:, 0]  # only first channel

# Normalize
signal = signal / np.max(np.abs(signal))

# Segmentation function
def create_segments(signal, window_size=200):
    segments = []
    for i in range(0, len(signal) - window_size, window_size):
        segment = signal[i:i+window_size]
        segments.append(segment)
    return np.array(segments)

# Create segments
segments = create_segments(signal)

print("Segments shape:", segments.shape)
