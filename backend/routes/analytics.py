from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db
from models.user import User
from utils.dependencies import get_current_user

router = APIRouter()

@router.get("/analytics/weekly")
def weekly_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(
        text("SELECT * FROM get_weekly_summary(:user_id)"),
        {"user_id": current_user.id}
    ).fetchall()

    return [
        {
            "log_date": str(row[0]),
            "total_calorie_min": row[1],
            "total_calorie_max": row[2],
            "meal_count": row[3]
        }
        for row in result
    ]

@router.get("/analytics/unhealthy")
def unhealthy_report(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(
        text("SELECT * FROM get_unhealthy_report(:user_id)"),
        {"user_id": current_user.id}
    ).fetchall()

    return [
        {
            "food_label": row[0],
            "calorie_category": row[1],
            "calorie_max": row[2],
            "meal_date": str(row[3])
        }
        for row in result
    ]

@router.get("/analytics/summary")
def overall_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from models.meal import Meal
    from sqlalchemy import func

    total_meals = db.query(func.count(Meal.id)).filter(
        Meal.user_id == current_user.id
    ).scalar()

    avg_calories = db.query(func.avg(Meal.calorie_max)).filter(
        Meal.user_id == current_user.id
    ).scalar()

    high_calorie = db.query(func.count(Meal.id)).filter(
        Meal.user_id == current_user.id,
        Meal.calorie_max > 500
    ).scalar()

    return {
        "total_meals": total_meals,
        "average_calories": round(avg_calories or 0, 2),
        "high_calorie_meals": high_calorie
    }