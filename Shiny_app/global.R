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


# Establish connection ----------------------------------------------------
pool <- dbPool_MetabolomiQCs(120)
