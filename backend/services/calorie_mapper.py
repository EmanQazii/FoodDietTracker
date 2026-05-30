CALORIE_MAP = {
    "biryani":                {"min": 500, "max": 800, "category": "High Calorie Rice Meal",        "dietary_flag": "high_calorie"},
    "brownie":                {"min": 300, "max": 450, "category": "High Calorie Dessert",           "dietary_flag": "high_calorie"},
    "butter_chicken":         {"min": 400, "max": 600, "category": "High Calorie Curry",             "dietary_flag": "high_calorie"},
    "chai":                   {"min": 50,  "max": 150, "category": "Low Calorie Beverage",           "dietary_flag": "low_calorie"},
    "chicken_curry":          {"min": 350, "max": 550, "category": "Protein Curry",                  "dietary_flag": "balanced"},
    "chicken_tikka":          {"min": 250, "max": 400, "category": "Grilled Protein",                "dietary_flag": "balanced"},
    "chicken_wings":          {"min": 400, "max": 600, "category": "High Calorie Snack",             "dietary_flag": "high_calorie"},
    "chocolate_cake":         {"min": 350, "max": 500, "category": "High Calorie Dessert",           "dietary_flag": "high_calorie"},
    "club_sandwich":          {"min": 400, "max": 600, "category": "Moderate Calorie Meal",          "dietary_flag": "balanced"},
    "cup_cakes":              {"min": 250, "max": 400, "category": "High Calorie Dessert",           "dietary_flag": "high_calorie"},
    "french_fries":           {"min": 300, "max": 500, "category": "High Calorie Snack",             "dietary_flag": "high_calorie"},
    "french_toast":           {"min": 250, "max": 400, "category": "Moderate Calorie Breakfast",     "dietary_flag": "balanced"},
    "fried_rice":             {"min": 400, "max": 650, "category": "High Calorie Rice Meal",         "dietary_flag": "high_calorie"},
    "garlic_bread":           {"min": 200, "max": 350, "category": "Moderate Calorie Side",          "dietary_flag": "balanced"},
    "greek_salad":            {"min": 100, "max": 250, "category": "Low Calorie Meal",               "dietary_flag": "low_calorie"},
    "grilled_cheese_sandwich":{"min": 350, "max": 500, "category": "Moderate Calorie Meal",          "dietary_flag": "balanced"},
    "haleem":                 {"min": 350, "max": 550, "category": "High Protein Meal",              "dietary_flag": "balanced"},
    "hamburger":              {"min": 400, "max": 700, "category": "High Calorie Fast Food",         "dietary_flag": "high_calorie"},
    "hot_and_sour_soup":      {"min": 100, "max": 200, "category": "Low Calorie Soup",               "dietary_flag": "low_calorie"},
    "ice_cream":              {"min": 200, "max": 400, "category": "High Calorie Dessert",           "dietary_flag": "high_calorie"},
    "lasagna":                {"min": 400, "max": 650, "category": "High Calorie Meal",              "dietary_flag": "high_calorie"},
    "macaroni_and_cheese":    {"min": 350, "max": 550, "category": "High Calorie Meal",              "dietary_flag": "high_calorie"},
    "omelette":               {"min": 150, "max": 300, "category": "Protein Breakfast",              "dietary_flag": "balanced"},
    "onion_rings":            {"min": 250, "max": 400, "category": "High Calorie Snack",             "dietary_flag": "high_calorie"},
    "pancakes":               {"min": 300, "max": 500, "category": "Moderate Calorie Breakfast",     "dietary_flag": "balanced"},
    "paratha":                {"min": 200, "max": 350, "category": "Moderate Calorie Bread",         "dietary_flag": "balanced"},
    "paratha_roll":           {"min": 350, "max": 550, "category": "Moderate Calorie Meal",          "dietary_flag": "balanced"},
    "pizza":                  {"min": 400, "max": 700, "category": "High Calorie Fast Food",         "dietary_flag": "high_calorie"},
    "red_velvet_cake":        {"min": 350, "max": 500, "category": "High Calorie Dessert",           "dietary_flag": "high_calorie"},
    "samosa":                 {"min": 150, "max": 300, "category": "Moderate Calorie Snack",         "dietary_flag": "balanced"},
    "spaghetti_carbonara":    {"min": 400, "max": 650, "category": "High Calorie Pasta",             "dietary_flag": "high_calorie"},
    "spring_rolls":           {"min": 150, "max": 300, "category": "Moderate Calorie Snack",         "dietary_flag": "balanced"},
    "steak":                  {"min": 400, "max": 700, "category": "High Protein Meal",              "dietary_flag": "high_calorie"},
    "waffles":                {"min": 300, "max": 500, "category": "Moderate Calorie Breakfast",     "dietary_flag": "balanced"}
}

CALORIE_DISCLAIMER = (
    "Calorie ranges are approximate estimates based on standard serving sizes, "
    "cross-referenced with USDA FoodData Central. Actual values may vary depending "
    "on preparation method, ingredients, and portion size."
)

def get_calorie_info(food_label: str) -> dict:
    if food_label == "unknown":
        return {
            "min": 0,
            "max": 0,
            "category": "Unrecognized Food",
            "dietary_flag": None,
            "is_unknown": True,
            "message": "Food not recognized. Please try a clearer image or enter the food name manually.",
            "disclaimer": CALORIE_DISCLAIMER
        }

    result = CALORIE_MAP.get(food_label)
    if result:
        return {
            **result,
            "source": "USDA FoodData Central (manually verified)",
            "is_unknown": False,
            "message": "",
            "disclaimer": CALORIE_DISCLAIMER
        }

    return {
        "min": 0,
        "max": 0,
        "category": "Unknown",
        "dietary_flag": None,
        "is_unknown": True,
        "message": "Food not in database.",
        "disclaimer": CALORIE_DISCLAIMER
    }