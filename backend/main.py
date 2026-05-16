from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import Base, engine
from routes import auth, meals, predictions, analytics

# create all tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Food Tracker API",
    description="AI Based Food Recognition and Dietary Tracking System",
    version="1.0.0"
)

# CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# register routes
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(predictions.router, prefix="/api", tags=["Predictions"])
app.include_router(meals.router, prefix="/api", tags=["Meals"])
app.include_router(analytics.router, prefix="/api", tags=["Analytics"])

@app.get("/")
def root():
    return {"message": "Food Tracker API is running", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "healthy"}