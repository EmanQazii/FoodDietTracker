from fastapi import APIRouter, File, UploadFile, Depends
from services.image_preprocessing import preprocess_for_model
from services.ml_model import predict_food
from services.calorie_mapper import get_calorie_info
from db.transactions import save_meal_with_prediction
from sqlalchemy.orm import Session
from app.database import get_db

router = APIRouter()

@router.post("/predict")
async def predict(
    file: UploadFile = File(...),
    meal_type: str = "lunch",
    db: Session = Depends(get_db)
):
    # Step 1 — read uploaded image bytes
    image_bytes = await file.read()

    # Step 2 — DIP pipeline preprocesses image
    img_array, psnr_val = preprocess_for_model(image_bytes)

    # Step 3 — ML model predicts food
    food_label, confidence = predict_food(img_array)

    # Step 4 — get calorie info
    calorie_info = get_calorie_info(food_label)

    # Step 5 — save to database with transaction
    meal = save_meal_with_prediction(
        db=db,
        user_id=2,  # will come from JWT token later
        image_path=file.filename,
        food_label=food_label,
        confidence=confidence,
        calorie_min=calorie_info['min'],
        calorie_max=calorie_info['max'],
        calorie_category=calorie_info['category'],
        meal_type=meal_type
    )

    return {
        "food_label": food_label,
        "confidence": round(confidence * 100, 2),
        "calorie_min": calorie_info['min'],
        "calorie_max": calorie_info['max'],
        "calorie_category": calorie_info['category'],
        "psnr": psnr_val,
        "meal_id": meal.id
    }