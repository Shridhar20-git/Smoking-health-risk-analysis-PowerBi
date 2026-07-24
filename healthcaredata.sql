
CREATE TABLE patients (
    Patient_ID           INT PRIMARY KEY,
    Age                  INT,
    Gender               VARCHAR(10),
    Smoking_Status       VARCHAR(20),
    Years_of_Smoking     INT,
    Cigarettes_Per_Day   INT,
    Organ                VARCHAR(30),
    Organ_Condition      VARCHAR(20),
    BMI                  DECIMAL(5,2),
    BP_Risk              VARCHAR(20),
    Cholesterol_Level     DECIMAL(6,2),
    Family_History_Risk  VARCHAR(10),
    Alcohol_Consumption  VARCHAR(20)
);
CREATE TABLE organ_icons (
    Organ     VARCHAR(30) PRIMARY KEY,
    Icon_URL  TEXT
);
CREATE TABLE organ_images (
    Organ            VARCHAR(30),
    Organ_Condition  VARCHAR(20),
    Image_URL        TEXT,
    PRIMARY KEY (Organ, Organ_Condition)
);CREATE TABLE condition_lookup (
    Organ_Condition VARCHAR(20) PRIMARY KEY
);
INSERT INTO condition_lookup (Organ_Condition) VALUES
('Healthy'),
('Damaged');

SELECT COUNT(*) FROM patients;
SELECT * FROM condition_lookup;
SELECT Organ,
       COUNT(*) AS total_patients,
       SUM(CASE WHEN Organ_Condition = 'Damaged' THEN 1 ELSE 0 END) AS damaged_count,
       ROUND(100.0 * SUM(CASE WHEN Organ_Condition = 'Damaged' THEN 1 ELSE 0 END) / COUNT(*), 2) AS damage_rate_pct
FROM patients
GROUP BY Organ
ORDER BY damage_rate_pct DESC;
SELECT Smoking_Status,
       COUNT(*) AS total,
       SUM(CASE WHEN Organ_Condition = 'Damaged' THEN 1 ELSE 0 END) AS damaged,
       ROUND(100.0 * SUM(CASE WHEN Organ_Condition = 'Damaged' THEN 1 ELSE 0 END) / COUNT(*), 2) AS damage_rate_pct
FROM patients
GROUP BY Smoking_Status
ORDER BY damage_rate_pct DESC;
SELECT
    CASE
        WHEN BMI < 18.5 THEN 'Underweight'
        WHEN BMI < 25   THEN 'Normal'
        WHEN BMI < 30   THEN 'Overweight'
        ELSE 'Obese'
    END AS bmi_category,
    COUNT(*) AS total,
    SUM(CASE WHEN Organ_Condition = 'Damaged' THEN 1 ELSE 0 END) AS damaged,
    ROUND(100.0 * SUM(CASE WHEN Organ_Condition = 'Damaged' THEN 1 ELSE 0 END) / COUNT(*), 2) AS damage_rate_pct
FROM patients
GROUP BY bmi_category
ORDER BY damage_rate_pct DESC;
SELECT
    CASE
        WHEN Age < 30 THEN '18-29'
        WHEN Age < 45 THEN '30-44'
        WHEN Age < 60 THEN '45-59'
        ELSE '60+'
    END AS age_group,
    COUNT(*) AS total,
    ROUND(AVG(BMI), 1) AS avg_bmi,
    ROUND(AVG(Cholesterol_Level), 1) AS avg_cholesterol,
    SUM(CASE WHEN Organ_Condition = 'Damaged' THEN 1 ELSE 0 END) AS damaged,
    ROUND(100.0 * SUM(CASE WHEN Organ_Condition = 'Damaged' THEN 1 ELSE 0 END) / COUNT(*), 2) AS damage_rate_pct
FROM patients
GROUP BY age_group
ORDER BY age_group;
SELECT Family_History_Risk, Alcohol_Consumption,
       COUNT(*) AS total,
       ROUND(100.0 * SUM(CASE WHEN Organ_Condition = 'Damaged' THEN 1 ELSE 0 END) / COUNT(*), 2) AS damage_rate_pct
FROM patients
GROUP BY Family_History_Risk, Alcohol_Consumption
ORDER BY damage_rate_pct DESC;
SELECT Organ_Condition, BP_Risk,
       COUNT(*) AS total,
       ROUND(AVG(Cholesterol_Level), 1) AS avg_cholesterol
FROM patients
GROUP BY Organ_Condition, BP_Risk
ORDER BY Organ_Condition, BP_Risk;
SELECT Gender,
       COUNT(*) AS total,
       ROUND(AVG(BMI), 1) AS avg_bmi,
       ROUND(100.0 * SUM(CASE WHEN Organ_Condition = 'Damaged' THEN 1 ELSE 0 END) / COUNT(*), 2) AS damage_rate_pct
FROM patients
GROUP BY Gender;
CREATE OR REPLACE VIEW patient_risk_score AS
SELECT
    Patient_ID,
    Age,
    Organ,
    Organ_Condition,
    (
        CASE WHEN Smoking_Status = 'Current' THEN 2
             WHEN Smoking_Status = 'Former' THEN 1 ELSE 0 END +
        CASE WHEN BMI >= 30 THEN 2
             WHEN BMI >= 25 THEN 1 ELSE 0 END +
        CASE WHEN BP_Risk = 'High' THEN 2
             WHEN BP_Risk = 'Normal' THEN 1 ELSE 0 END +
        CASE WHEN Cholesterol_Level >= 240 THEN 2
             WHEN Cholesterol_Level >= 200 THEN 1 ELSE 0 END +
        CASE WHEN Family_History_Risk = 'Yes' THEN 2 ELSE 0 END +
        CASE WHEN Alcohol_Consumption = 'High' THEN 2
             WHEN Alcohol_Consumption = 'Moderate' THEN 1 ELSE 0 END
    ) AS risk_points
FROM patients;
SELECT *,
    CASE
        WHEN risk_points >= 8 THEN 'High Risk'
        WHEN risk_points >= 4 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM patient_risk_score
ORDER BY risk_points DESC
LIMIT 20;
SELECT
    CASE
        WHEN risk_points >= 8 THEN 'High Risk'
        WHEN risk_points >= 4 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category,
    COUNT(*) AS total,
    SUM(CASE WHEN Organ_Condition = 'Damaged' THEN 1 ELSE 0 END) AS damaged,
    ROUND(100.0 * SUM(CASE WHEN Organ_Condition = 'Damaged' THEN 1 ELSE 0 END) / COUNT(*), 2) AS damage_rate_pct
FROM patient_risk_score
GROUP BY risk_category
ORDER BY damage_rate_pct DESC;