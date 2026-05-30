DISPLAY_NAMES = {
    "biryani": "Biryani",
    "brownie": "Brownie",
    "butter_chicken": "Butter Chicken",
    "chai": "Chai",
    "chicken_curry": "Chicken Curry",
    "chicken_tikka": "Chicken Tikka",
    "chicken_wings": "Chicken Wings",
    "chocolate_cake": "Chocolate Cake",
    "club_sandwich": "Club Sandwich",
    "cup_cakes": "Cupcakes",
    "french_fries": "French Fries",
    "french_toast": "French Toast",
    "fried_rice": "Fried Rice",
    "garlic_bread": "Garlic Bread",
    "greek_salad": "Greek Salad",
    "grilled_cheese_sandwich": "Grilled Cheese Sandwich",
    "haleem": "Haleem",
    "hamburger": "Hamburger",
    "hot_and_sour_soup": "Hot and Sour Soup",
    "ice_cream": "Ice Cream",
    "lasagna": "Lasagna",
    "macaroni_and_cheese": "Macaroni and Cheese",
    "omelette": "Omelette",
    "onion_rings": "Onion Rings",
    "pancakes": "Pancakes",
    "paratha": "Paratha",
    "paratha_roll": "Paratha Roll",
    "pizza": "Pizza",
    "red_velvet_cake": "Red Velvet Cake",
    "samosa": "Samosa",
    "spaghetti_carbonara": "Spaghetti Carbonara",
    "spring_rolls": "Spring Rolls",
    "steak": "Steak",
    "waffles": "Waffles",
    "unknown": "Unrecognized Food"
}

def get_display_name(food_label: str) -> str:
    return DISPLAY_NAMES.get(
        food_label,
        food_label.replace("_", " ").title()
    )