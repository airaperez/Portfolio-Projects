--========================================================================================
-- CHECKING THE DATA
--========================================================================================
SELECT TOP 5 * FROM intakes;
SELECT TOP 5 * FROM outcomes;



--========================================================================================
-- DATA QUALITY CHECKING
--========================================================================================

-- 1. Uniqueness of records ---------------------------------------------
---- From `intakes`
WITH intake_counts (int_total_rows, unique_id) AS 
(
	SELECT
		count(*) AS int_total_rows,
		count(DISTINCT Animal_ID) AS unique_id
	FROM intakes
)
SELECT
	int_total_rows,
	unique_id,
	(int_total_rows - unique_id) AS duplicates
FROM intake_counts;

---- From `outcomes`
WITH outcome_counts (out_total_rows, unique_id) AS 
(
	SELECT
		count(*) AS out_total_rows,
		count(DISTINCT Animal_ID) AS unique_id
	FROM outcomes
)
SELECT
	out_total_rows,
	unique_id,
	(out_total_rows - unique_id) AS duplicates
FROM outcome_counts;

---- Checking the duplicate IDs
------ From `intakes`
SELECT * 
FROM intakes
WHERE Animal_ID IN
(
	SELECT Animal_ID
	FROM intakes
	GROUP BY Animal_ID
	HAVING count(Animal_ID) > 1
)
ORDER BY Animal_ID;

------ From `outcomes`
SELECT * 
FROM outcomes
WHERE Animal_ID IN
(
	SELECT Animal_ID
	FROM outcomes
	GROUP BY Animal_ID
	HAVING count(Animal_ID) > 1
)
ORDER BY Animal_ID;


-- 2. Missing values ----------------------------------------------------
---- From `intakes`
SELECT
	count(*) - count(Animal_ID) AS count_id,
	count(*) - count(Name) AS count_name,
	count(*) - count(DateTime) AS count_date,
	count(*) - count(MonthYear) AS count_month,
	count(*) - count(Found_Location) AS count_loc,
	count(*) - count(Intake_Type) AS count_inttype,
	count(*) - count(Intake_Condition) AS count_intcond,
	count(*) - count(Animal_Type) AS count_type,
	count(*) - count(Sex_upon_Intake) AS count_sex,
	count(*) - count(Age_upon_Intake) AS count_age,
	count(*) - count(Breed) AS count_breed,
	count(*) - count(Color) AS count_color
FROM intakes;

---- From `outcomes`
SELECT
	count(*) - count(Animal_ID) AS count_id,
	count(*) - count(Name) AS count_name,
	count(*) - count(DateTime) AS count_date,
	count(*) - count(MonthYear) AS count_month,
	count(*) - count(Date_of_Birth) AS count_birth,
	count(*) - count(Outcome_Type) AS count_outtype,
	count(*) - count(Outcome_Subtype) AS count_outcond,
	count(*) - count(Animal_Type) AS count_type,
	count(*) - count(Sex_upon_Outcome) AS count_sex,
	count(*) - count(Age_upon_Outcome) AS count_age,
	count(*) - count(Breed) AS count_breed,
	count(*) - count(Color) AS count_color
FROM outcomes;

------ Checking the null values in `Outcome_Type`
SELECT *
FROM outcomes
WHERE Outcome_Type IS NULL

WITH null_outcome (id) AS
(
	SELECT Animal_ID AS id
	FROM outcomes
	WHERE Outcome_Type IS NULL
)
SELECT *
FROM intakes
WHERE Animal_ID IN (SELECT id FROM null_outcome)



--========================================================================================
-- DATA CLEANING
--========================================================================================

-- 1. Adding new columns for the `intakes` table ------------------------
ALTER TABLE intakes
ADD Animal_Index INT,
	Entry_Order INT,
	Intake_Age VARCHAR(50);

---- The column `Animal_Index` will serve as a primary key within the `intakes` table
DECLARE @RowIntake INT = 0;
UPDATE intakes
SET Animal_Index = @RowIntake,
	@RowIntake = @RowIntake + 1;

---- The column `Entry_Order` shows their entry frequency as of the given DateTime
WITH entry_order (index_key, id_order) AS
(
	SELECT
		Animal_Index AS index_key,
		RANK() OVER (PARTITION BY Animal_ID ORDER BY DateTime) AS id_order
	FROM intakes
)
UPDATE intakes
SET intakes.Entry_Order = entry_order.id_order
FROM entry_order
WHERE intakes.Animal_Index = entry_order.index_key;

---- The column `Intake_Age` will contain the cleaned age values, discretized
-- Checking the unique values in `Age_upon_Intake`
SELECT
	DISTINCT Age_upon_Intake
FROM intakes
ORDER BY Age_upon_Intake;

-- Updating the `Intake_Age` column
WITH years (index_key, time_value, time_unit) AS
(
	SELECT
		Animal_Index AS index_key,
		TRIM(LEFT(Age_upon_Intake, CHARINDEX(' ', Age_upon_Intake))) AS time_value,
		SUBSTRING(Age_upon_Intake, CHARINDEX(' ', Age_upon_Intake)+1, LEN(Age_upon_Intake)) AS time_unit
	FROM intakes
)
UPDATE intakes
SET intakes.Intake_Age =
	CASE
		WHEN (y.time_unit NOT LIKE '%year%') AND (y.time_unit <> 'NULL') THEN 'Less than a year'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value IN (0, -1)) THEN 'Less than a year'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value BETWEEN 1 AND 5) THEN '1 to 5 years'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value < -1) THEN '1 to 5 years'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value BETWEEN 6 AND 10) THEN '6 to 10 years'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value BETWEEN 11 AND 15) THEN '11 to 15 years'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value BETWEEN 16 AND 20) THEN '16 to 20 years'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value > 20) THEN 'More than 20 years'
		ELSE NULL
	END
FROM years AS y
WHERE intakes.Animal_Index = y.index_key;


-- 2. Adding new columns for the `outcomes` table -----------------------
ALTER TABLE outcomes
ADD Animal_Index INT,
	Exit_Order INT,
	Outcome_Age VARCHAR(50);

-- The column `Animal_Index` will serve as a primary key within the	`outcomes` table
DECLARE @RowOutcome INT = 0;
UPDATE outcomes
SET Animal_Index = @RowOutcome,
	@RowOutcome = @RowOutcome + 1;

-- The column `Exit_Order` shows their release frequency as of the given DateTime
WITH exit_order (index_key, id_order) AS
(
	SELECT
		Animal_Index AS index_key,
		RANK() OVER (PARTITION BY Animal_ID ORDER BY DateTime) AS id_order
	FROM outcomes
)
UPDATE outcomes
SET outcomes.Exit_Order = exit_order.id_order
FROM exit_order
WHERE outcomes.Animal_Index = exit_order.index_key;

---- The column `Outcome_Age` will contain the cleaned age values, discretized
-- Checking the unique values in `Age_upon_Outcome`
SELECT
	DISTINCT Age_upon_Outcome
FROM outcomes
ORDER BY Age_upon_Outcome;

-- Updating the `Outcome_Age` column
WITH years (index_key, time_value, time_unit) AS
(
	SELECT
		Animal_Index AS index_key,
		TRIM(LEFT(Age_upon_Outcome, CHARINDEX(' ', Age_upon_Outcome))) AS time_value,
		SUBSTRING(Age_upon_Outcome, CHARINDEX(' ', Age_upon_Outcome)+1, LEN(Age_upon_Outcome)) AS time_unit
	FROM outcomes
)
UPDATE outcomes
SET outcomes.Outcome_Age =
	CASE
		WHEN (y.time_unit NOT LIKE '%year%') AND (y.time_unit <> 'NULL') THEN 'Less than a year'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value IN (0, -1)) THEN 'Less than a year'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value BETWEEN 1 AND 5) THEN '1 to 5 years'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value < -1) THEN '1 to 5 years'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value BETWEEN 6 AND 10) THEN '6 to 10 years'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value BETWEEN 11 AND 15) THEN '11 to 15 years'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value BETWEEN 16 AND 20) THEN '16 to 20 years'
		WHEN (y.time_unit LIKE '%year%') AND (y.time_value > 20) THEN 'More than 20 years'
		ELSE NULL
	END
FROM years AS y
WHERE outcomes.Animal_Index = y.index_key;


-- 3. Further cleaning of the entry and exit order columns --------------
-- Checking of the data
SELECT
	i.Animal_ID,
	i.Entry_Order,
	o.Exit_Order,
	i.DateTime AS Intake_Date,
	o.DateTime AS Outcome_Date,
	DATEDIFF(day, i.DateTime, o.DateTime) AS Duration
FROM intakes AS i
INNER JOIN outcomes AS o
ON i.Animal_ID = o.Animal_ID AND
	i.Entry_Order = o.Exit_Order
WHERE DATEDIFF(day, i.DateTime, o.DateTime) < 0
ORDER BY Animal_ID, Entry_Order;

-- Updating the Entry_Order values of select rows
WITH negative_duration (index_key, id, Entry_Order, Exit_Order) AS
(
	SELECT
		i.Animal_Index AS index_key,
		i.Animal_ID AS id,
		i.Entry_Order,
		o.Exit_Order
	FROM intakes AS i
	INNER JOIN outcomes AS o
	ON i.Animal_ID = o.Animal_ID AND
		i.Entry_Order = o.Exit_Order
	WHERE DATEDIFF(day, i.DateTime, o.DateTime) < 0
)
UPDATE intakes
SET intakes.Entry_Order = intakes.Entry_Order + 1
FROM negative_duration AS nd
WHERE intakes.Animal_Index = nd.index_key AND
	intakes.Animal_ID IN (SELECT id FROM negative_duration);


-- 4. Adding a column containing the animal's stay duration -------------
---- For `intakes`
ALTER TABLE intakes
ADD Stay_Duration INT;

WITH stay (index_key, id, Duration) AS
(
	SELECT
		i.Animal_Index AS index_key,
		i.Animal_ID AS id,
		DATEDIFF(day, i.DateTime, o.DateTime) AS Duration
	FROM intakes AS i
	LEFT JOIN outcomes AS o
	ON i.Animal_ID = o.Animal_ID AND
		i.Entry_Order = o.Exit_Order
)
UPDATE intakes
SET intakes.Stay_Duration = stay.Duration
FROM stay
WHERE intakes.Animal_Index = stay.index_key;

---- For `outcomes`
ALTER TABLE outcomes
ADD Stay_Duration INT;

WITH stay (index_key, id, Duration) AS
(
	SELECT
		o.Animal_Index AS index_key,
		o.Animal_ID AS id,
		DATEDIFF(day, i.DateTime, o.DateTime) AS Duration
	FROM outcomes AS o
	LEFT JOIN intakes AS i
	ON i.Animal_ID = o.Animal_ID AND
		i.Entry_Order = o.Exit_Order
)
UPDATE outcomes
SET outcomes.Stay_Duration = stay.Duration
FROM stay
WHERE outcomes.Animal_Index = stay.index_key;


/*-----------------------------------------------------------------------

The final cleaned tables are exported from MS SQL Server into CSV files
for utilization in Python for data visualization purposes.

------------------------------------------------------------------------*/
SELECT * FROM intakes; -- Saved as `Intakes_Clean.csv`
SELECT * FROM outcomes; -- Saved as `Outcomes_Clean.csv`



--========================================================================================
-- EXPLORATORY DATA ANALYSIS
--========================================================================================

---------------------------
--		  OVERALL
---------------------------

-- Total number of animals handled by the shelter since October 2013, excluding duplicates
WITH all_animals (Animal_ID) AS
(
	SELECT DISTINCT Animal_ID
	FROM intakes
	UNION
	SELECT DISTINCT Animal_ID
	FROM outcomes
) 
SELECT
	count(DISTINCT Animal_ID) AS Total_Animals
FROM all_animals;

-- Yearly intakes and outcomes
---- Number of intakes each year
SELECT
	DISTINCT SUBSTRING(CAST(DateTime AS varchar), 1, 7) AS MonthYear,
	count(*) AS Intake_Count
FROM intakes
GROUP BY SUBSTRING(CAST(DateTime AS varchar), 1, 7)
ORDER BY MonthYear;

---- Number of outcomes each year
SELECT
	DISTINCT SUBSTRING(CAST(DateTime AS varchar), 1, 7) AS MonthYear,
	count(*) AS Outcome_Count
FROM outcomes
GROUP BY SUBSTRING(CAST(DateTime AS varchar), 1, 7)
ORDER BY MonthYear;


---------------------------
--		Animal Type
---------------------------

-- Total number of animals handled by the shelter per animal type, excluding duplicates
WITH all_animals (Animal_ID, Animal_Type) AS
(
	SELECT DISTINCT Animal_ID, Animal_Type
	FROM intakes
	UNION
	SELECT DISTINCT Animal_ID, Animal_Type
	FROM outcomes
) 
SELECT
	DISTINCT Animal_Type,
	count(DISTINCT Animal_ID) AS AnimalCount
FROM all_animals
GROUP BY Animal_Type
ORDER BY AnimalCount DESC;

-- Percentage of the different intake types relative to each animal type
WITH intake_counts (Animal_Type, Intake_Type, Intake_Count)  AS
(
	SELECT
		DISTINCT Animal_Type,
		Intake_Type,
		count(*) AS Intake_Count
	FROM intakes
	GROUP BY Animal_Type, Intake_Type
)
SELECT
	Animal_Type,
	Intake_Type,
	Intake_Count,
	CAST(
		(Intake_Count*100.0) / (SUM(Intake_Count) OVER (PARTITION BY Animal_Type))
		AS DECIMAL(5,3)) AS Intake_Percentage
FROM intake_counts
ORDER BY Animal_Type, Intake_Percentage DESC;

-- Percentage of the different outcome types relative to each animal type
WITH outcome_counts (Animal_Type, Outcome_Type, Outcome_Count)  AS
(
	SELECT
		DISTINCT Animal_Type,
		Outcome_Type,
		count(*) AS Outcome_Count
	FROM outcomes
	WHERE Outcome_Type IS NOT NULL
	GROUP BY Animal_Type, Outcome_Type
)
SELECT
	Animal_Type,
	Outcome_Type,
	Outcome_Count,
	CAST(
		(Outcome_Count*100.0) / (SUM(Outcome_Count) OVER (PARTITION BY Animal_Type))
		AS DECIMAL(5,3)) AS Outcome_Percentage
FROM outcome_counts
ORDER BY Animal_Type, Outcome_Percentage DESC;


---------------------------
--	   Age of Animal
---------------------------

-- Counts of intake and outcome ages per animal type
WITH int_age (Animal_Type, Intake_Age, Age_Count, Age_Order) AS
(
	SELECT
		DISTINCT Animal_Type,
		Intake_Age,
		count(DISTINCT Animal_ID) AS Age_Count,
		CASE Intake_Age
			WHEN 'Less than a year' THEN 1
			WHEN '1 to 5 years' THEN 2
			WHEN '6 to 10 years' THEN 3
			WHEN '11 to 15 years' THEN 4
			WHEN '16 to 20 years' THEN 5
			WHEN 'More than 20 years' THEN 6
		END AS Age_Order
	FROM intakes
	WHERE Intake_Age IS NOT NULL
	GROUP BY Animal_Type, Intake_Age
),
out_age (Animal_Type, Outcome_Age, Age_Count, Age_Order) AS
(
	SELECT
		DISTINCT Animal_Type,
		Outcome_Age,
		count(DISTINCT Animal_ID) AS Age_Count,
		CASE Outcome_Age
			WHEN 'Less than a year' THEN 1
			WHEN '1 to 5 years' THEN 2
			WHEN '6 to 10 years' THEN 3
			WHEN '11 to 15 years' THEN 4
			WHEN '16 to 20 years' THEN 5
			WHEN 'More than 20 years' THEN 6
		END AS Age_Order
	FROM outcomes
	WHERE Outcome_Age IS NOT NULL
	GROUP BY Animal_Type, Outcome_Age
)
SELECT
	i.Animal_Type,
	Intake_Age AS Age,
	i.Age_Count AS Intake_Age_Count,
	o.Age_Count AS Outcome_Age_Count
FROM int_age AS i
FULL JOIN out_age AS o
ON i.Animal_Type = o.Animal_Type AND
	i.Intake_Age = o.Outcome_Age
ORDER BY Animal_Type, i.Age_Order;


---------------------------
--	  Duration of Stay
---------------------------

-- Average, minimum, and maximum stay of animals, grouped by animal type
SELECT
	DISTINCT i.Animal_Type,
	AVG(i.Stay_Duration) AS Avg_Days,
	MIN(i.Stay_Duration) AS Min_Days,
	MAX(i.Stay_Duration) AS Max_Days
FROM intakes AS i
GROUP BY i.Animal_Type
ORDER BY Avg_Days;

-- Average, minimum, and maximum time before animals were returned to their owners
SELECT
	DISTINCT i.Animal_Type,
	AVG(i.Stay_Duration) AS Avg_Days_Return,
	MIN(i.Stay_Duration) AS Min_Days_Return,
	MAX(i.Stay_Duration) AS Max_Days_Return
FROM intakes AS i
INNER JOIN outcomes AS o
ON i.Animal_ID = o.Animal_ID AND
	i.Entry_Order = o.Exit_Order
WHERE o.Outcome_Type = 'Return to Owner'
GROUP BY i.Animal_Type, o.Outcome_Type
ORDER BY Avg_Days_Return;

-- Average duration of animals' stay in the shelter per year
SELECT
	DISTINCT YEAR(o.DateTime) AS Year,
	i.Animal_Type,
	AVG(i.Stay_Duration) AS Days_Duration
FROM intakes AS i
INNER JOIN outcomes AS o
ON i.Animal_ID = o.Animal_ID AND
	i.Entry_Order = o.Exit_Order
GROUP BY YEAR(o.DateTime), i.Animal_Type
ORDER BY i.Animal_Type, Year;


---------------------------
--	Condition of Animal
---------------------------

-- Which animal is commonly brought to the shelter as sick?
WITH int_conditions (Animal_Type, Sick_Count, Total_Count) AS
(
	SELECT
		DISTINCT Animal_Type,
		COUNT(
			CASE WHEN Intake_Condition NOT IN
				('Aged', 'Feral', 'Normal', 'Nursing', 'Other', 'Pregnant', 'Unknown', 'Space')
			THEN 1 END) AS Sick_Count,
		COUNT(*) AS Total_Count
	FROM intakes
	GROUP BY Animal_Type
)
SELECT
	Animal_Type,
	CAST((Sick_Count*100.0)/Total_Count AS DECIMAL(5,2)) AS Sick_Percentage
FROM int_conditions
ORDER BY Sick_Percentage DESC;

-- Trend of the number of intakes for sick animals across the years
SELECT
	DISTINCT YEAR(DateTime) AS Year,
	Animal_Type,
	COUNT(*) AS Sick_Count
FROM intakes
WHERE Intake_Condition NOT IN
	('Aged', 'Feral', 'Normal', 'Nursing', 'Other', 'Pregnant', 'Unknown', 'Space')
GROUP BY YEAR(DateTime), Animal_Type
ORDER BY Animal_Type, Year;

-- Common outcomes observed for sick animals
SELECT
	DISTINCT o.Outcome_Type,
	COUNT(*) AS Outcome_Counts
FROM intakes AS i
INNER JOIN outcomes AS o
ON i.Animal_ID = o.Animal_ID AND
	i.Entry_Order = o.Exit_Order
WHERE i.Intake_Condition NOT IN
		('Aged', 'Feral', 'Normal', 'Nursing', 'Other', 'Pregnant', 'Unknown', 'Space')
	AND o.Outcome_Type IS NOT NULL
GROUP BY o.Outcome_Type
ORDER BY Outcome_Counts DESC;