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



# Get settings ------------------------------------------------------------

# search locations
ini_file <- c("./MetabolomiQCs.conf", # if file in working dir use that
              "../MetabolomiQCs.conf", # two folder back
              "~/MetabolomiQCs.conf", # if file in home folder
              system.file("extdata", "MetabolomiQCs.conf", package = "MetabolomiQCsR") # If no file found use the one from the package
)


# check if we can find any config file at all
if(all(!file.exists(ini_file))) stop("No MetabolomiQCs.conf found.\n
                                     This should not happen since the packages comes with a default configuration file.")


# Get the first of the module_Files in the above list
ini_file <- ini_file[file.exists(ini_file)][1]

# read the ini file
message(paste0("Using MetabolomiQCsR configuration file in: ",normalizePath(ini_file)))
ini <- read.ini(normalizePath(ini_file))



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
                

# Add create/drop factor
module_table %<>% cbind(data_frame(sql_fun = list(factor(c("drop","create"),c("drop","create"))))) %>% 
                  as.tbl %>% 
                  unnest(sql_fun)


# Find files and check if they exist

module_table %<>% rowwise %>% 
                  mutate(script_path = paste0("../Modules/",module,"/",switch(as.character(sql_fun), drop = "init_db_drop.sql", create = "init_db_create.sql"))) %>% 
                  ungroup %>% 
                  mutate(file_exists = file.exists(script_path)) %>% 
                  filter(file_exists) %>%
                  rowwise %>% 
                  mutate(sql = readLines(script_path) %>% paste(collapse="\n ") %>% strsplit(";") %>% .[[1]] %>% list) %>% 
                  ungroup



# cleanup
rm(ini, ini_file)



# Write to db -------------------------------------------------------------
pool <- dbPool_MetabolomiQCs(5)
con <- poolCheckout(pool)
dbBegin(con)

# functions for repeated use
msg_fun <- . %>% extract2("sql") %>% 
                unlist %>% 
                length %>% 
                paste0(" drop queries to make.\n") %>% 
                message()


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



# DROP
module_table %>% filter(sql_fun == "drop") %>% msg_fun
                


module_table %>% filter(sql_fun == "drop") %>% 
                 arrange(desc(init_db_priority)) %>% 
                 sql_fun %>% 
                 {ifelse(all(.),"All drop queries were successful.\n",  paste0("Drop queries ",paste(which(!.),collapse=", ")," failed.\n")   )} %>% 
                 message


# Create
module_table %>% msg_fun


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
poolClose(pool)
rm(pool, con)
