# Libraries ---------------------------------------------------------------
library(DBI)
library(RMySQL)
library(MetabolomiQCsR)
library(pool) # devtools::install_github("rstudio/pool")
library(magrittr)
library(rlist)
library(ini)
library(dplyr)
library(tidyr)
library(purrr)


# Get settings ------------------------------------------------------------

ini <- MetabolomiQCsR.env$general$settings_file %>% read.ini


# List modules with database tables
module_table  <- ini %>% 
                 list.match("module_.*") %>% 
                 list.stack(fill = TRUE, idcol="module") %>% 
                 as.tbl %>% 
                 transmute(enabled = as.logical(enabled), 
                           init_db_priority = as.integer(init_db_priority), 
                           module = module %>% gsub("module_", "", .) %>% as.character
                           ) %>% 
                 filter(enabled, !is.na(init_db_priority))
                

# Add create/drop/create factor
module_table %<>% cbind(tibble(sql_fun = list(factor(c("drop","create","check"),c("drop","create","check"))))) %>% 
                  as.tbl %>% 
                  unnest(sql_fun)


# Find files and check if they exist
module_table %<>% rowwise %>% 
                  mutate(script_path = paste0("Modules/",module,"/",switch(as.character(sql_fun), drop = "init_db_drop.sql", create = "init_db_create.sql", check =  "init_db_check.sql"))) %>% 
                  ungroup %>% 
                  mutate(file_exists = file.exists(script_path)) %>% 
                  filter(file_exists) %>%
                  rowwise %>% 
                  mutate(sql =   readLines(script_path) %>% 
                                 paste(collapse="\n ") %>% 
                                 gsub("\\;","--SEMICOLON--",., fixed=TRUE) %>%
                                 strsplit(";") %>% .[[1]] %>% 
                                 gsub("--SEMICOLON--","\\;",., fixed=TRUE) %>% 
                                 list
                         ) %>% 
                  ungroup



# cleanup
rm(ini)



# Write to db -------------------------------------------------------------
initpool <- dbPool_MetabolomiQCs(5)
con <- poolCheckout(initpool)
dbBegin(con)

# functions for repeated use
# msg_fun <- . %>% extract2("sql") %>% 
#                 unlist %>% 
#                 length %>% 
#                 paste0(" drop queries to make.\n") %>% 
#                 message()

msg_fun <- function(tab, qm){
  
  extract2(tab, "sql") %>% 
    unlist %>% 
    length %>% 
    paste0(" ",qm," queries to make.\n") %>% 
    message()

}

sql_fun <-   . %>% 
             extract2("sql") %>% 
             unlist %>% 
             sapply(.,function(x){ 
                                    if(gsub("[[:space:]]", "", x)=="") return(TRUE)
                                    
                                    dbSendQuery(con, x) 
                                    dbCommit(con)
                                 }
                    ) %>% 
             unname



# Check if tables are already present and if so don't do anything
module_table %<>% 
  mutate(check_exist = map2_lgl(sql_fun, sql, ~ifelse(..1=="check",dbGetQuery(con, ..2) %>% 
                                                       unlist %>% 
                                                       unname %>% 
                                                       {.>0},NA
                                                     )
                               )
       ) %>% 
  group_by(module) %>% 
  filter(!any(sql_fun == "check" & check_exist == TRUE, na.rm = TRUE)) %>% 
  select(-enabled)




# DROP
module_table %>% filter(sql_fun == "drop") %>% msg_fun(., "drop")


module_table %>% filter(sql_fun == "drop") %>% 
                 arrange(desc(init_db_priority)) %>% 
                 sql_fun %>% 
                 {ifelse(all(.),"All drop queries were successful.\n",  paste0("Drop queries ",paste(which(!.),collapse=", ")," failed.\n")   )} %>% 
                 message


# Create
module_table %>% filter(sql_fun == "create") %>% msg_fun(., "create")


module_table %>% filter(sql_fun == "create") %>% 
                 arrange(init_db_priority) %>% 
                 extract2("sql") %>% 
                 unlist %>% 
                 sapply(.,function(x){ 
                                        if(gsub("[[:space:]]", "", x)=="") return(TRUE)
                                        
                                        dbSendQuery(con, x) 
                                        dbCommit(con)
                                     }
                        ) %>% 
                 unname %>% 
                 {ifelse(all(.),"All create queries were successful.\n",  paste0("Create queries ",paste(which(!.),collapse=", ")," failed.\n")   )} %>% 
                 message




# Close connection
poolReturn(con)
poolClose(initpool)
rm(initpool, con)
