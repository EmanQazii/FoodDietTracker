import numpy as np
import tensorflow as tf
import json
import os

from ml.custom_layers import ChannelAttention

MODEL_PATH = os.path.join(
    os.path.dirname(__file__),
    '../ml/saved_model/best_finetuned_v3.h5'
)

LABELS_PATH = os.path.join(
    os.path.dirname(__file__),
    '../ml/class_labels.json'
)

CONFIDENCE_THRESHOLD = 0.45

model = None
class_labels = None

def load_model_once():
    global model, class_labels
    if model is None:
        model = tf.keras.models.load_model(
            MODEL_PATH,
            custom_objects={"ChannelAttention": ChannelAttention}
        )
        with open(LABELS_PATH, 'r') as f:
            class_labels = json.load(f)
        print("Model loaded successfully")

# modify predict_food to return raw predictions too
def predict_food(img_array: np.ndarray) -> tuple:
    load_model_once()
    predictions = model.predict(img_array, verbose=0)
    class_idx = np.argmax(predictions[0])
    confidence = float(predictions[0][class_idx])

    if confidence < CONFIDENCE_THRESHOLD:
        return "unknown", confidence, predictions[0]   # added predictions[0]

    food_label = class_labels[str(class_idx)]
    return food_label, confidence, predictions[0]      # added predictions[0]


# add this new function below predict_food
def get_top3_predictions(raw_predictions: np.ndarray) -> list:
    load_model_once()
    top3_indices = np.argsort(raw_predictions)[::-1][:3]
    result = []
    for idx in top3_indices:
        label = class_labels[str(idx)]
        result.append({
            "food_label": label,
            "food_name": label.replace("_", " ").title(),
            "confidence": round(float(raw_predictions[idx]) * 100, 2)
        })
    return result