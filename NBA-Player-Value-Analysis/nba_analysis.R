library(tidyverse)
library(scales)

nba <- read_csv("nba-all-stats.csv") %>%
  mutate(
    position_group = case_when(
      Position %in% c("PG", "SG", "PG-SG", "SG-PG") ~ "Guard",
      Position %in% c("SF", "PF", "SF-PF", "SF-SG") ~ "Forward",
      Position == "C" ~ "Center",
      TRUE ~ NA_character_
    )
  )
