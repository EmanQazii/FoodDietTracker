from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Meal(Base):
    __tablename__ = "meals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    image_path = Column(String, nullable=False)
    food_label = Column(String, nullable=False)
    confidence = Column(Float, nullable=False)
    calorie_min = Column(Integer, nullable=False)
    calorie_max = Column(Integer, nullable=False)
    calorie_category = Column(String, nullable=False)
    meal_type = Column(String, nullable=False)  # breakfast, lunch, dinner, snack
    created_at = Column(DateTime, server_default=func.now())

    user = relationship("User", back_populates="meals")