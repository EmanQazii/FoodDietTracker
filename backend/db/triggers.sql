-- Trigger function to auto update nutrition_logs after meal insert
CREATE OR REPLACE FUNCTION update_nutrition_log()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO nutrition_logs (user_id, log_date, total_calorie_min, total_calorie_max, meal_count)
    VALUES (NEW.user_id, DATE(NEW.created_at), NEW.calorie_min, NEW.calorie_max, 1)
    ON CONFLICT (user_id, log_date)
    DO UPDATE SET
        total_calorie_min = nutrition_logs.total_calorie_min + NEW.calorie_min,
        total_calorie_max = nutrition_logs.total_calorie_max + NEW.calorie_max,
        meal_count = nutrition_logs.meal_count + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to meals table
CREATE TRIGGER after_meal_insert
AFTER INSERT ON meals
FOR EACH ROW
EXECUTE FUNCTION update_nutrition_log();


-- Trigger function to update daily analytics
CREATE OR REPLACE FUNCTION update_daily_analytics()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO daily_analytics (user_id, analytics_date, high_calorie_count, low_calorie_count)
    VALUES (
        NEW.user_id,
        DATE(NEW.created_at),
        CASE WHEN NEW.calorie_max > 500 THEN 1 ELSE 0 END,
        CASE WHEN NEW.calorie_max <= 300 THEN 1 ELSE 0 END
    )
    ON CONFLICT (user_id, analytics_date)
    DO UPDATE SET
        high_calorie_count = daily_analytics.high_calorie_count + 
            CASE WHEN NEW.calorie_max > 500 THEN 1 ELSE 0 END,
        low_calorie_count = daily_analytics.low_calorie_count + 
            CASE WHEN NEW.calorie_max <= 300 THEN 1 ELSE 0 END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_meal_analytics
AFTER INSERT ON meals
FOR EACH ROW
EXECUTE FUNCTION update_daily_analytics();