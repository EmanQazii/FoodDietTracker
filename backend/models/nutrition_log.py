from sqlalchemy import Column, Integer, Date, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class NutritionLog(Base):
    __tablename__ = "nutrition_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    date = Column(Date, nullable=False)
    total_calorie_min = Column(Integer, default=0)
    total_calorie_max = Column(Integer, default=0)
    meal_count = Column(Integer, default=0)

    user = relationship("User", back_populates="nutrition_logs")