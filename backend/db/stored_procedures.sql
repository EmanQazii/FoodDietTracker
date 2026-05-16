-- Weekly nutrition summary for a user
CREATE OR REPLACE FUNCTION get_weekly_summary(p_user_id INTEGER)
RETURNS TABLE (
    log_date DATE,
    total_calorie_min INTEGER,
    total_calorie_max INTEGER,
    meal_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        nl.log_date,
        nl.total_calorie_min,
        nl.total_calorie_max,
        nl.meal_count
    FROM nutrition_logs nl
    WHERE nl.user_id = p_user_id
    AND nl.log_date >= CURRENT_DATE - INTERVAL '7 days'
    ORDER BY nl.log_date DESC;
END;
$$ LANGUAGE plpgsql;


-- Get unhealthy meal report for a user
CREATE OR REPLACE FUNCTION get_unhealthy_report(p_user_id INTEGER)
RETURNS TABLE (
    food_label VARCHAR,
    calorie_category VARCHAR,
    calorie_max INTEGER,
    meal_date TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.food_label,
        m.calorie_category,
        m.calorie_max,
        m.created_at
    FROM meals m
    WHERE m.user_id = p_user_id
    AND m.calorie_max > 500
    ORDER BY m.created_at DESC;
END;
$$ LANGUAGE plpgsql;