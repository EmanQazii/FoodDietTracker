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

@router.get("/analytics/meal-types")
def meal_type_breakdown(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from models.meal import Meal
    from sqlalchemy import func
    results = db.query(
        Meal.meal_type,
        func.count(Meal.id).label('count')
    ).filter(
        Meal.user_id == current_user.id
    ).group_by(Meal.meal_type).all()

    return {row[0]: row[1] for row in results}

@router.get("/analytics/all")
def analytics_overview(
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

    summary = {
        "total_meals": total_meals,
        "average_calories": round(avg_calories or 0, 2),
        "high_calorie_meals": high_calorie,
    }

    weekly_result = db.execute(
        text("SELECT * FROM get_weekly_summary(:user_id)"),
        {"user_id": current_user.id}
    ).fetchall()
    weekly = [
        {
            "log_date": str(row[0]),
            "total_calorie_min": row[1],
            "total_calorie_max": row[2],
            "meal_count": row[3],
        }
        for row in weekly_result
    ]

    unhealthy_result = db.execute(
        text("SELECT * FROM get_unhealthy_report(:user_id)"),
        {"user_id": current_user.id}
    ).fetchall()
    unhealthy = [
        {
            "food_label": row[0],
            "calorie_category": row[1],
            "calorie_max": row[2],
            "meal_date": str(row[3]),
        }
        for row in unhealthy_result
    ]

    meal_type_results = db.query(
        Meal.meal_type,
        func.count(Meal.id).label('count')
    ).filter(
        Meal.user_id == current_user.id
    ).group_by(Meal.meal_type).all()
    meal_types = {row[0]: row[1] for row in meal_type_results}

    return {
        "summary": summary,
        "weekly": weekly,
        "unhealthy": unhealthy,
        "meal_types": meal_types,
    }