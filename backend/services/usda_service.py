import requests
from app.config import settings

USDA_API_KEY = settings.USDA_API_KEY
DEFAULT_SERVING_GRAMS = 250  # assumed single serving size

def get_calories_from_usda(food_name: str) -> dict:
    try:
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

        # nutrient number 208 is energy in kcal in USDA
        calories_per_100g = next(
            (n["value"] for n in nutrients if n.get("nutrientNumber") == "208"),
            None
        )

        if not calories_per_100g:
            return None

        # scale to default serving size
        serving_multiplier = DEFAULT_SERVING_GRAMS / 100
        estimated_calories = calories_per_100g * serving_multiplier

        return {
            "min": int(estimated_calories * 0.85),
            "max": int(estimated_calories * 1.15),
            "category": food.get("foodCategory", "General Food"),
            "source": "USDA FoodData Central",
            "per_serving_g": DEFAULT_SERVING_GRAMS,
            "is_unknown": False
        }

    except Exception as e:
        print(f"USDA API error: {e}")
        return None