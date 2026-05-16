CALORIE_MAP = {
    "biryani":                {"min": 500, "max": 800, "category": "High Calorie Rice Meal"},
    "brownie":                {"min": 300, "max": 450, "category": "High Calorie Dessert"},
    "butter_chicken":         {"min": 400, "max": 600, "category": "High Calorie Curry"},
    "chai":                   {"min": 50,  "max": 150, "category": "Low Calorie Beverage"},
    "chicken_curry":          {"min": 350, "max": 550, "category": "Protein Curry"},
    "chicken_tikka":          {"min": 250, "max": 400, "category": "Grilled Protein"},
    "chicken_wings":          {"min": 400, "max": 600, "category": "High Calorie Snack"},
    "chocolate_cake":         {"min": 350, "max": 500, "category": "High Calorie Dessert"},
    "club_sandwich":          {"min": 400, "max": 600, "category": "Moderate Calorie Meal"},
    "cup_cakes":              {"min": 250, "max": 400, "category": "High Calorie Dessert"},
    "french_fries":           {"min": 300, "max": 500, "category": "High Calorie Snack"},
    "french_toast":           {"min": 250, "max": 400, "category": "Moderate Calorie Breakfast"},
    "fried_rice":             {"min": 400, "max": 650, "category": "High Calorie Rice Meal"},
    "garlic_bread":           {"min": 200, "max": 350, "category": "Moderate Calorie Side"},
    "greek_salad":            {"min": 100, "max": 250, "category": "Low Calorie Meal"},
    "grilled_cheese_sandwich":{"min": 350, "max": 500, "category": "Moderate Calorie Meal"},
    "haleem":                 {"min": 350, "max": 550, "category": "High Protein Meal"},
    "hamburger":              {"min": 400, "max": 700, "category": "High Calorie Fast Food"},
    "hot_and_sour_soup":      {"min": 100, "max": 200, "category": "Low Calorie Soup"},
    "ice_cream":              {"min": 200, "max": 400, "category": "High Calorie Dessert"},
    "lasagna":                {"min": 400, "max": 650, "category": "High Calorie Meal"},
    "macaroni_and_cheese":    {"min": 350, "max": 550, "category": "High Calorie Meal"},
    "omelette":               {"min": 150, "max": 300, "category": "Protein Breakfast"},
    "onion_rings":            {"min": 250, "max": 400, "category": "High Calorie Snack"},
    "pancakes":               {"min": 300, "max": 500, "category": "Moderate Calorie Breakfast"},
    "paratha":                {"min": 200, "max": 350, "category": "Moderate Calorie Bread"},
    "paratha_roll":           {"min": 350, "max": 550, "category": "Moderate Calorie Meal"},
    "pizza":                  {"min": 400, "max": 700, "category": "High Calorie Fast Food"},
    "red_velvet_cake":        {"min": 350, "max": 500, "category": "High Calorie Dessert"},
    "samosa":                 {"min": 150, "max": 300, "category": "Moderate Calorie Snack"},
    "spaghetti_carbonara":    {"min": 400, "max": 650, "category": "High Calorie Pasta"},
    "spring_rolls":           {"min": 150, "max": 300, "category": "Moderate Calorie Snack"},
    "steak":                  {"min": 400, "max": 700, "category": "High Protein Meal"},
    "waffles":                {"min": 300, "max": 500, "category": "Moderate Calorie Breakfast"}
}

def get_calorie_info(food_label: str) -> dict:
    return CALORIE_MAP.get(food_label, {
        "min": 0,
        "max": 0,
        "category": "Unknown"
    })