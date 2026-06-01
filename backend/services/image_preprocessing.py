import cv2
import numpy as np

def load_image_from_bytes(image_bytes: bytes) -> np.ndarray:
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    return cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

def resize_image(img: np.ndarray, size=(224, 224)) -> np.ndarray:
    return cv2.resize(img, size)

def clahe_equalization(img: np.ndarray) -> np.ndarray:
    lab = cv2.cvtColor(img, cv2.COLOR_RGB2LAB)
    clahe = cv2.createCLAHE(
        clipLimit=2.0,
        tileGridSize=(8, 8)
    )
    lab[:, :, 0] = clahe.apply(lab[:, :, 0])
    return cv2.cvtColor(lab, cv2.COLOR_LAB2RGB)

def denoise_image(img: np.ndarray) -> np.ndarray:
    return cv2.fastNlMeansDenoisingColored(
        img,
        None,
        10,
        10,
        7,
        21
    )

def unsharp_mask(img: np.ndarray) -> np.ndarray:
    blur = cv2.GaussianBlur(img, (0, 0), 3)
    sharpened = cv2.addWeighted(
        img,
        1.5,
        blur,
        -0.5,
        0
    )
    return sharpened

def compute_psnr(original: np.ndarray,
                 processed: np.ndarray) -> float:

    orig = original.astype(np.float64)
    proc = processed.astype(np.float64)

    mse = np.mean((orig - proc) ** 2)

    if mse == 0:
        return 100.0

    return round(
        20 * np.log10(255.0 / np.sqrt(mse)),
        2
    )

def preprocess_for_model(image_bytes: bytes) -> tuple:
    """
    Production Pipeline

    1. Load uploaded image
    2. Resize to 224x224
    3. CLAHE enhancement
    4. Non-Local Means denoising
    5. Unsharp masking
    6. PSNR quality validation
    7. MobileNetV2 preprocessing
    """

    # Load
    original = load_image_from_bytes(image_bytes)

    # Resize
    resized = resize_image(original)

    # Contrast enhancement
    enhanced = clahe_equalization(resized)

    # Edge-preserving denoising
    denoised = denoise_image(enhanced)

    # Sharpen important food details
    processed = unsharp_mask(denoised)

    # Quality validation
    psnr_val = compute_psnr(resized, processed)

    # Fallback if preprocessing becomes too aggressive
    if psnr_val < 18:
        processed = resized

    # MobileNetV2 preprocessing
    img_array = processed.astype(np.float32)
    img_array = (img_array / 127.5) - 1.0

    # Batch dimension
    img_array = np.expand_dims(img_array, axis=0)

    return img_array, psnr_val