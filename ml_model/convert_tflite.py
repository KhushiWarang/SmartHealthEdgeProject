import tensorflow as tf
import os

# Load trained model
model = tf.keras.models.load_model("ecg_model.h5")

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]

tflite_model = converter.convert()

# Save converted model
with open("model.tflite", "wb") as f:
    f.write(tflite_model)

# Print sizes
h5_size = os.path.getsize("ecg_model.h5") / 1024
tflite_size = os.path.getsize("model.tflite") / 1024

print("Conversion complete!")
print(f"H5 model size: {h5_size:.2f} KB")
print(f"TFLite model size: {tflite_size:.2f} KB")