import requests
from app.config import settings

USDA_API_KEY = settings.USDA_API_KEY
USDA_SEARCH_URL = "https://api.nal.usda.gov/fdc/v1/foods/search"
SERVING_SIZES = {
    "small": 150,
    "medium": 250,
    "large": 400
}

def get_calories_from_usda(food_name: str, serving_size: str = "medium") -> dict:
    try:
        serving_grams = SERVING_SIZES.get(serving_size.lower(), 250)
        
        params = {
            "query": food_name,
            "pageSize": 1,
            "api_key": USDA_API_KEY
        }
        response = requests.get(USDA_SEARCH_URL, params=params, timeout=5)
        data = response.json()

        if not data.get("foods"):
            return None

        food = data["foods"][0]
        nutrients = food.get("foodNutrients", [])

        calories_per_100g = next(
            (n["value"] for n in nutrients if n.get("nutrientNumber") == "208"),
            None
        )

        if not calories_per_100g:
            return None

        serving_multiplier = serving_grams / 100
        estimated_calories = calories_per_100g * serving_multiplier

        return {
            "min": int(estimated_calories * 0.85),
            "max": int(estimated_calories * 1.15),
            "category": food.get("foodCategory", "General Food"),
            "source": "USDA FoodData Central",
            "per_serving_g": serving_grams,
            "is_unknown": False
        }

    except Exception as e:
        print(f"USDA API error: {e}")
        return None