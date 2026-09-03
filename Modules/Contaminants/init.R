source(".Rprofile", local = TRUE)

# Libraries ---------------------------------------------------------------
library(DBI)
library(magrittr)
library(dplyr)
library(pool)
library(MetabolomiQCsR)

setwd("Modules/Contaminants")


# DB connect --------------------------------------------------------------
pool <- dbPool_MetabolomiQCs(30)



# Get database and contruct query -----------------------------------------

conts <- get_cont_list(c("positive","negative"))

conts[[1]] %<>% mutate(mode = "pos")
conts[[2]] %<>% mutate(mode = "neg")

conts <- bind_rows(conts[[1]], conts[[2]])

conts_formatted <- conts %>%
            mutate(anno = paste0(molecular_formula," (",ion_type ,")")) %>%
            select(name = compound_ID,
                 ion_id = ion_ID,
                 mode = mode,
                 mz = mz,
                 anno = anno,
                 notes = origin
                 ) %>%
            mutate(across(where(is.character), ~gsub(";","\\\\;", .x)))


# Send command to the DB --------------------------------------------------
# init.R only runs on a freshly-dropped+created table, so no duplicates exist;
# ON DUPLICATE KEY UPDATE is unnecessary and VALUES() was removed in recent MariaDB.
con <- poolCheckout(pool)
on.exit({ try(dbRollback(con), silent = TRUE); poolReturn(con) }, add = TRUE)
dbBegin(con)
sql <- sqlAppendTable(con, "cont_cmp", conts_formatted)
dbExecute(con, sql)
dbCommit(con)

poolClose(pool)
