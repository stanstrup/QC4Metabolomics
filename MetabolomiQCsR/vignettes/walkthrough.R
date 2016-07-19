## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)

## ----libraries, message=FALSE--------------------------------------------
library(MetabolomiQCsR)
library(dplyr)
library(faahKO)

## ----xcmsRaw_to_tbl------------------------------------------------------
files <- file.path(find.package("faahKO"), "cdf/KO") %>% 
         list.files(full.names=TRUE)
 
files %>% xcmsRaw_to_tbl

