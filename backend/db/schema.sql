-- Users Table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    dietary_goal VARCHAR(50) DEFAULT 'balanced',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Meals Table
CREATE TABLE meals (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_path VARCHAR(255) NOT NULL,
    food_label VARCHAR(100) NOT NULL,
    confidence FLOAT NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
    calorie_min INTEGER NOT NULL CHECK (calorie_min > 0),
    calorie_max INTEGER NOT NULL CHECK (calorie_max > calorie_min),
    calorie_category VARCHAR(100) NOT NULL,
    meal_type VARCHAR(20) NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Predictions Table
CREATE TABLE predictions (
    id SERIAL PRIMARY KEY,
    meal_id INTEGER NOT NULL REFERENCES meals(id) ON DELETE CASCADE,
    predicted_label VARCHAR(100) NOT NULL,
    confidence_score FLOAT NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Nutrition Logs Table
CREATE TABLE nutrition_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    total_calorie_min INTEGER DEFAULT 0 CHECK (total_calorie_min >= 0),
    total_calorie_max INTEGER DEFAULT 0 CHECK (total_calorie_max >= 0),
    meal_count INTEGER DEFAULT 0 CHECK (meal_count >= 0),
    UNIQUE (user_id, log_date)
);

-- Daily Analytics Table
CREATE TABLE daily_analytics (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    analytics_date DATE NOT NULL,
    high_calorie_count INTEGER DEFAULT 0,
    low_calorie_count INTEGER DEFAULT 0,
    most_frequent_food VARCHAR(100),
    UNIQUE (user_id, analytics_date)
);