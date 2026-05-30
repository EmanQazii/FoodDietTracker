from fastapi import APIRouter, File, UploadFile, Depends
from pydantic import BaseModel
from services.image_preprocessing import preprocess_for_model
from services.ml_model import predict_food, get_top3_predictions
from services.calorie_mapper import get_calorie_info, CALORIE_DISCLAIMER
from services.usda_service import get_calories_from_usda
from db.transactions import save_meal_with_prediction
from sqlalchemy.orm import Session
from app.database import get_db
from utils.dependencies import get_current_user
from models.user import User
from services.display_names import get_display_name

router = APIRouter()


# ── existing predict route ──────────────────────────────────────────────────

@router.post("/predict")
async def predict(
    file: UploadFile = File(...),
    meal_type: str = "lunch",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    image_bytes = await file.read()
    img_array, psnr_val = preprocess_for_model(image_bytes)
    food_label, confidence, raw_predictions = predict_food(img_array)
    calorie_info = get_calorie_info(food_label)

    # top 3 only returned when confidence is low or food is unknown
    top3 = None
    if confidence < 0.45 or food_label == "unknown":
        top3 = get_top3_predictions(raw_predictions)

    meal = save_meal_with_prediction(
        db=db,
        user_id=current_user.id,
        image_path=file.filename,
        food_label=food_label,
        confidence=confidence,
        calorie_min=calorie_info["min"],
        calorie_max=calorie_info["max"],
        calorie_category=calorie_info["category"],
        meal_type=meal_type
    )

    return {
        "food_label": food_label,
        "food_name": get_display_name(food_label),
        "confidence": round(confidence * 100, 2),
        "calorie_min": calorie_info["min"],
        "calorie_max": calorie_info["max"],
        "calorie_category": calorie_info["category"],
        "dietary_flag": calorie_info.get("dietary_flag"),
        "is_unknown": calorie_info.get("is_unknown", False),
        "message": calorie_info.get("message", ""),
        "source": calorie_info.get("source", ""),
        "disclaimer": CALORIE_DISCLAIMER,
        "top3_suggestions": top3,        # None when confidence is fine
        "psnr": psnr_val,
        "meal_id": meal.id
    }


# ── new manual entry route ──────────────────────────────────────────────────

class ManualEntryRequest(BaseModel):
    food_name: str
    meal_type: str = "lunch"

@router.post("/predict/manual")
async def predict_manual(
    request: ManualEntryRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    food_name = request.food_name.strip().lower()

    # try USDA first
    usda_result = get_calories_from_usda(food_name)

    if usda_result:
        calorie_min = usda_result["min"]
        calorie_max = usda_result["max"]
        calorie_category = usda_result["category"]
        dietary_flag = None          # USDA doesn't give us this
        source = "USDA FoodData Central"
        message = f"Nutrition data fetched from USDA for '{food_name}' (estimated per {usda_result['per_serving_g']}g serving)."
    else:
        # USDA returned nothing, still save with zeros and tell user
        calorie_min = 0
        calorie_max = 0
        calorie_category = "Unknown"
        dietary_flag = None
        source = "Not found"
        message = f"'{food_name}' was not found in USDA database. Meal saved without calorie data."

    meal = save_meal_with_prediction(
        db=db,
        user_id=current_user.id,
        image_path="manual_entry",
        food_label=food_name,
        confidence=1.0,              # user confirmed, so treat as certain
        calorie_min=calorie_min,
        calorie_max=calorie_max,
        calorie_category=calorie_category,
        meal_type=request.meal_type
    )

    return {
        "food_label": food_name,
        "food_name": food_name.replace("_", " ").title(),
        "confidence": 100.0,
        "calorie_min": calorie_min,
        "calorie_max": calorie_max,
        "calorie_category": calorie_category,
        "dietary_flag": dietary_flag,
        "is_unknown": calorie_min == 0,
        "source": source,
        "message": message,
        "disclaimer": CALORIE_DISCLAIMER,
        "top3_suggestions": None,
        "meal_id": meal.id
    }