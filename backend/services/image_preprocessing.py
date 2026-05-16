import cv2
import numpy as np
from PIL import Image
import io

def load_image_from_bytes(image_bytes: bytes) -> np.ndarray:
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    return cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

def resize_image(img: np.ndarray, size=(224, 224)) -> np.ndarray:
    return cv2.resize(img, size)

def clahe_equalization(img: np.ndarray) -> np.ndarray:
    lab = cv2.cvtColor(img, cv2.COLOR_RGB2LAB)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    lab[:, :, 0] = clahe.apply(lab[:, :, 0])
    return cv2.cvtColor(lab, cv2.COLOR_LAB2RGB)

def apply_gaussian_blur(img: np.ndarray) -> np.ndarray:
    return cv2.GaussianBlur(img, (5, 5), 0)

def compute_psnr(original: np.ndarray, processed: np.ndarray) -> float:
    orig = original.astype(np.float64)
    proc = processed.astype(np.float64)
    mse = np.mean((orig - proc) ** 2)
    if mse == 0:
        return 100.0
    return round(20 * np.log10(255.0 / np.sqrt(mse)), 2)

def preprocess_for_model(image_bytes: bytes) -> tuple:
    """
    Full pipeline:
    1. Load from bytes (user upload)
    2. Resize
    3. Enhance
    4. Blur
    5. Quality check
    6. Return numpy array ready for model
    """
    # load
    original = load_image_from_bytes(image_bytes)

    # resize
    resized = resize_image(original)

    # enhance lighting
    enhanced = clahe_equalization(resized)

    # noise removal
    processed = apply_gaussian_blur(enhanced)

    # quality check
    psnr_val = compute_psnr(resized, processed)

    # if enhancement degraded quality too much fallback to just resized
    if psnr_val < 20:
        processed = resized

    # convert to float32 and apply MobileNetV2 preprocessing
    img_array = processed.astype(np.float32)
    img_array = (img_array / 127.5) - 1.0  # MobileNetV2 preprocess_input equivalent

    # add batch dimension
    img_array = np.expand_dims(img_array, axis=0)

    return img_array, psnr_val