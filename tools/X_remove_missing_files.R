# Libraries ---------------------------------------------------------------
library(MetabolomiQCsR)
library(dplyr)
library(magrittr)
#library(stringr)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(xml2)
library(purrr)
library(tidyr)
library(fs)


# Establish connection to get new files -----------------------------------------------
pool <- dbPool_MetabolomiQCs(30)




file_tbl <- "SELECT  path, file_md5
             FROM    files
             UNION ALL
             SELECT  path, file_md5
             FROM    files_ignore" %>% 
                dbGetQuery(pool,.) %>% 
                as_tibble %>%
                mutate(path = paste0(Sys.getenv("QC4METABOLOMICS_base"),"/",path))

file_tbl %<>% mutate(file_found = file_exists(path))


bad_file_md5 <- file_tbl %>% filter(!file_found) %>% pull(file_md5)

if(length(bad_file_md5)>0){
  tables_to_prune <- c("std_stat_data", "file_schedule", "file_info", "cont_data", "files", "files_ignore")
  
  
  cmd <- expand.grid(bad_file_md5, tables_to_prune, stringsAsFactors = FALSE)
  
  
  sql_query <- paste0("DELETE FROM ",cmd$Var2," WHERE file_md5='",cmd$Var1,"';")
  
  
  con <- poolCheckout(pool)
        dbBegin(con)
        
        
  for(i in seq_along(sql_query)){
    dbSendQuery(con,sql_query[i])
    dbCommit(con)
  }
  
  poolReturn(con)
  

}
