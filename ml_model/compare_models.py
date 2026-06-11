import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import load_model
from sklearn.metrics import accuracy_score

print("Running H5 vs TFLite comparison...")

# -----------------------------
# Load saved test set
# -----------------------------
X_test = np.load("X_test.npy").astype(np.float32)
y_test = np.load("y_test.npy")

# -----------------------------
# H5 model evaluation
# -----------------------------
h5_model = load_model("ecg_model.h5")
h5_probs = h5_model.predict(X_test, verbose=0)
h5_preds = np.argmax(h5_probs, axis=1)
h5_acc = accuracy_score(y_test, h5_preds)

# -----------------------------
# TFLite model evaluation
# -----------------------------
interpreter = tf.lite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

tflite_preds = []

for i in range(len(X_test)):
    sample_input = X_test[i:i+1]
    interpreter.set_tensor(input_details[0]['index'], sample_input)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])
    predicted_class = np.argmax(output[0])
    tflite_preds.append(predicted_class)

tflite_preds = np.array(tflite_preds)
tflite_acc = accuracy_score(y_test, tflite_preds)

# -----------------------------
# Size comparison
# -----------------------------
h5_size = os.path.getsize("ecg_model.h5") / 1024
tflite_size = os.path.getsize("model.tflite") / 1024

# -----------------------------
# Final output
# -----------------------------
print("\n===== FINAL COMPARISON =====")
print(f"H5 Accuracy        : {h5_acc:.4f}")
print(f"TFLite Accuracy    : {tflite_acc:.4f}")
print(f"Accuracy Difference: {h5_acc - tflite_acc:.4f}")
print(f"H5 Size            : {h5_size:.2f} KB")
print(f"TFLite Size        : {tflite_size:.2f} KB")
