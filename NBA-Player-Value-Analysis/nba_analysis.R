library(tidyverse)
library(scales)


# DATA CLEANING -----------------------------------------------------------

# Import NBA player statistics and salary data
nba <- read_csv("nba-all-stats.csv") %>%
  select(-`...1`) %>%
  
  # Simplify player positions into three main groups
  mutate(
    position_group = case_when(
      Position %in% c("PG", "SG", "PG-SG", "SG-PG") ~ "Guard",
      Position %in% c("SF", "PF", "SF-PF", "SF-SG") ~ "Forward",
      Position == "C" ~ "Center",
      TRUE ~ NA_character_
    )
  )


# DATA VALIDATION ---------------------------------------------------------

# Check the number of players in each position group
table(nba$position_group)

# Check for any positions that were not grouped
nba %>%
  filter(is.na(position_group)) %>%
  distinct(Position)

# Check for missing values in each column
colSums(is.na(nba))

# View the structure of the dataset
glimpse(nba)


# EXPLORATORY DATA ANALYSIS -----------------------------------------------

# Summarize key salary and performance variables
nba %>%
  summarise(
    players = n(),
    avg_salary = dollar(mean(Salary)),
    median_salary = dollar(median(Salary)),
    avg_points = round(mean(PTS), 2),
    avg_assists = round(mean(AST), 2),
    avg_rebounds = round(mean(TRB), 2),
    avg_per = round(mean(PER), 2),
    avg_vorp = round(mean(VORP), 2)
  )

# Visualize the distribution of NBA player salaries
ggplot(nba, aes(x = Salary)) +
  geom_histogram(bins = 30, color = "white") +
  scale_x_continuous(
    labels = label_dollar(scale = 1e-6, suffix = "M")
  ) +
  labs(
    title = "Distribution of NBA Player Salaries",
    subtitle = "Most players earn substantially less than the league's highest-paid players",
    x = "Salary",
    y = "Number of Players"
  ) +
  theme_minimal()

# Measure correlations between player performance and salary
salary_correlations <- nba %>%
  select(
    Salary,
    PTS,
    AST,
    TRB,
    STL,
    BLK,
    PER,
    `TS%`,
    WS,
    `WS/48`,
    BPM,
    VORP
  ) %>%
  cor(use = "complete.obs")

salary_correlations

# Extract and rank correlations with salary
salary_correlations[, "Salary"] %>%
  sort(decreasing = TRUE)

# Create a table of performance correlations with salary
salary_corr_df <- tibble(
  metric = names(salary_correlations[, "Salary"]),
  correlation = salary_correlations[, "Salary"]
) %>%
  filter(metric != "Salary") %>%
  arrange(desc(correlation))

salary_corr_df

# Visualize which performance metrics are most associated with salary
ggplot(salary_corr_df, aes(
  x = reorder(metric, correlation),
  y = correlation
)) +
  geom_col() +
  geom_text(
    aes(label = round(correlation, 2)),
    hjust = -0.2,
    size = 4
  ) +
  scale_y_continuous(limits = c(0, 0.8)) +
  coord_flip() +
  labs(
    title = "NBA Performance Metrics Most Associated with Salary",
    subtitle = "Points per game shows the strongest positive correlation with player salary",
    x = "Performance Metric",
    y = "Correlation with Salary"
  ) +
  theme_minimal()

# Compare salary distributions across position groups
ggplot(nba, aes(
  x = position_group,
  y = Salary
)) +
  geom_boxplot() +
  scale_y_continuous(
    labels = label_dollar(scale = 1e-6, suffix = "M")
  ) +
  labs(
    title = "NBA Salary Distribution by Position Group",
    x = "Position Group",
    y = "Salary"
  ) +
  theme_minimal()

# Summarize salary by position group
position_salary_summary <- nba %>%
  group_by(position_group) %>%
  summarise(
    players = n(),
    avg_salary = mean(Salary),
    median_salary = median(Salary),
    min_salary = min(Salary),
    max_salary = max(Salary)
  )

position_salary_summary

# Compare the relationship between scoring and salary by position
ggplot(nba, aes(
  x = PTS,
  y = Salary,
  color = position_group
)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_smooth(
    method = "lm",
    se = FALSE
  ) +
  scale_y_continuous(
    labels = label_dollar(scale = 1e-6, suffix = "M")
  ) +
  labs(
    title = "Scoring and Salary Relationship by Position",
    subtitle = "Linear trends compare how points per game relate to salary across position groups",
    x = "Points Per Game",
    y = "Salary",
    color = "Position Group"
  ) +
  theme_minimal()

# Calculate scoring and salary correlation by position group
position_correlations <- nba %>%
  group_by(position_group) %>%
  summarise(
    pts_salary_correlation = cor(PTS, Salary)
  )

position_correlations

# PLAYER VALUE MODEL ------------------------------------------------------

# Select variables for salary modeling
model_data <- nba %>%
  select(
    `Player Name`,
    Salary,
    Age,
    PTS,
    AST,
    TRB,
    PER,
    WS,
    BPM,
    VORP,
    position_group
  )

glimpse(model_data)

# Check correlations between potential model predictors
predictor_correlations <- model_data %>%
  select(
    Age,
    PTS,
    AST,
    TRB,
    PER,
    WS,
    BPM,
    VORP
  ) %>%
  cor()

round(predictor_correlations, 2)

# Build a multiple linear regression model to estimate salary
salary_model <- lm(
  Salary ~ Age + PTS + AST + TRB + BPM + VORP + position_group,
  data = model_data
)

summary(salary_model)

# Add predicted salaries and residuals to the modeling data
model_results <- model_data %>%
  mutate(
    predicted_salary = predict(salary_model),
    residual = Salary - predicted_salary
  )

glimpse(model_results)

# Compare actual salaries with model-predicted salaries
ggplot(model_results, aes(
  x = predicted_salary,
  y = Salary
)) +
  geom_point(alpha = 0.6) +
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = "dashed"
  ) +
  scale_x_continuous(
    labels = label_dollar(scale = 1e-6, suffix = "M")
  ) +
  scale_y_continuous(
    labels = label_dollar(scale = 1e-6, suffix = "M")
  ) +
  labs(
    title = "Actual vs. Predicted NBA Player Salaries",
    subtitle = "Predictions are based on age, performance metrics, and position",
    x = "Predicted Salary",
    y = "Actual Salary"
  ) +
  theme_minimal()

# Find players earning the most below their model-predicted salary
model_results %>%
  arrange(residual) %>%
  select(
    `Player Name`,
    Salary,
    predicted_salary,
    residual,
    PTS,
    VORP,
    position_group
  ) %>%
  slice_head(n = 10)

# Inspect playing time for players with the largest negative residuals
model_results %>%
  arrange(residual) %>%
  slice_head(n = 10) %>%
  left_join(
    nba %>%
      select(`Player Name`, GP, `Total Minutes`),
    by = "Player Name"
  ) %>%
  select(
    `Player Name`,
    Salary,
    predicted_salary,
    residual,
    GP,
    `Total Minutes`,
    PTS,
    VORP,
    Age
  )

# Remove players with limited playing time from the value analysis
eligible_players <- model_results %>%
  left_join(
    nba %>%
      select(`Player Name`, GP, `Total Minutes`),
    by = "Player Name"
  ) %>%
  filter(`Total Minutes` >= 500)

nrow(eligible_players)