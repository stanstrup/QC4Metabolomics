# Libraries ---------------------------------------------------------------
# Suppress masking/attaching noise; real errors still propagate.
.quiet_load <- function(expr) {
    withCallingHandlers(
        suppressPackageStartupMessages(expr),
        message = function(m) {
            if (grepl("masked from|Attaching package|Loading required package|Welcome to Bioconductor|Visit https|Consider switching|This is.*version",
                      conditionMessage(m), perl = TRUE))
                invokeRestart("muffleMessage")
        },
        warning = function(w) {
            if (grepl("replacing previous import", conditionMessage(w)))
                invokeRestart("muffleWarning")
        }
    )
}

.quiet_load({
    # library(stringr)
    library(xcms)
    library(DBI)
    # library(RMySQL)
    library(pool)
    library(magrittr)
    library(purrr)
    library(tidyr)
    library(dplyr)
    library(MSnbase)
    library(Spectra)
    library(MetabolomiQCsR)
})
setwd("Modules/Contaminants")

source("process_files.R", local = TRUE)
