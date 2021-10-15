## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, fig.align = "center", dev='svg')

## ----default configuration----------------------------------------------------
writeLines(readLines(system.file("extdata", "MetabolomiQCsR.conf", package = "MetabolomiQCsR")))

## ----config environment-------------------------------------------------------
library(MetabolomiQCsR)

MetabolomiQCsR.env

MetabolomiQCsR.env$target_cont

## ----changing the configuration-----------------------------------------------
MetabolomiQCsR.env$target_cont$EIC_ppm <- 10

MetabolomiQCsR.env$target_cont

