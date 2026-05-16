from sqlalchemy import Column, Integer, String, Float, ForeignKey, TIMESTAMP
from sqlalchemy.sql import func
from app.database import Base

class Prediction(Base):
    __tablename__ = "predictions"

    id = Column(Integer, primary_key=True, index=True)

    meal_id = Column(
        Integer,
        ForeignKey("meals.id", ondelete="CASCADE"),
        nullable=False
    )

    predicted_label = Column(String(100), nullable=False)

    confidence_score = Column(Float, nullable=False)

    model_version = Column(String(50), default="v1.0")

    created_at = Column(TIMESTAMP, server_default=func.now())