import wfdb
import matplotlib.pyplot as plt

# Record 100 load 
record = wfdb.rdrecord('../dataset/mitbih/100')

# ECG signal extract
signal = record.p_signal

print("Signal shape:", signal.shape)

# first channel plot karenge 
plt.plot(signal[:1000, 0])   # 0 = first ECG lead
plt.title("ECG Signal (Record 100)")
plt.xlabel("Time")
plt.ylabel("Amplitude")
plt.show()