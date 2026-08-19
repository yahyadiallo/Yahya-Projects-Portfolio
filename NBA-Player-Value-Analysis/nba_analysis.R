library(tidyverse)
library(scales)


# DATA CLEANING -----------------------------------------------------------

# Import NBA player statistics and salary data
nba <- read_csv("nba-all-stats.csv") %>%
  select(-`...1`) %>%
  mutate(
    position_group = case_when(
      Position %in% c("PG", "SG", "PG-SG", "SG-PG") ~ "Guard",
      Position %in% c("SF", "PF", "SF-PF", "SF-SG") ~ "Forward",
      Position == "C" ~ "Center",
      TRUE ~ NA_character_
    )
  )


# DATA VALIDATION ---------------------------------------------------------

# Check number of players in each position group
table(nba$position_group)

# Check for positions that were not successfully grouped
nba %>%
  filter(is.na(position_group)) %>%
  distinct(Position)

# Check missing values
colSums(is.na(nba))

# Review dataset structure
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


# Visualize salary distribution
ggplot(nba, aes(x = Salary)) +
  geom_histogram(
    bins = 30,
    fill = "navy",
    color = "white"
  ) +
  scale_x_continuous(
    labels = label_dollar(
      scale = 1e-6,
      suffix = "M"
    )
  ) +
  labs(
    title = "Distribution of NBA Player Salaries",
    subtitle = "Most players earn substantially less than the league's highest-paid players",
    x = "Salary",
    y = "Number of Players"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )


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


# Create a ranked table of performance correlations with salary
salary_corr_df <- tibble(
  metric = names(salary_correlations[, "Salary"]),
  correlation = salary_correlations[, "Salary"]
) %>%
  filter(metric != "Salary") %>%
  arrange(desc(correlation))


# Visualize performance metrics most associated with salary
ggplot(
  salary_corr_df,
  aes(
    x = reorder(metric, correlation),
    y = correlation,
    fill = metric == "PTS"
  )
) +
  geom_col() +
  geom_text(
    aes(label = round(correlation, 2)),
    hjust = -0.2,
    size = 4
  ) +
  scale_fill_manual(
    values = c(
      "TRUE" = "red",
      "FALSE" = "navy"
    ),
    guide = "none"
  ) +
  scale_y_continuous(
    limits = c(0, 0.8)
  ) +
  coord_flip() +
  labs(
    title = "NBA Performance Metrics Most Associated with Salary",
    subtitle = "Points per game shows the strongest positive correlation with player salary",
    x = "Performance Metric",
    y = "Correlation with Salary"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )


# Compare salary distributions across position groups
ggplot(
  nba,
  aes(
    x = position_group,
    y = Salary,
    fill = position_group
  )
) +
  geom_boxplot(alpha = 0.8) +
  scale_fill_manual(
    values = c(
      "Center" = "red",
      "Forward" = "navy",
      "Guard" = "gray"
    )
  ) +
  scale_y_continuous(
    labels = label_dollar(
      scale = 1e-6,
      suffix = "M"
    )
  ) +
  labs(
    title = "NBA Salary Distribution by Position Group",
    x = "Position Group",
    y = "Salary"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )


# Summarize salary by position group
position_salary_summary <- nba %>%
  group_by(position_group) %>%
  summarise(
    players = n(),
    avg_salary = mean(Salary),
    median_salary = median(Salary),
    min_salary = min(Salary),
    max_salary = max(Salary),
    .groups = "drop"
  )

position_salary_summary


# Compare scoring and salary relationship by position
ggplot(
  nba,
  aes(
    x = PTS,
    y = Salary,
    color = position_group
  )
) +
  geom_point(
    alpha = 0.65,
    size = 2
  ) +
  geom_smooth(
    method = "lm",
    se = FALSE,
    linewidth = 1
  ) +
  scale_color_manual(
    values = c(
      "Center" = "red",
      "Forward" = "navy",
      "Guard" = "gray"
    )
  ) +
  scale_y_continuous(
    labels = label_dollar(
      scale = 1e-6,
      suffix = "M"
    )
  ) +
  labs(
    title = "Scoring and Salary Relationship by Position",
    subtitle = "Linear trends compare how points per game relate to salary across position groups",
    x = "Points Per Game",
    y = "Salary",
    color = "Position Group"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )


# Calculate scoring and salary correlation by position
position_correlations <- nba %>%
  group_by(position_group) %>%
  summarise(
    pts_salary_correlation = cor(PTS, Salary),
    .groups = "drop"
  )

position_correlations


# PLAYER VALUE MODEL ------------------------------------------------------

# Create modeling dataset and require at least 500 total minutes
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
    position_group,
    GP,
    `Total Minutes`
  ) %>%
  filter(`Total Minutes` >= 500)


# Check correlations between potential predictors
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


# Build log-salary regression model
salary_model <- lm(
  log(Salary) ~ Age + PTS + AST + TRB + BPM + VORP + position_group,
  data = model_data
)

summary(salary_model)


# Calculate Duan's smearing factor for bias-corrected dollar predictions
smearing_factor <- mean(
  exp(residuals(salary_model))
)

smearing_factor


# Add predictions, residuals, and salary-value measures
model_results <- model_data %>%
  mutate(
    predicted_log_salary = predict(salary_model),
    log_residual = residuals(salary_model),
    
    # Convert log predictions back to dollars with smearing correction
    predicted_salary = exp(predicted_log_salary) * smearing_factor,
    
    # Compare actual salary with model-predicted salary
    salary_ratio = Salary / predicted_salary,
    salary_pct_of_prediction = salary_ratio * 100
  )


# MODEL VALIDATION --------------------------------------------------------

# Check residual pattern
ggplot(
  model_results,
  aes(
    x = predicted_log_salary,
    y = log_residual
  )
) +
  geom_point(
    alpha = 0.65,
    color = "navy"
  ) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed",
    color = "red",
    linewidth = 0.8
  ) +
  labs(
    title = "Residuals vs. Predicted Log Salary",
    subtitle = "Players with at least 500 total minutes",
    x = "Predicted Log Salary",
    y = "Residual"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )


# PLAYER VALUE RANKINGS ---------------------------------------------------

# Rank players by salary relative to model expectations
top_value_players <- model_results %>%
  arrange(salary_ratio) %>%
  slice_head(n = 10)


# View top salary-value players
top_value_players %>%
  select(
    `Player Name`,
    Salary,
    predicted_salary,
    salary_pct_of_prediction,
    PTS,
    VORP,
    GP,
    `Total Minutes`,
    position_group
  )


# Visualize top salary-value players
ggplot(
  top_value_players,
  aes(
    x = salary_pct_of_prediction,
    y = reorder(
      `Player Name`,
      -salary_pct_of_prediction
    ),
    fill = `Player Name` == "Kris Dunn"
  )
) +
  geom_col() +
  geom_text(
    aes(
      label = paste0(
        round(salary_pct_of_prediction, 1),
        "%"
      )
    ),
    hjust = -0.2,
    size = 4
  ) +
  scale_fill_manual(
    values = c(
      "TRUE" = "red",
      "FALSE" = "navy"
    ),
    guide = "none"
  ) +
  scale_x_continuous(
    labels = function(x) paste0(round(x), "%"),
    expand = expansion(
      mult = c(0, 0.1)
    )
  ) +
  labs(
    title = "NBA Players Providing the Most Salary Value",
    subtitle = "Comparing actual and predicted salaries for players with 500+ minutes played",
    x = "Actual Salary as % of Predicted Salary",
    y = NULL
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

