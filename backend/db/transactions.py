from sqlalchemy.orm import Session
from models.meal import Meal
from models.prediction import Prediction
from app.database import SessionLocal

def save_meal_with_prediction(
    db: Session,
    user_id: int,
    image_path: str,
    food_label: str,
    confidence: float,
    calorie_min: int,
    calorie_max: int,
    calorie_category: str,
    meal_type: str
):
    try:
        # Start transaction
        meal = Meal(
            user_id=user_id,
            image_path=image_path,
            food_label=food_label,
            confidence=confidence,
            calorie_min=calorie_min,
            calorie_max=calorie_max,
            calorie_category=calorie_category,
            meal_type=meal_type
        )
        db.add(meal)
        db.flush()  # get meal.id without committing

        # Save prediction record
        prediction = Prediction(
            meal_id=meal.id,
            predicted_label=food_label,
            confidence_score=confidence
        )
        db.add(prediction)

        # Commit everything together
        db.commit()
        db.refresh(meal)
        return meal

    except Exception as e:
        db.rollback()  # rollback if anything fails
        raise e