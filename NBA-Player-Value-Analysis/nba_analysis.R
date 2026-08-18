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
