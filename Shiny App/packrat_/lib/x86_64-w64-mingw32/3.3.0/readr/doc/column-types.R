## ---- include = FALSE----------------------------------------------------
library(readr)
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")

## ------------------------------------------------------------------------
data <- read_csv(readr_example("mtcars.csv"))
data

# Every table returned has a spec attribute
s <- spec(data)
s

# Alternatively you can use a spec function instead, which will only read the
# first 1000 rows (user configurable with guess_max)
s <- spec_csv(readr_example("mtcars.csv"))
s

# Automatically set the default to the most common type
cols_condense(s)

# If the spec has a default of skip then uses cols_only
s$default <- col_skip()
s

# Otherwise set the default to the proper type
s$default <- col_character()
s

# The print method takes a n parameter to return only that number of columns
print(s, n = 5)

# When reading this is set to 20 by default, set 
# options("readr.num_columns" = x) to change
options("readr.num_columns" = 5)
data <- read_csv(readr_example("mtcars.csv"))

# Setting it to 0 disables printing
options("readr.num_columns" = 0)
data <- read_csv(readr_example("mtcars.csv"))

## ------------------------------------------------------------------------
parse_number(c("0%", "10%", "150%"))
parse_number(c("$1,234.5", "$12.45"))

## ------------------------------------------------------------------------
guess_parser("$1,234")
guess_parser("1,234")

## ------------------------------------------------------------------------
parse_datetime("2010-10-01 21:45")
parse_date("2010-10-01")

## ------------------------------------------------------------------------
parse_datetime("1 January, 2010", "%d %B, %Y")
parse_datetime("02/02/15", "%m/%d/%y")

## ------------------------------------------------------------------------
parse_factor(c("a", "b", "a"), levels = c("a", "b", "c"))

