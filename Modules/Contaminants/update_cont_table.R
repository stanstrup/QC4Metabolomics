source(".Rprofile", local = TRUE)
print(.libPaths())

# Libraries ---------------------------------------------------------------
library(DBI)
library(magrittr)
library(dplyr)
library(pool)

setwd("../")
library(MetabolomiQCsR)
setwd("Contaminants")

source("get_settings.R", local = TRUE)



# DB connect --------------------------------------------------------------
pool <- dbPool_MetabolomiQCs(30)



# Get database and contruct query -----------------------------------------

conts <- get_cont_list(c("positive","negative"))

conts[[1]] %<>% mutate(mode = "pos")
conts[[2]] %<>% mutate(mode = "neg") %>% mutate( `Ion ID` =  -`Ion ID`)

conts <- bind_rows(conts[[1]], conts[[2]])

conts %>%   mutate(anno = paste0(`Formula for M or subunit or sequence`," (",`Ion type`,")")) %>% 
            select(name = `Compound ID or species`, 
                 ion_id = `Ion ID`, 
                 mode = mode, 
                 mz = `Monoisotopic ion mass (singly charged)`, 
                 anno = anno,
                 notes = `Possible origin and other comments`
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
