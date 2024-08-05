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

conts %>%   mutate(anno = paste0(molecular_formula," (",ion_type ,")")) %>% 
            select(name = compound_ID, 
                 ion_id = ion_ID, 
                 mode = mode, 
                 mz = mz, 
                 anno = anno,
                 notes = origin
                 ) %>% 
            mutate_all(~gsub(";","\\\\;",.)) %>%
            sqlAppendTable(pool,"cont_cmp",.) ->
sql_query


sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE name = values(name), mode = values(mode), mz = values(mz), anno = values(anno), notes = values(notes)")



# Send command to the DB --------------------------------------------------
con <- poolCheckout(pool)
dbBegin(con)
q_res <- sql_query %>% dbSendQuery(con, .)
res <- dbCommit(con)

# Close connection
poolReturn(con)
poolClose(pool)
