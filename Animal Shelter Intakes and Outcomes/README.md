<!--========================================================================================================================-->
<!-- INTRODUCTION -->
<!--========================================================================================================================-->

![5](https://github.com/airaperez/Portfolio-Projects/assets/110292677/8f1924f5-8224-452a-97b8-fed94edb6b45)

# <p align="center"> Analysis of Animal Shelter Intakes and Outcomes </p>

###### <p align="center"> <i>Copyright © 2024 Aira Perez. All rights reserved.</i> </p>


-----


Using SQL and Python, I performed an exploratory data analysis on the characteristics of the animals that were taken in and released from the [Austin Animal Center](https://www.austintexas.gov/austin-animal-center), the largest no-kill animal shelter in the United States.

|Tool|Skills Used|
|---|---|
|MS SQL Server|Data cleaning, data exploration, table joins, updating tables, windows function, Common Table Expressions (CTE), aggregation|
|Python|Pandas, Matplotlib, Pandasql (SQLite Query Language), data manipulation, data visualization|



# Table of Contents
1. [Data Description](#data-description)
2. [Data Quality Checking](#data-quality-checking)
3. [Data Cleaning](#data-cleaning)
4. [Exploratory Data Analysis](#exploratory-data-analysis)
   1. [Overview of Shelter Operations](#overview-of-shelter-operations)
   2. [Exploration by Animal Type](#exploration-by-animal-type)
   3. [Analyzing the Animals' Duration of Stay](#analyzing-the-animals-duration-of-stay)
   4. [Analyzing the Animals' Intake Conditions](#analyzing-the-animals-intake-conditions)




<!---     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -->
# Data Description
The data is sourced from the [Austin Open Data Portal](https://data.austintexas.gov/), retrieved last April 9, 2024. The following two tables were used for the analysis:
* **Austin Animal Center Intakes**: this contains the records of the animals as they arrive at the shelter (161,099 rows)
* **Austin Animal Center Outcomes**: this contains the records of the animals as they leave the shelter (161,228 rows)

The tables are named `intakes` and `outcomes` for the purposes of this project. Both contain the data of animals that the shelter handled from October 1, 2013 to present. The first 5 rows of each table are presented below:

|Intakes|
|---|

```sql
SELECT TOP 5 * FROM intakes;
```

![1-select](https://github.com/airaperez/Portfolio-Projects/assets/110292677/20adb10f-6748-4f9a-b001-6a4ae5f0b58b)


|Outcomes|
|---|

```sql
SELECT TOP 5 * FROM outcomes;
```

![2-select](https://github.com/airaperez/Portfolio-Projects/assets/110292677/2aa30370-4d2c-4792-8170-a8e3b3d89e5a)

<hr>





<!--========================================================================================================================-->
<!-- DATA QUALITY CHECKS -->
<!--========================================================================================================================-->

# Data Quality Checking

<!---     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -->
### Checking the uniqueness of records

<!-------------------------------------- [[(start) TABLE OF CODE ---------------------------------------->

<table>
<tr>
	<td> <p align="center"><strong>Intakes</strong></p> </td>
	<td> <p align="center"><strong>Outcomes</strong></p> </td>
</tr>
<tr>
<td>

```sql
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
```

</td>
<td>
    
```sql
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
```
</td>
</tr>
</table>

<!--------------------------------------  TABLE OF CODE (end)]] ---------------------------------------->

**Intakes**

|int_total_rows|unique_id|duplicates|
|---:|---:|---:|
|161,099|144,572|16,527|

**Outcomes**

|out_total_rows|unique_id|duplicates|
|---:|---:|---:|
|161,228|144,701|16,527|

It can be observed that, in both tables, there are 16,527 duplicate Animal IDs.

Further, it is seen that the `outcomes` table has a few more rows than the `intakes` table. This may be because there were animals already in the shelter prior to the creation of the database, resulting in unrecorded intake data.


<!---     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -->
#### Examining duplicate IDs

<!-------------------------------------- [[(start) TABLE OF CODE  ---------------------------------------->

<table>
<tr>
	<td> <p align="center"><strong>Intakes</strong></p> </td>
	<td> <p align="center"><strong>Outcomes</strong></p> </td>
</tr>
<tr>
<td>

```sql
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
```

</td>
<td>
    
```sql
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
```
</td>
</tr>
</table>

<!--------------------------------------  TABLE OF CODE (end)]] ---------------------------------------->

**Intakes** (first 5 duplicate records)

|Animal_ID|Name|DateTime|...|Age_upon_Intake|Breed|Color|
|---|---|---|---|---|---|---|
|A006100|Scamp|2014-12-19 10:21:00|...|7 years|Spinone Italiano Mix|Yellow/White|
|A006100|Scamp|2017-12-07 14:07:00|...|10 years|Spinone Italiano Mix|Yellow/White|
|A006100|Scamp|2014-03-07 14:26:00|...|6 years|Spinone Italiano Mix|Yellow/White|
|A245945|Boomer|2014-07-03 17:55:00|...|14 years|Labrador Retriever Mix|Tan|
|A245945|Boomer|2015-05-20 22:34:00|...|15 years|Labrador Retriever Mix|Tan|

**Outcomes** (first 5 duplicate records)

|Animal_ID|Name|DateTime|...|Age_upon_Outcome|Breed|Color|
|---|---|---|---|---|---|---|
|A006100|Scamp|2014-12-20 16:35:00|...|7 years|Spinone Italiano Mix|Yellow/White|
|A006100|Scamp|2017-12-07 0:00:00|...|10 years|Spinone Italiano Mix|Yellow/White|
|A006100|Scamp|2014-03-08 17:10:00|...|6 years|Spinone Italiano Mix|Yellow/White|
|A245945|Boomer|2014-07-04 15:26:00|...|14 years|Labrador Retriever Mix|Tan|
|A245945|Boomer|2015-05-25 11:49:00|...|15 years|Labrador Retriever Mix|Tan|

Upon further inspection, it can be seen the duplicate IDs do not pertain to duplicate records but rather are instances wherein the same animal is brought to and released from the shelter multiple times. This is evident from the differing dates and age values of each record. This is likely also the reason why the same number of duplicates are observed in both table, as these records are paired.


<!---     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -->
### Missing values

<!-------------------------------------- [[(start) TABLE OF CODE  ---------------------------------------->

<table>
<tr>
	<td> <p align="center"><strong>Intakes</strong></p> </td>
	<td> <p align="center"><strong>Outcomes</strong></p> </td>
</tr>
<tr>
<td>

```sql
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
```

</td>
<td>
    
```sql
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
```
</td>
</tr>
</table>

<!--------------------------------------  TABLE OF CODE (end)]] ---------------------------------------->

**Intakes**

|count_id|count_name|count_date|count_month|count_loc|count_inttype|count_intcond|count_type|count_sex|count_age|count_breed|count_color|
|---|---|---|---|---|---|---|---|---|---|---|---|
|0|46281|0|0|0|0|0|0|0|0|0|0|

**Outcomes**

|count_id|count_name|count_date|count_month|count_birth|count_outtype|count_outcond|count_type|count_sex|count_age|count_breed|count_color|
|---|---|---|---|---|---|---|---|---|---|---|---|
|0|46190|0|0|0|35|87254|0|0|0|0|0|

In both tables, there are null values in the `Name` column, indicating that there are animals that have not been named. However, this does not pose a problem since all animals were still provided with a unique ID.

It can also be observed that the `outcomes` table has null values in the `Outcome_Type` column. This column indicates what happened to the animal after being released from the shelter (ex. returned to their owner, transferred, adopted, etc.). Given its significance, it is essential for this column not contain any missing entries. However, upon further observation of the records concerned, not enough information was found that could hint at what the missing values may indicate, making it difficult to impute its values. Thus, the blanks were left as is.

<hr>




<!--========================================================================================================================-->
<!-- DATA CLEANING -->
<!--========================================================================================================================-->

# Data Cleaning

<!---     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -->
### Adding new columns

#### 1. Animal Index

As observed earlier, there were duplicates of the `Animal_ID`. To make it easier to reference a specific record within the same table, each row was assigned an index number from 1 to the total number of rows of that table. This column is named `Animal_Index`.

<!-------------------------------------- [[(start) TABLE OF CODE  ---------------------------------------->

<table>
<tr>
	<td> <p align="center"><strong>Intakes</strong></p> </td>
	<td> <p align="center"><strong>Outcomes</strong></p> </td>
</tr>
<tr>
<td>

```sql
DECLARE @RowIntake INT = 0;
UPDATE intakes
SET Animal_Index = @RowIntake,
	@RowIntake = @RowIntake + 1;
```

</td>
<td>
    
```sql
DECLARE @RowOutcome INT = 0;
UPDATE outcomes
SET Animal_Index = @RowOutcome,
	@RowOutcome = @RowOutcome + 1;
```
</td>
</tr>
</table>

<!--------------------------------------  TABLE OF CODE (end)]] ---------------------------------------->

#### 2. Entry and Exit Order

Most observations from the `intakes` and `outcomes` table are paired, denoting the instance when the same animal was taken in and released from the shelter. However, it was noted earlier that there were animals that have went in and out of the shelter more than once. Thus, I added a new column to signify the number of times they have been taken in and out of the shelter as of the specified date, named `Entry_Order` and `Exit_Order`, respectively. This column together with `Animal_ID` will serve as the primary key.

<!-------------------------------------- [[(start) TABLE OF CODE  ---------------------------------------->

<table>
<tr>
	<td> <p align="center"><strong>Intakes</strong></p> </td>
	<td> <p align="center"><strong>Outcomes</strong></p> </td>
</tr>
<tr>
<td>

```sql
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
```

</td>
<td>
    
```sql
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
```
</td>
</tr>
</table>

<!--------------------------------------  TABLE OF CODE (end)]] ---------------------------------------->

It was noted earlier that the `outcomes` table has a few more rows, indicating unrecorded intake data. Hence, it is possible that some of the animals that have been in the shelter multiple times also lack intake records.

To check this, using `Animal_ID` and the newly created `Entry_Order` and `Exit_Order` as primary keys, the time difference between intake and outcome dates were compared. It was found that 136 records returned a negative time difference, indicating that the outcome date preceded the intake date. To correct this, the `Entry_Order` of the 136 records was incremented by 1. 
 
```sql
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
```

#### 3. Cleaned intake and outcome age

Upon inspection of the `Age_upon_Intake` and `Age_upon_Outcome` columns, it is found that no consistent format or time unit is being used. Records contained values expressed in days, weeks, months, or years, while some values were only approximates of the animal's age (ex. "-2 years", "0 year").

To maintain consistency, new columns were created in both tables to categorize age groups. The values are categorized as follows:
* Less than a year
* 1 to 5 years
* 6 to 10 years
* 11 to 15 years
* 16 to 20 years
* More than 20 years

<!-------------------------------------- [[(start) TABLE OF CODE  ---------------------------------------->

<table>
<tr>
	<td> <p align="center"><strong>Intakes</strong></p> </td>
	<td> <p align="center"><strong>Outcomes</strong></p> </td>
</tr>
<tr>
<td>

```sql
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
```

</td>
<td>
    
```sql
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
```
</td>
</tr>
</table>

<!--------------------------------------  TABLE OF CODE (end)]] ---------------------------------------->

#### 4. Stay Duration

One of the variables I want to explore is the average duration of an animal's stay in the shelter. Now that primary keys have been cleaned and established for both tables, I utilized these to calculate how long each animal has been in the shelter during each of their visits.

<!-------------------------------------- [[(start) TABLE OF CODE  ---------------------------------------->

<table>
<tr>
	<td> <p align="center"><strong>Intakes</strong></p> </td>
	<td> <p align="center"><strong>Outcomes</strong></p> </td>
</tr>
<tr>
<td>

```sql
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
```

</td>
<td>
    
```sql
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
```
</td>
</tr>
</table>

<!--------------------------------------  TABLE OF CODE (end)]] ---------------------------------------->

<hr>

<p align="center"><i> The cleaned tables are then exported from MS SQL Server into CSV files for utilization in Python for data visualization purposes. </i></p>

<hr>




<!--========================================================================================================================-->
<!-- EXPLORATORY DATA ANALYSIS -->
<!--========================================================================================================================-->

# Exploratory Data Analysis

<!---     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -->
### Overview of Shelter Operations

#### Total number of animals handled by the shelter since October 1, 2013

```sql
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
```

***Output:***

|Total_Animals|
|---:|
|145,386|

The total number of distinct animals handled by the shelter since the creation of the database is `145,386`, which is indicative of the shelter's capacity as well as success the past 11 years.

#### Yearly trend of intakes and outcomes

```python
month_int = sqldf(
"""
    SELECT
        DISTINCT SUBSTR(DateTime, 1, 7) AS MonthYear,
        count(*) AS Intake_Count
    FROM intakes
    GROUP BY SUBSTR(DateTime, 1, 7)
    ORDER BY MonthYear;
""", globals())

month_out = sqldf(
"""
    SELECT
        DISTINCT SUBSTR(DateTime, 1, 7) AS MonthYear,
        count(*) AS Outcome_Count
    FROM outcomes
    GROUP BY SUBSTR(DateTime, 1, 7)
    ORDER BY MonthYear;
""", globals())

month_animals = pd.merge(month_int, month_out)
month_animals['MonthYear'] = pd.to_datetime(month_animals['MonthYear'], format='%Y-%m')

fig, ax = plt.subplots()
month_animals.set_index('MonthYear').plot(kind='line',ax=ax)
plt.grid(axis='x', linestyle='--')
plt.title("Yearly Intakes and Outcomes")
plt.xlabel("Year")
plt.legend(labels=['Intakes', 'Outcomes'])
plt.show()
```

![Figure_1](https://github.com/airaperez/Portfolio-Projects/assets/110292677/599dae46-2e11-4d1f-8ce4-ed4d60480fce)


Both intakes and outcomes follow a similar trend, as illustrated in the figure above. A seasonal pattern is evident in both, wherein higher numbers are commonly observed during the middle of the year and drops by the year's end. As expected, during the COVID-19 pandemic, a drastic decrease in both intakes and outcomes are observed. However, since 2021, the numbers have been starting to increase and revert to its pattern pre-pandemic.

#### Monthly trend of intakes and outcomes

<!-------------------------------------- [[(start) TABLE OF CODE  ---------------------------------------->

<table>
<tr>
	<td> <p align="center"><strong>Intakes</strong></p> </td>
	<td> <p align="center"><strong>Outcomes</strong></p> </td>
</tr>
<tr>
<td>

```python
month_animals['Year'] = [date.year for date in month_animals['MonthYear']]
month_animals['Month'] = [date.month for date in month_animals['MonthYear']]
monthly_intakes = month_animals.drop(columns=['MonthYear','Outcome_Count'])
month_pivot_int = monthly_intakes.pivot(index='Month', columns='Year', values='Intake_Count')

year_colors = cm.get_cmap('tab20')(range(12))

month_pivot_int.plot.box(patch_artist=True,
                         color={'boxes':'saddlebrown', 'whiskers':'black', 'medians':'black', 'caps':'black'},
                         flierprops={'markerfacecolor':'dimgray', 'markeredgecolor':'white'})
plt.xticks(ticks=list(range(1, 13)), labels=list(calendar.month_abbr)[1:13])
plt.ylim(bottom=0, top=2500)
plt.grid(axis='x', linestyle='--')
plt.title("Monthly Trend of Animal Intakes")
plt.ylabel("Number of Intakes")
plt.xlabel("")
plt.show()
```

</td>
<td>
    
```python
monthly_outcomes = month_animals.drop(columns=['MonthYear','Intake_Count'])
month_pivot_out = monthly_outcomes.pivot(index='Month', columns='Year', values='Outcome_Count')

month_pivot_out.plot.box(patch_artist=True,
                         color={'boxes':'goldenrod', 'whiskers':'black', 'medians':'black', 'caps':'black'},
                         flierprops={'markerfacecolor':'dimgray', 'markeredgecolor':'white'})
plt.xticks(ticks=list(range(1, 13)), labels=list(calendar.month_abbr)[1:13])
plt.ylim(bottom=0, top=2500)
plt.grid(axis='x', linestyle='--')
plt.title("Monthly Trend of Animal Outcomes")
plt.ylabel("Number of Outcomes")
plt.xlabel("")
plt.show()
```
</td>
</tr>
</table>

<!--------------------------------------  TABLE OF CODE (end)]] ---------------------------------------->

|![Figure_2](https://github.com/airaperez/Portfolio-Projects/assets/110292677/36c16222-e5cc-431c-a476-4d305500cc6d)|![Figure_3](https://github.com/airaperez/Portfolio-Projects/assets/110292677/4e32de36-61a5-4f67-90fa-464b254b169e)|
|---|---|

To further examine the pattern of intakes and outcomes, the distribution of the two across each month were analyzed. Through the plots above, it is more evident that the number of animals taken in and out of the shelter increases from January to July, and drops significantly by August.



<!---     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -->
### Exploration by Animal Type

#### Total number of animals handled by the shelter per animal type

```python
animal_types = sqldf(
"""
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
""", globals())

animal_types['Animal_Type'] = pd.Categorical(animal_types['Animal_Type'],
                                             categories=['Dog', 'Cat', 'Bird', 'Livestock', 'Other'],
                                             ordered=True)
type_order = animal_types['Animal_Type'].cat.codes

fig, ax = plt.subplots()
ax.barh(type_order, animal_types['AnimalCount'],
                align='center', color='sienna', tick_label=animal_types['Animal_Type'])
ax.invert_yaxis()
ax.set_title("Number of Animals per Type")
ax.set_xlabel("Count")
ax.set_xlim(right=90000)
for c in ax.containers:
    ax.bar_label(c, labels=[f' {x:,.0f}' for x in c.datavalues])
plt.show()
```

![Figure_4](https://github.com/airaperez/Portfolio-Projects/assets/110292677/74af1261-feec-48fe-9979-655441aaf262)

It can be observed that a majority of the animals commonly handled by the shelter are cats and dogs. However, it is seen that the shelter does not cater solely to dogs and cats, as they have also handled birds, livestock, and other animals, albeit rarely as compared to the common household pets.


#### Distribution of the different intake types relative to each animal type

```python
perc_intake = sqldf(
"""
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
""", globals())

pivot_intake = perc_intake.pivot(index='Animal_Type', columns='Intake_Type', values='Intake_Percentage').fillna(0)

pivot_intake.plot(kind='barh', stacked=True)
plt.xlabel("Percentage of Animals (%)")
plt.ylabel("")
plt.title("Breakdown of Animal Intakes per Type")
plt.legend(bbox_to_anchor=(1, 1.15), ncol=6, loc='upper right')
plt.xlim(right=100)
plt.gca().invert_yaxis()
plt.show()
```

![Figure_5](https://github.com/airaperez/Portfolio-Projects/assets/110292677/eea718d2-b079-48d5-b00b-f11548c317c1)


Most of the animals were more commonly taken in as strays, with the exception of those categorized under `Other`, which has most animals tagged as wildlife. This gives us an idea on what other types of animals the shelter may have handled. Further, the high percentage of strays taken in by the shelter shows that it is very welcoming and is able accomodate a large number of animals.

There is also a small percentage of animals that were taken in for a euthanasia request, which shows that while uncommon, the Austin Animal Center also provides this type of service.


#### Distribution of the different outcome types relative to each animal type

```python
perc_outcome = sqldf(
"""
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
""", globals())

pivot_outcome = perc_outcome.pivot(index='Animal_Type', columns='Outcome_Type', values='Outcome_Percentage').fillna(0)

outcome_colors = cm.get_cmap('Set3')(range(11))

pivot_outcome.plot(kind='barh', stacked=True, color=outcome_colors)
plt.xlabel("Percentage of Animals (%)")
plt.ylabel("")
plt.title("Breakdown of Animal Outcomes per Type")
plt.legend(bbox_to_anchor=(1, 1.13), ncol=11, loc='upper right')
plt.xlim(right=100)
plt.gca().invert_yaxis()
plt.show()
```

![Figure_6](https://github.com/airaperez/Portfolio-Projects/assets/110292677/df4addd6-39cf-4994-b4cc-0743ab33345f)


As for the animals' outcomes, most are either adopted or transferred to a different shelter. However, it is surprising that while only a small percentage of animals were taken in for a euthanasia request, a higher percentage of animals ended up undergoing euthanasia, especially those categorized under `Other`.


#### Distribution of Age Groups

```python
age_categories = ['Less than a year', '1 to 5 years', '6 to 10 years',
                  '11 to 15 years', '16 to 20 years', 'More than 20 years']

# Intakes Data
intakes['Intake_Age'] = pd.Categorical(intakes['Intake_Age'],
                                       categories=age_categories,
                                       ordered=True)
ages_int = intakes.groupby(['Animal_Type', 'Intake_Age']).size().reset_index(name='Age_Count')
ages_int_p = ages_int.pivot(index='Intake_Age', columns='Animal_Type', values='Age_Count').fillna(0).reset_index()

# Outcomes Data
outcomes['Outcome_Age'] = pd.Categorical(outcomes['Outcome_Age'],
                                         categories=age_categories,
                                         ordered=True)
ages_out = outcomes.groupby(['Animal_Type', 'Outcome_Age']).size().reset_index(name='Age_Count')
ages_out_p = ages_out.pivot(index='Outcome_Age', columns='Animal_Type', values='Age_Count').fillna(0).reset_index()

# Plot
fig, ax = plt.subplots(2,3)
axes = ax.flatten()
for i, col in enumerate(ages_out_p.drop(columns='Outcome_Age')):
    axes[i].bar(np.arange(6)-0.2, ages_int_p[col], width=0.4, color='saddlebrown')
    axes[i].bar(np.arange(6)+0.2, ages_out_p[col], width=0.4, color='goldenrod')
    axes[i].set_title(f'{col}s')
    axes[i].set_xticks(np.arange(6))
    axes[i].set_xticklabels(['<1', '[1,5]', '[6,10]', '[11,15]', '[16,20]', '>20'])
    axes[i].tick_params(axis='x', labelsize='small')
fig.suptitle("Intake and Outcome Age Distribution of Animals")
fig.text(0.5, 0.02, 'Age Group (in years)', ha='center')
fig.delaxes(ax[1, 2])
plt.figlegend(['Intakes', 'Outcomes'], title="Legend", bbox_to_anchor=(0.85, 0.2), loc='lower right')
plt.show()
```

![Figure_8](https://github.com/airaperez/Portfolio-Projects/assets/110292677/56655836-b61a-4d09-9958-f01bbcbc99e6)


In the above graph, it can be seen that the distribution of intake age groups across animal types are fairly similar to the distribution of outcome age groups. This is with the exception of livestocks, where more animals less than a year old were taken into the shelter than released. The opposite pattern is seen in livestock aged 1 to 5 years old, where less is taken in as compared to those released. This may suggest that there is a number of livestock that remained in the shelter for at least a year before being released.

Further, for birds, dogs, and other animals, a majority are aged between 1 to 5 years. Cats, on the other hand, are more commonly taken in and out of the shelter as kittens less than a year old. This hints that there may be a high number of stray kittens roaming around Austin, Texas, emphasizing the need for a community animal spay and neuter project to control the cat population.



<!---     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -->
### Analyzing the Animals' Duration of Stay

#### Distribution of the animals' stay duration

```python
plt.hist(intakes['Stay_Duration'], color='sienna')
plt.xlabel("Duration of Stay (Days)")
plt.title("Distribution of the Animals' Stay Duration")
plt.show()
```

![Figure_9](https://github.com/airaperez/Portfolio-Projects/assets/110292677/b56c4432-9741-4c3d-9e48-c44711ac1f53)

Due to the presence of outliers, the distribution of the animals' duration of stay is sharply skewed to the right. To better visualize the distribution, I chose to filter out the animals that stayed for more than a year.

```python
plt.hist(intakes['Stay_Duration'][intakes['Stay_Duration'] <= 365], color='sienna')
plt.xlabel("Duration of Stay (Days)")
plt.title("Distribution of the Animals' Stay Duration (30 days and less)")
plt.show()
```

![Figure_10](https://github.com/airaperez/Portfolio-Projects/assets/110292677/401c74ef-11c5-4a47-8da3-eb8a11ccfd99)


From here, it can be seen that only a few animals stay in the shelter for more than a month. Additionally, it is rarer for animals to stay in the shelter for more than half a year, or approximately 180 days.


#### Distribution of duration of owner reclamation

```python
return_days = outcomes[outcomes['Outcome_Type'] == 'Return to Owner']
plt.hist(return_days['Stay_Duration'], color='sienna')
plt.xlabel("Days before owner reclamation")
plt.title("Distribution of Duration until Owner Reclamation")
plt.show()
```

![Figure_11](https://github.com/airaperez/Portfolio-Projects/assets/110292677/4fb81583-b4a1-469d-aec3-6e0443077b4f)

Similar to the distribution of stay duration, the distribution of the time before animals were returned to their owners is skewed to the right. Unlike the earlier plot, this is more sharply skewed, with not much values aside from the first bin. Thus, I decided to focus only on the animals that returned to their owners within a month.

```python
plt.hist(return_days['Stay_Duration'][return_days['Stay_Duration'] <= 30], color='sienna')
plt.xlabel("Days before owner reclamation")
plt.title("Distribution of Duration until Owner Reclamation (30 days and less)")
plt.show()
```

![Figure_12](https://github.com/airaperez/Portfolio-Projects/assets/110292677/24abf791-e17e-4031-b5b5-ee2ac4aaa302)

As depicted in the graph above, it is evident that animals with owners tend to stay in the shelter for a shorter amount of time. Majority take only about less than a week, or even less than a day before they are returned. It is less common for animals to take more than 2 weeks before being reclaimed by their owners.

#### Average stay duration of animals across the years

```python
avg_stay = sqldf(
"""
    SELECT
        DISTINCT SUBSTR(o.DateTime, 1, 4) AS Year,
        i.Animal_Type,
        AVG(i.Stay_Duration) AS Days_Duration
    FROM intakes AS i
    INNER JOIN outcomes AS o
    ON i.Animal_ID = o.Animal_ID AND
        i.Entry_Order = o.Exit_Order
    GROUP BY SUBSTR(o.DateTime, 1, 4), i.Animal_Type
    ORDER BY i.Animal_Type, Year;
""", globals())

stay_pivot = avg_stay.pivot(index='Year', columns='Animal_Type', values='Days_Duration').reset_index()
stay_pivot['Year'] = pd.to_numeric(stay_pivot['Year'])
stay_pivot.set_index('Year').plot(kind='line', color=['tab:cyan', 'tab:orange', 'tab:brown',
                                                      'tab:pink', 'darkslategray'])
plt.xticks(stay_pivot['Year'])
plt.title("Average Duration of Stay")
plt.xlabel("Year of Intake")
plt.ylabel("Duration of Stay (Days)")
plt.legend(title="Animal Type")
plt.show()
```

![Figure_13](https://github.com/airaperez/Portfolio-Projects/assets/110292677/df2db2f8-9394-4f12-949e-63497a440697)

Comparing the stay duration of each animal type across the years, it is apparent that livestock usually stays the longest in the shelter. Notably, animals taken in from 2019 to 2021 observed an increasing stay duration, peaking at 2021. Going back to the analysis of the distribution of age groups, it was found earlier that more livestock less than a year old were taken in the shelter than released. This confirms my earlier hypothesis that there are livestock that stayed in the shelter for more than a year.

The high values of the livestocks' average duration of stay compressed the plots of the rest of the animal groups. Thus, to better visualize the yearly trend of stay duration of the other animal types, a separate plot is created which excludes livestock.

```python
stay_pivot.set_index('Year').drop(columns=['Livestock']).plot(kind='line', color=['tab:cyan', 'tab:orange',
                                                                                  'tab:brown', 'darkslategray'])
plt.xticks(stay_pivot['Year'])
plt.title("Average Duration of Stay")
plt.xlabel("Year of Intake")
plt.ylabel("Duration of Stay (Days)")
plt.legend(title='Animal Type')
plt.show()
```

![Figure_14](https://github.com/airaperez/Portfolio-Projects/assets/110292677/501b05f2-1b1f-4534-9824-8228673d1689)

As observed in the plot above, on average, dogs and cats stay in the shelter longer than birds and other animals, with a yearly average stay duration of about 2 weeks to slightly more than a month. Conversely, birds and other animals usually stay for no more than 2 weeks. It is also interesting to note that birds' average stay duration increases and decreases every other year.


<!---     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -----     -->
### Analyzing the Animals' Intake Conditions

#### Distribution of intake conditions

Prior to analysis, the column `Intake_Condition` was cleaned, as it contained too many distinct values. In the following analyses, the conditions 'Aged', 'Feral', 'Normal', 'Nursing', 'Other', 'Pregnant', 'Unknown', and 'Space' were categorized as `Non-sick`, while the rest of the values were categorized as `Sick`.

```python
sick_animals = sqldf(
"""
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
""", globals())

sick_animals['Non_Sick'] = 100 - sick_animals['Sick_Percentage']
sick_animals = sick_animals.set_index('Animal_Type')

fig, ax = plt.subplots()
hbars = sick_animals.plot(kind='barh', stacked=True, color=['indianred', 'mediumseagreen'], ax=ax)
ax.set_xlabel("Percentage of Animals (%)")
ax.set_ylabel("")
ax.set_title("Breakdown of Intake Conditions per Type")
ax.legend(bbox_to_anchor=(0.5, 1.11), ncol=2, loc='center', labels=['Sick', 'Non-sick'])
for c in ax.containers:
    ax.bar_label(c, fmt='%.0f%%', label_type='center', color='white')
ax.set_xlim(right=100)
plt.show()
```

![Figure_15](https://github.com/airaperez/Portfolio-Projects/assets/110292677/1cee1f96-7c6f-4952-a257-b5472fc2021c)

From the above figure, it is observed that only a few percentage of intakes are sick animals. However, more than 25% of the birds and other animals taken in are found sick.

#### Yearly sick animal intakes

```python
yearly_sick = sqldf(
"""
    SELECT
        DISTINCT SUBSTR(DateTime, 1, 7) AS MonthYear,
        Animal_Type,
        COUNT(*) AS Sick_Count
    FROM intakes
    WHERE Intake_Condition NOT IN
        ('Aged', 'Feral', 'Normal', 'Nursing', 'Other', 'Pregnant', 'Unknown', 'Space')
    GROUP BY SUBSTR(DateTime, 1, 7), Animal_Type
    ORDER BY Animal_Type, MonthYear;
""", globals())

yearly_sick['MonthYear'] = pd.to_datetime(yearly_sick['MonthYear'], format='%Y-%m')
sick_pivot = yearly_sick.pivot(index='MonthYear', columns='Animal_Type', values='Sick_Count').fillna(0)

sick_pivot.plot(kind='line', color=['tab:cyan', 'tab:orange', 'tab:brown', 'tab:pink', 'darkslategray'])
plt.grid(axis='x', linestyle='--')
plt.title("Number of Sick Animal Intakes per Year")
plt.xlabel("Year")
plt.legend(title='Animal Type')
plt.show()
```

![Figure_16](https://github.com/airaperez/Portfolio-Projects/assets/110292677/513f03dd-8b69-48ea-90a4-048304f01da3)

Across all animal groups, except livestock, there is an evident trend in the number of sick animals taken to the shelter, increasing by the middle of the year and decreasing by the end. Notably, not much sick livestock were taken to the shelter throughout the years, with the exception of a few instances during 2020, 2022, and 2023.

#### Monthly sick animal intakes

```python
yearly_sick['Year'] = [date.year for date in yearly_sick['MonthYear']]
yearly_sick['Month'] = [date.month for date in yearly_sick['MonthYear']]
monthly_sick = yearly_sick.drop(columns=['MonthYear'])
monthly_sick_p = monthly_sick.pivot(index=['Year', 'Animal_Type'], columns='Month', values='Sick_Count')
monthly_sick_p = monthly_sick_p.reset_index('Animal_Type')
animals = sorted(monthly_sick_p['Animal_Type'].unique())

color = ['tab:cyan', 'tab:orange', 'tab:brown', 'tab:pink', 'darkslategray']

fig, ax = plt.subplots(2,3)
axes = ax.flatten()
for i, animal_type in enumerate(animals):
    month_pivot = monthly_sick_p[monthly_sick_p['Animal_Type']==animal_type].drop(columns='Animal_Type')
    month_pivot.plot.box(grid=False, ax=axes[i], legend=True, patch_artist=True,
                     color={'boxes':color[i], 'whiskers':'black',
                            'medians':'black', 'caps':'black'},
                     flierprops={'markerfacecolor':'dimgray', 'markeredgecolor':'white'})
    axes[i].grid(axis='x', linestyle='--')
    axes[i].set_title(f'{animal_type}s')
    axes[i].set_xticklabels(list(calendar.month_abbr)[1:13])
fig.suptitle("Distribution of Sick Animals per Month")
fig.text(0.08, 0.5, "Number of Sick Animals", va='center', rotation='vertical')
fig.delaxes(ax[1, 2])
fig.subplots_adjust(hspace=0.3)
plt.show()
```

![Figure_17](https://github.com/airaperez/Portfolio-Projects/assets/110292677/7b9018e4-17e7-4cc0-a845-d9de794a8274)

As illustrated above, the shelter commonly sees an increase in the intake of sick birds, cats, and dogs around May and June. Thus, it is recommended that the shelter conducts necessary preparations prior to these months, stocking up on medical supplies. However, it is also important to note that during March, a spike in the intake of other animal types are often seen, which emphasizes the importance of preparing earlier in the year. Lastly, the graph shows that there have only been exactly 3 sick livestock that were taken to the shelter.

#### Outcomes of sick animals

```python
sick_outcome = sqldf(
"""
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
""", globals())

total_sick = sick_outcome['Outcome_Counts'].sum()

fig, ax = plt.subplots()
ax.barh(sick_outcome['Outcome_Type'], sick_outcome['Outcome_Counts'],
                align='center', color='indianred')
ax.invert_yaxis()
ax.set_title("Outcomes of Sick Animals")
ax.set_xlabel("Count")
ax.set_xlim(right=7000)
for c in ax.containers:
    ax.bar_label(c, labels=[f' {x:,.0f} ({round((x/total_sick)*100,2)}%)' for x in c.datavalues])
plt.show()
```

![Figure_18](https://github.com/airaperez/Portfolio-Projects/assets/110292677/9c677a70-cc61-4c31-8ebf-ee87a067a50d)

The plot above shows that the three most common outcomes for sick animals taken to the shelter are being transferred, subjected to euthanasia, or being adopted. As noted earlier in the analysis of the distribution of outcomes, though only less animals were taken in for a euthanasia request, a relatively higher proportion ultimately underwent the said procedure. Through the graph above, it becomes evident that euthanasia has been a common outcome of sick animals, hence the increase in the proportion of euthanasia outcomes.

Lastly, it is also of note that only a small percentage of sick animals died due to other causes apart from euthanasia. This is indicative of the shelter's efforts and commitment to caring for the animals and minimizing mortality rates as much as possible, staying true to its title of being the largest no-kill animal shelter in the US.
