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
