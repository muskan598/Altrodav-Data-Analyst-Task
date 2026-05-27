

DROP TABLE IF EXISTS placements CASCADE;
DROP TABLE IF EXISTS daily_activity CASCADE;
DROP TABLE IF EXISTS student_progress CASCADE;
DROP TABLE IF EXISTS skill_modules CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS colleges CASCADE;



CREATE TABLE colleges (
    college_id SERIAL PRIMARY KEY,
    college_name VARCHAR(100)
);

CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    student_name VARCHAR(100),
    college_id INT REFERENCES colleges(college_id),
    join_date DATE
);

CREATE TABLE skill_modules (
    skill_id SERIAL PRIMARY KEY,
    skill_name VARCHAR(100)
);

CREATE TABLE student_progress (
    progress_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    skill_id INT REFERENCES skill_modules(skill_id),
    level_reached INT,
    completed BOOLEAN,
    failed BOOLEAN,
    completion_date DATE
);

CREATE TABLE daily_activity (
    activity_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    activity_date DATE
);

CREATE TABLE placements (
    placement_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    placed BOOLEAN
);



INSERT INTO colleges (college_name) VALUES
('QIS College'),
('Narayana Engineering College'),
('VIT Vellore'),
('SRM University'),
('Amrita University'),
('Anna University'),
('JNTU Hyderabad'),
('BITS Pilani');

INSERT INTO students (student_name, college_id, join_date) VALUES
('muskan',1,'2025-01-01'),
('Rahul',1,'2025-01-10'),
('Sneha',2,'2025-01-12'),
('Anjali',2,'2025-01-15'),
('Arjun',3,'2025-01-20'),
('Kiran',4,'2025-01-22'),
('Meera',5,'2025-01-25'),
('Ravi',6,'2025-01-28'),
('Divya',7,'2025-02-01'),
('Aman',8,'2025-02-05');

INSERT INTO skill_modules (skill_name) VALUES
('Aptitude'),
('SQL'),
('Python'),
('Machine Learning'),
('Data Structures');

INSERT INTO student_progress (
    student_id,
    skill_id,
    level_reached,
    completed,
    failed,
    completion_date
)
VALUES
(1,1,55,TRUE,FALSE,'2025-02-20'),
(2,1,35,FALSE,TRUE,'2025-02-22'),
(3,1,60,TRUE,FALSE,'2025-02-15'),
(4,2,70,TRUE,FALSE,'2025-03-01'),
(5,3,40,FALSE,TRUE,'2025-03-03'),
(6,4,80,TRUE,FALSE,'2025-03-05'),
(7,1,52,TRUE,FALSE,'2025-03-06'),
(8,2,45,FALSE,TRUE,'2025-03-07'),
(9,3,75,TRUE,FALSE,'2025-03-08'),
(10,5,65,TRUE,FALSE,'2025-03-09');

INSERT INTO daily_activity (student_id, activity_date) VALUES
(1,'2025-04-01'),
(1,'2025-04-02'),
(1,'2025-04-03'),
(1,'2025-04-04'),
(1,'2025-04-05'),
(1,'2025-04-06'),
(1,'2025-04-07'),
(2,'2025-04-01'),
(2,'2025-04-02'),
(2,'2025-04-03'),
(3,'2025-04-01'),
(3,'2025-04-02');

INSERT INTO placements (student_id, placed) VALUES
(1,TRUE),
(2,FALSE),
(3,TRUE),
(4,TRUE),
(5,FALSE),
(6,TRUE),
(7,TRUE),
(8,FALSE),
(9,TRUE),
(10,TRUE);



SELECT * FROM colleges;
SELECT * FROM students;
SELECT * FROM skill_modules;
SELECT * FROM student_progress;
SELECT * FROM daily_activity;
SELECT * FROM placements;



SELECT
    c.college_name,
    AVG(sp.completion_date - s.join_date) AS avg_days_to_level50
FROM student_progress sp
JOIN students s
    ON sp.student_id = s.student_id
JOIN colleges c
    ON s.college_id = c.college_id
JOIN skill_modules sm
    ON sp.skill_id = sm.skill_id
WHERE sm.skill_name = 'Aptitude'
  AND sp.level_reached >= 50
GROUP BY c.college_name;




SELECT
    sm.skill_name,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN sp.failed THEN 1 ELSE 0 END) AS failed_count,
    ROUND(
        SUM(CASE WHEN sp.failed THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS fail_rate
FROM student_progress sp
JOIN skill_modules sm
    ON sp.skill_id = sm.skill_id
GROUP BY sm.skill_name
HAVING
    SUM(CASE WHEN sp.failed THEN 1 ELSE 0 END)::FLOAT
    / COUNT(*) > 0.40;



WITH ranked_activity AS (
    SELECT
        student_id,
        activity_date,
        activity_date - (
            ROW_NUMBER() OVER (
                PARTITION BY student_id
                ORDER BY activity_date
            ) * INTERVAL '1 day'
        ) AS streak_group
    FROM daily_activity
),

streaks AS (
    SELECT
        student_id,
        COUNT(*) AS streak_length
    FROM ranked_activity
    GROUP BY student_id, streak_group
)

SELECT
    COUNT(DISTINCT student_id) AS students_with_7plus_streak
FROM streaks
WHERE streak_length >= 7;



SELECT
    sm.skill_name,
    COUNT(DISTINCT sp.student_id) AS total_students,
    COUNT(
        DISTINCT CASE
            WHEN sp.completed THEN sp.student_id
        END
    ) AS completed_students,
    ROUND(
        COUNT(
            DISTINCT CASE
                WHEN sp.completed THEN sp.student_id
            END
        ) * 100.0
        / COUNT(DISTINCT sp.student_id),
        2
    ) AS completion_rate
FROM student_progress sp
JOIN skill_modules sm
    ON sp.skill_id = sm.skill_id
GROUP BY sm.skill_name;


SELECT
    c.college_name,
    COUNT(DISTINCT s.student_id) AS total_students,
    COUNT(
        DISTINCT CASE
            WHEN p.placed THEN s.student_id
        END
    ) AS placed_students,
    ROUND(
        COUNT(
            DISTINCT CASE
                WHEN p.placed THEN s.student_id
            END
        ) * 100.0
        / COUNT(DISTINCT s.student_id),
        2
    ) AS placement_rate
FROM placements p
JOIN students s
    ON p.student_id = s.student_id
JOIN colleges c
    ON s.college_id = c.college_id
GROUP BY c.college_name
ORDER BY placement_rate DESC
LIMIT 10;
