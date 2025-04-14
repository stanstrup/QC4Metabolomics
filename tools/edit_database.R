library(MetabolomiQCsR)
library(dplyr)
library(DBI)
library(pool)
library(purrr)

pool <- dbPool_MetabolomiQCs(30)


# Change records in file_info ---------------------------------------------
file_info <-  paste0("
                    SELECT * FROM file_info
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


con <- poolCheckout(pool)
    dbBegin(con)
    
    
    file_info %>% 
      #filter(grepl("test",instrument)) %>%
      filter(instrument == "Sold") %>% 
      mutate(instrument = "Snew") %>% 
      sqlAppendTable(pool, "file_info", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE instrument = values(instrument)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)
    
    
    

# Delete files ------------------------------------------------------------

# md5_to_rem <-  paste0("
#                     SELECT * FROM file_info
#                     "
#                     ) %>% 
#             dbGetQuery(pool,.) %>% 
#             distinct() %>% 
#             as_tibble %>% 
#             filter(grepl("67|72",instrument)) %>% 
#             pull(file_md5)
#    
    
md5_to_rem <-  paste0("
                    SELECT * FROM files
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble %>% 
            filter(grepl("Sold",path)) %>% 
            pull(file_md5)
    

    


# creating list of DELETE queries with each id
delete_queries <- c(
                    paste0("DELETE FROM files_ignore WHERE (file_md5 = '", md5_to_rem, "');"),
                    paste0("DELETE FROM std_stat_data WHERE (file_md5 = '", md5_to_rem, "');"),
                    paste0("DELETE FROM cont_data WHERE (file_md5 = '", md5_to_rem, "');"),
                    paste0("DELETE FROM file_info WHERE (file_md5 = '", md5_to_rem, "');"),
                    paste0("DELETE FROM file_schedule WHERE (file_md5 = '", md5_to_rem, "');"),
                    paste0("DELETE FROM files WHERE (file_md5 = '", md5_to_rem, "');")
                    )


# executing each query

con <- poolCheckout(pool)
    dbBegin(con)
    
res <- map(.x = delete_queries, .f = dbExecute, conn = con)
  


res <- dbCommit(con)
poolReturn(con)
