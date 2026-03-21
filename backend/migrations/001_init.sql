-- Create professors table
CREATE TABLE IF NOT EXISTS professors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    department TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'Professor',
    phone TEXT,
    email TEXT NOT NULL UNIQUE,
    office TEXT,
    personal_id TEXT,
    password_hash TEXT NOT NULL
);

-- Create students table
CREATE TABLE IF NOT EXISTS students (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    surname TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL
);

-- Create slots table
-- day_of_week: 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri
-- week_offset: 0 = current week, -1 = last week, 1 = next week, etc.
-- week_anchor: the ISO date of the Monday of that week
CREATE TABLE IF NOT EXISTS slots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    professor_id INTEGER NOT NULL REFERENCES professors(id),
    day_of_week INTEGER NOT NULL CHECK(day_of_week BETWEEN 0 AND 4),
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    total_slots INTEGER NOT NULL DEFAULT 1,
    available_slots INTEGER NOT NULL DEFAULT 1,
    week_anchor TEXT NOT NULL
);

-- Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    slot_id INTEGER NOT NULL REFERENCES slots(id),
    student_id INTEGER NOT NULL REFERENCES students(id),
    topic TEXT NOT NULL,
    booked_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================
-- SEED DATA
-- ============================

-- Professor: Adam Herout (password: herout123)
INSERT INTO professors (id, name, department, role, phone, email, office, personal_id, password_hash)
VALUES (1, 'Adam Herout', 'Computer Science', 'Deputy Head', '+420 541 141 270', 'herout@fit.vut.cz', 'L324', '12345', '$2b$12$RTcNNA5RHAeWo0XANb1j/.y/EWK4yxLPb9gT16xAHfh8hpaI/i4RK');

-- Students (password: student123)
INSERT INTO students (id, name, surname, email, password_hash)
VALUES
    (1, 'Jan', 'Novak', 'jan.novak@stud.fit.vut.cz', '$2b$12$cCIo5TMsm11jmy77RQ2JOOsjVHl01HMhObwZ3c5zklPoTvWJyyQni'),
    (2, 'Marie', 'Svoboda', 'marie.svoboda@stud.fit.vut.cz', '$2b$12$cCIo5TMsm11jmy77RQ2JOOsjVHl01HMhObwZ3c5zklPoTvWJyyQni'),
    (3, 'Petr', 'Dvorak', 'petr.dvorak@stud.fit.vut.cz', '$2b$12$cCIo5TMsm11jmy77RQ2JOOsjVHl01HMhObwZ3c5zklPoTvWJyyQni');

-- Slots for current and next week (Mar 9 and Mar 16, 2026)
INSERT INTO slots (professor_id, day_of_week, start_time, end_time, total_slots, available_slots, week_anchor)
VALUES
    -- Week of Mar 9
    (1, 0, '09:00', '10:00', 1, 1, '2026-03-09'),
    (1, 0, '11:00', '12:00', 1, 1, '2026-03-09'),
    (1, 1, '10:00', '11:00', 1, 1, '2026-03-09'),
    (1, 1, '14:00', '15:00', 1, 1, '2026-03-09'),
    (1, 2, '09:00', '10:00', 1, 1, '2026-03-09'),
    (1, 3, '13:00', '14:00', 1, 1, '2026-03-09'),
    (1, 4, '10:00', '11:00', 1, 1, '2026-03-09'),
    -- Week of Mar 16
    (1, 0, '09:00', '10:00', 1, 1, '2026-03-16'),
    (1, 1, '10:00', '11:00', 1, 1, '2026-03-16'),
    (1, 2, '11:00', '12:00', 1, 1, '2026-03-16'),
    (1, 3, '14:00', '15:00', 1, 1, '2026-03-16'),
    (1, 4, '15:00', '16:00', 1, 1, '2026-03-16');

INSERT INTO bookings (slot_id, student_id, topic, booked_at)
VALUES
    (1, 1, 'UXI Initial Meeting', '2026-03-01 10:00:00'),
    (2, 2, 'Thesis Discussion', '2026-03-01 11:00:00');
