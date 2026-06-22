from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from app.database import get_db
from models.meal import Meal
from models.user import User
from utils.dependencies import get_current_user

router = APIRouter()


class SaveMealRequest(BaseModel):
    food_label: str
    confidence: Optional[str] = None
    calorie_min: Optional[int] = 0
    calorie_max: Optional[int] = 0
    calorie_category: Optional[str] = None
    meal_type: str = "lunch"
    image_path: Optional[str] = None


class UpdateMealRequest(BaseModel):
    food_label: Optional[str] = None
    confidence: Optional[str] = None
    calorie_min: Optional[int] = None
    calorie_max: Optional[int] = None
    calorie_category: Optional[str] = None
    meal_type: Optional[str] = None
    image_path: Optional[str] = None


@router.post("/meals", status_code=201)
def save_meal(
    request: SaveMealRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # parse confidence — Flutter sends it as "87%" or "87.5"
    confidence_val = 0.0
    if request.confidence:
        cleaned = request.confidence.replace('%', '').strip()
        try:
            confidence_val = float(cleaned)
        except ValueError:
            confidence_val = 0.0

    meal = Meal(
        user_id=current_user.id,
        food_label=request.food_label,
        confidence=confidence_val,
        calorie_min=request.calorie_min or 0,
        calorie_max=request.calorie_max or 0,
        calorie_category=request.calorie_category or "",
        meal_type=request.meal_type.lower(),
        image_path=request.image_path or ""
    )
    db.add(meal)
    db.commit()
    db.refresh(meal)

    return {"success": True, "meal_id": meal.id}


@router.get("/meals")
def get_meals(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    meals = db.query(Meal).filter(
        Meal.user_id == current_user.id
    ).order_by(Meal.created_at.desc()).all()

    return [
        {
            "id": m.id,
            "food_label": m.food_label,
            "confidence": m.confidence,
            "calorie_min": m.calorie_min,
            "calorie_max": m.calorie_max,
            "calorie_category": m.calorie_category,
            "meal_type": m.meal_type,
            "created_at": m.created_at
        }
        for m in meals
    ]


@router.get("/meals/{meal_id}")
def get_meal(
    meal_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    meal = db.query(Meal).filter(
        Meal.id == meal_id,
        Meal.user_id == current_user.id
    ).first()

    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    return {
        "id": meal.id,
        "food_label": meal.food_label,
        "confidence": meal.confidence,
        "calorie_min": meal.calorie_min,
        "calorie_max": meal.calorie_max,
        "calorie_category": meal.calorie_category,
        "meal_type": meal.meal_type,
        "image_path": meal.image_path,
        "created_at": meal.created_at
    }


@router.put("/meals/{meal_id}")
def update_meal(
    meal_id: int,
    request: UpdateMealRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    meal = db.query(Meal).filter(
        Meal.id == meal_id,
        Meal.user_id == current_user.id
    ).first()

    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    if request.food_label is not None:
        meal.food_label = request.food_label

    if request.confidence is not None:
        cleaned = request.confidence.replace('%', '').strip()
        try:
            meal.confidence = float(cleaned)
        except ValueError:
            meal.confidence = 0.0

    if request.calorie_min is not None:
        meal.calorie_min = request.calorie_min
    if request.calorie_max is not None:
        meal.calorie_max = request.calorie_max
    if request.calorie_category is not None:
        meal.calorie_category = request.calorie_category
    if request.meal_type is not None:
        meal.meal_type = request.meal_type.lower()
    if request.image_path is not None:
        meal.image_path = request.image_path

    db.commit()
    db.refresh(meal)

    return {"success": True, "meal_id": meal.id}
