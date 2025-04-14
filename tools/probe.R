library(dplyr)
library(DBI)

# ssh -L 5555:a00835.science.domain:12345 tmh331@a00835.science.domain

pool <- dbPool_MetabolomiQCs(30)


files <-  paste0("
                    SELECT * FROM files
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble

ignored <-  paste0("
                    SELECT * FROM files_ignore
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble

file_info <-  paste0("
                    SELECT * FROM file_info
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


file_schedule <-  paste0("
                    SELECT * FROM file_schedule
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


std_stat_data_unique <-  paste0("
                    SELECT DISTINCT file_md5
                    FROM std_stat_data;
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


cont_data_unique <-  paste0("
                    SELECT DISTINCT file_md5
                    FROM cont_data;
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble




# are any missing file info?
sum(!( files$file_md5   %in%  file_info$file_md5    ))

# are any files not in the scheduler yet?
sum(!( files$file_md5   %in%  file_schedule$file_md5    ))


# how many are in queue
file_schedule %>% 
  group_by(module) %>% 
  summarise(waiting = sum(priority ==  1),
            done    = sum(priority == -1)
            )

# how many files do we have std data for?
nrow(std_stat_data_unique)


# how many files do we have cont data for?
nrow(cont_data_unique)














sum(ignored$file_md5 %in% file_info$file_md5)





sum(ignored$file_md5 %in% file_info$file_md5)



log <-  paste0("
                    SELECT * FROM log
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble %>% 
            mutate(ignore = TRUE)




grep("ignore",log$msg, value = TRUE)



dup_idx <- which(basename(files$path)=="M237 PRIMA_20220410_Sold_195_neg_6622-2-3.mzML")
dup_idx_ig <- which(basename(ignored$path)=="M237 PRIMA_20220410_Sold_195_neg_6622-2-3.mzML")


ignored[dup_idx_ig,]
files[dup_idx,]


