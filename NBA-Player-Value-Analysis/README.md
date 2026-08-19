# NBA Player Value Analysis

An R-based analysis of NBA player salaries and performance during the 2022–23 season. This project explores which performance metrics are most associated with player salaries and uses a regression model to identify players whose actual salaries were significantly below their model-predicted salaries.

## Project Overview

NBA player salaries vary significantly, but how closely does compensation reflect on-court performance?

This project analyzes player salary, traditional statistics, and advanced performance metrics to answer four main questions:

1. How are NBA player salaries distributed?
2. Which performance metrics are most strongly associated with salary?
3. Does the relationship between scoring and salary differ across position groups?
4. Which players were paid significantly less than their performance-based model predictions?

The analysis progresses from exploratory data analysis into a regression-based player value model.

## Dataset

The analysis uses the **NBA Player Salaries (2022–23 Season)** dataset created by Jamie Welsh and available on Kaggle.

The dataset combines:

- NBA player salary information
- Player demographics and positions
- Per-game statistics such as points, assists, and rebounds
- Advanced metrics including PER, Win Shares, BPM, and VORP

According to the dataset documentation, salary information was collected from HoopsHype while traditional and advanced player statistics were obtained from Basketball Reference.

**Dataset:** [NBA Player Salaries (2022–23 Season) – Kaggle](https://www.kaggle.com/datasets/jamiewelsh2/nba-player-salaries-2022-23-season)

## Tools & Technologies

- R
- tidyverse
- dplyr
- ggplot2
- scales
- Linear Regression
- Exploratory Data Analysis
- Data Visualization

## Data Preparation

Before analysis, the dataset was cleaned and prepared in R.

Player positions were simplified into three broader groups:

- Guard
- Forward
- Center

The data was also checked for missing values and unclassified positions before beginning the analysis.

For the salary prediction model, players were required to have played at least **500 total minutes**. This reduces the influence of players with very limited playing time whose per-game statistics may not represent a meaningful season-long performance sample.

## Exploratory Analysis

### NBA Salary Distribution

<img width="1230" height="874" alt="Salary-Distribution" src="https://github.com/user-attachments/assets/b6442319-9693-4bed-b2cb-4ca1d578cf91" />

NBA salaries are strongly right-skewed. Most players earn salaries toward the lower end of the league's salary range, while a relatively small number of players earn salaries above $30–40 million.

This distribution also motivated the use of a log transformation when modeling salary.

### Performance Metrics Associated with Salary

<img width="1230" height="874" alt="Salary-Correlations" src="https://github.com/user-attachments/assets/1212e9c6-ecfd-41d3-a636-a261ca659eb7" />

Points per game had the strongest positive correlation with salary at approximately **0.73**.

Other strong relationships included:

- VORP: 0.68
- Win Shares: 0.62
- Assists: 0.59
- Rebounds: 0.50

The results suggest that scoring production has the strongest individual linear association with salary among the performance variables examined, although salary is related to several areas of player performance.

Correlation does not necessarily indicate that a metric directly causes a higher salary.

### Scoring and Salary by Position

<img width="1230" height="874" alt="Scoring-Salary-Relationship" src="https://github.com/user-attachments/assets/f6a0dbb7-bc92-48fd-814b-5e4711dac03b" />

Because points per game showed the strongest correlation with salary, the relationship was examined further across guards, forwards, and centers.

All three position groups show a positive relationship between scoring and salary. Higher-scoring players generally earn more, although significant variation remains among players with similar scoring averages.

This indicates that scoring alone cannot fully explain differences in player compensation.

## Player Salary Model

A multiple linear regression model was developed to estimate player salary using several player characteristics and performance measures.

The model predicts **log salary** using:

- Age
- Points per game (PTS)
- Assists per game (AST)
- Rebounds per game (TRB)
- Box Plus/Minus (BPM)
- Value Over Replacement Player (VORP)
- Position group

The model can be represented conceptually as:

`log(Salary) ~ Age + PTS + AST + TRB + BPM + VORP + Position`

Log salary was modeled instead of raw salary because the salary distribution is highly skewed.

Predictions were converted back into dollar values using an adjustment based on the model's residuals to improve accuracy after the log transformation.

Model residuals were also examined to evaluate how prediction errors behaved across predicted salary levels.

## Identifying Salary Value

After generating predicted salaries, each players actual salary was compared with the salary estimated by the model.

The primary value measure was:

`Actual Salary / Predicted Salary × 100`

A lower percentage indicates that a players actual salary was significantly below the model's prediction.

### Players Providing the Most Salary Value

<img width="1700" height="900" alt="Top-Value-Players" src="https://github.com/user-attachments/assets/2ba502ac-ca52-4707-bcee-ff87fe1d20eb" />

Among players with at least 500 minutes played, Kris Dunn had the lowest actual salary relative to the model prediction.

His actual salary was approximately **8.5% of his predicted salary**.

Other players whose actual salaries were significantly below their model predictions included Desmond Bane, Anthony Lamb, Tre Jones, Austin Reaves, and others.

These results should be interpreted as **model-based estimates of salary value**, rather than definitive measures of whether a player was underpaid.

## Key Findings

- NBA salaries were heavily right-skewed, with most players earning significantly less than the league's highest-paid players.
- Points per game had the strongest positive correlation with salary among the performance metrics examined (`r ≈ 0.73`).
- VORP and Win Shares were also strongly associated with salary.
- Scoring showed a positive relationship with salary across guards, forwards, and centers.
- A regression model combining age, position, traditional statistics, and advanced metrics was used to estimate expected player salaries.
- Several players had actual salaries well below the model’s predictions, highlighting players who may have delivered strong performance for their level of compensation.

## Limitations

The model estimates salary based only on the variables available in the dataset and should not be interpreted as a complete measure of a players market value.

NBA salaries are also influenced by factors not captured by the model, including:

- Rookie scale contracts
- Contract timing
- Free agency and market conditions
- Salary cap rules
- Injuries
- Previous season performance
- Contract length
- Team strategy and roster needs

This analysis compares players actual salaries with what the model predicts based on their performance and characteristics. The results are intended to highlight potential salary value, not to label players as overpaid or underpaid.

## Repository Structure

    nba-player-value-analysis-r/
    │
    ├── nba-all-stats.csv
    ├── nba-player-value-analysis.R
    ├── README.md
    │
    └── visuals/
        ├── Salary-Distribution.png
        ├── Salary-Correlations.png
        ├── Salary-by-Position.png
        ├── Scoring-Salary-Relationship.png
        ├── Model-Residuals.png
        └── Top-Value-Players.png

## Author

**Yahya Diallo**

Data Visualization | Data Analytics | Data Science
