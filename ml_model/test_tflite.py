import numpy as np
import tensorflow as tf
import joblib
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

# -----------------------------
# Load saved test set + encoder
# -----------------------------
X_test = np.load("X_test.npy").astype(np.float32)
y_test = np.load("y_test.npy")
encoder = joblib.load("label_encoder.pkl")

# -----------------------------
# Load TFLite model
# -----------------------------
interpreter = tf.lite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input details:", input_details)
print("Output details:", output_details)

# -----------------------------
# Predict all samples
# -----------------------------
tflite_preds = []

for i in range(len(X_test)):
    sample_input = X_test[i:i+1]

    interpreter.set_tensor(input_details[0]['index'], sample_input)
    interpreter.invoke()

    output = interpreter.get_tensor(output_details[0]['index'])
    predicted_class = np.argmax(output)
    tflite_preds.append(predicted_class)

tflite_preds = np.array(tflite_preds)

# -----------------------------
# Evaluate
# -----------------------------
acc = accuracy_score(y_test, tflite_preds)
print("\nTFLite Accuracy:", acc)

print("\nConfusion Matrix:")
print(confusion_matrix(y_test, tflite_preds))

print("\nClassification Report:")
print(classification_report(y_test, tflite_preds, zero_division=0))
