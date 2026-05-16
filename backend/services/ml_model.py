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

# load once at startup
model = None
class_labels = None

def load_model_once():

    global model, class_labels

    if model is None:

        model = tf.keras.models.load_model(
            MODEL_PATH,
            custom_objects={
                "ChannelAttention": ChannelAttention
            }
        )

        with open(LABELS_PATH, 'r') as f:
            class_labels = json.load(f)

        print("Model loaded successfully")

def predict_food(img_array: np.ndarray) -> tuple:

    load_model_once()

    predictions = model.predict(img_array, verbose=0)

    class_idx = np.argmax(predictions[0])

    confidence = float(predictions[0][class_idx])

    food_label = class_labels[str(class_idx)]

    return food_label, confidence