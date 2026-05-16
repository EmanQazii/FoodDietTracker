-- High calorie meals view
CREATE OR REPLACE VIEW high_calorie_meals AS
SELECT
    u.username,
    m.food_label,
    m.calorie_category,
    m.calorie_max,
    m.meal_type,
    m.created_at
FROM meals m
JOIN users u ON m.user_id = u.id
WHERE m.calorie_max > 500
ORDER BY m.created_at DESC;


-- Recent uploads view
CREATE OR REPLACE VIEW recent_uploads AS
SELECT
    u.username,
    m.food_label,
    m.confidence,
    m.calorie_min,
    m.calorie_max,
    m.meal_type,
    m.created_at
FROM meals m
JOIN users u ON m.user_id = u.id
ORDER BY m.created_at DESC
LIMIT 50;


-- Unhealthy eating patterns view
CREATE OR REPLACE VIEW unhealthy_patterns AS
SELECT
    u.username,
    COUNT(m.id) AS high_calorie_meal_count,
    AVG(m.calorie_max) AS avg_calories,
    MAX(m.created_at) AS last_unhealthy_meal
FROM meals m
JOIN users u ON m.user_id = u.id
WHERE m.calorie_max > 500
GROUP BY u.username
ORDER BY high_calorie_meal_count DESC;