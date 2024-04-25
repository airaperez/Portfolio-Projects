# =========================================================================================
#  PRELIMINARIES
# =========================================================================================

# Importing packages
import numpy as np
import pandas as pd
import matplotlib as mt
import matplotlib.pyplot as plt
import matplotlib.cm as cm
from pandasql import sqldf
import calendar
mt.use('TkAgg')

# Importing the data
intakes = pd.read_csv("Intakes_Clean.csv")
outcomes = pd.read_csv("Outcomes_Clean.csv")

# Checking the data
print(intakes.head(10))
print(outcomes.head(10))


# =========================================================================================
#  EXPLORATORY DATA ANALYSIS
# =========================================================================================

### Overall ### ---------------------------------------------------------------------------

## Trend of intakes and outcomes each year
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


# Monthly Trend of Intakes
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


# Monthly Trend of Outcomes
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



### Animal Type ### -----------------------------------------------------------------------

## Total number of animals handled by the shelter per animal type, excluding duplicates
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


## Percentage of the different intake types relative to each animal type
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


## Percentage of the different outcome types relative to each animal type
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



### Age of Animal ### ---------------------------------------------------------------------

## Distribution of age groups upon intake per animal type
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



### Duration of Stay ### ------------------------------------------------------------------

## Distribution of the stay duration of animals
# Overall
plt.hist(intakes['Stay_Duration'], color='sienna')
plt.xlabel("Duration of Stay (Days)")
plt.title("Distribution of the Animals' Stay Duration")
plt.ylim(top=500)
plt.show()

# Stayed for at most a year
plt.hist(intakes['Stay_Duration'][intakes['Stay_Duration'] <= 365], color='sienna')
plt.xlabel("Duration of Stay (Days)")
plt.title("Distribution of the Animals' Stay Duration (Stayed less than a year)")
plt.show()


## Distribution of the time before animals were returned to their owners
# Overall
return_days = outcomes[outcomes['Outcome_Type'] == 'Return to Owner']
plt.hist(return_days['Stay_Duration'], color='sienna')
plt.xlabel("Days before owner reclamation")
plt.title("Distribution of Duration until Owner Reclamation")
plt.show()

# Returned within a month
plt.hist(return_days['Stay_Duration'][return_days['Stay_Duration'] <= 30], color='sienna')
plt.xlabel("Days before owner reclamation")
plt.title("Distribution of Duration until Owner Reclamation (30 days and less)")
plt.show()


## Average duration of animals' stay in the shelter per year
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

# All animals
stay_pivot.set_index('Year').plot(kind='line', color=['tab:cyan', 'tab:orange', 'tab:brown',
                                                      'tab:pink', 'darkslategray'])
plt.xticks(stay_pivot['Year'])
plt.title("Average Duration of Stay")
plt.xlabel("Year of Intake")
plt.ylabel("Duration of Stay (Days)")
plt.legend(title="Animal Type")
plt.show()

# All except livestock
stay_pivot.set_index('Year').drop(columns=['Livestock']).plot(kind='line', color=['tab:cyan', 'tab:orange',
                                                                                  'tab:brown', 'darkslategray'])
plt.xticks(stay_pivot['Year'])
plt.title("Average Duration of Stay")
plt.xlabel("Year of Intake")
plt.ylabel("Duration of Stay (Days)")
plt.legend(title='Animal Type')
plt.show()



### Condition of Animal ### ---------------------------------------------------------------

## Which animal is commonly brought to the shelter as sick?
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
ax.set_xticks([0,25,50,75,100])
plt.show()


## Trend of the number of intakes for sick animals across the years
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
plt.title("Yearly Sick Animal Intakes")
plt.xlabel("Year")
plt.ylabel("Number of Sick Animals")
plt.legend(title='Animal Type')
plt.show()


## Monthly Trend of intakes for sick animals across the years
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


## Common outcomes observed for sick animals
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