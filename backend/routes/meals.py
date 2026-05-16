from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from models.meal import Meal
from models.user import User
from utils.dependencies import get_current_user

router = APIRouter()

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

    return meal