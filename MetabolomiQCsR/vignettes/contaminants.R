## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, fig.align = "center", dev='svg')

## ----contaminant list----------------------------------------------------
library(MetabolomiQCsR)

get_cont_list(polarity = c("positive", "negative", "unknown"))

