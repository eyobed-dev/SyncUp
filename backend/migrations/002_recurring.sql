-- Recurring availability: professor's standing weekly schedule
-- Each row = one recurring time slot that repeats every week
CREATE TABLE IF NOT EXISTS recurring_availability (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    professor_id INTEGER NOT NULL REFERENCES professors(id),
    day_of_week INTEGER NOT NULL CHECK(day_of_week BETWEEN 0 AND 4),
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    UNIQUE(professor_id, day_of_week, start_time)
);
