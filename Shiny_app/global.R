# Libraries ---------------------------------------------------------------
library(shiny)
library(shinyjs)
library(pool)
library(DBI)
library(RMySQL)
library(MetabolomiQCsR)
library(DT)
library(plyr)
library(dplyr)
library(magrittr)
library(tidyr)
library(tibble)
library(plotly)
library(ggthemes)


# Establish connection ----------------------------------------------------
pool <- dbPool_MetabolomiQCs(120)
