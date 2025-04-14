# read file list and metadata from database
library(MetabolomiQCsR)
library(dplyr)
library(tools)
library(DBI)
library(purrr)
library(pool)

pool <- dbPool_MetabolomiQCs(30)



file_info <-  paste0("
                    SELECT * FROM file_info
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


files <-  paste0("
                    SELECT * FROM files
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble

files_ignore <-  paste0("
                    SELECT * FROM files_ignore
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


poolClose(pool)


file_info <- file_info %>% 
  full_join(bind_rows(files, files_ignore), by = "file_md5") %>% 
  mutate(patterncheck = stringi::stri_count(basename(gsub("\\\\","/",path)), fixed = "_")) %>% 
  filter(patterncheck == 5)
  
rm(files)


raw_files <- readRDS(paste0(Sys.getenv("QC4METABOLOMICS_base"), "/raw_files_survey_parsed.rds")) %>% 
              rename(path = file) %>% 
              mutate(filename = basename(path))





# Read partial mzML and get original name
#i <- 1
survey_total <- vector(mode = "list", length = nrow(file_info))

# for(i in 1:nrow(file_info)){
for(i in bad_idx){
  
  mzML_path <- paste0(Sys.getenv("QC4METABOLOMICS_base"),"/",file_info$path[[i]]) %>% 
    normalizePath
  
  if(!file.exists(mzML_path)) next
  
  counter <- 0
  file_start <- character(0)
  while(length(file_start)==0 & counter <= 10){
    file_start <- readr::read_lines(mzML_path,n_max =100 )
    counter <- counter+1
  }
  
  
  org_filename <- grep( "<sourceFile id=\"_HEADER.TXT\"", file_start, value = TRUE) %>% 
    gsub('.*location=\"file://(.*)\">', "\\1", .) %>% 
    gsub('^Z:', "", .) %>% 
    # gsub('\\\\', "/", .) %>%
    normalizePath(mustWork = FALSE)
  
  
 
  survey <- raw_files %>% 
    filter(grepl(basename(gsub("\\\\","/",org_filename)),path, fixed = TRUE)) %>% 
    mutate(
                      method_raw = case_when(
                        method == "mkri6min04flow_10uL" ~                  "Qold",
                        method == "mkri6min04flow_10uL_WASH PROG" ~        "Qold",
                        method == "STANDBY_TBarri"      ~                  "Qold",
                        method == "washing_step"                         ~ "Qold",

                        method == "Metabolomics_version2_7min05flow_5uL" ~ "Qnew",
                        method == "Metabolomics_version2_7min_05flow_5uL"~ "Snew",
                        
                        method == "mkri5,5min07flow,20full" ~              "mkri2008",
                        method == "mkri7-5min04flow_7uL" ~                 "mkri7-5min04flow-7uL",
                        method == "washing_step" ~                         "mkri7-5min04flow-7uL",
                        
                        method == "Quat_metabolomic_5uL_2" ~               "Qquat",
                        
                        method == "SCFA qtof" ~                            "QSCFA",
                        method == "SCFA test1" ~                           "SSCFA",
                        
                        method == "HILIC1" ~                               "QHILIC",
                        
                  
                        
                        
                        .default = NA
                      )
                    ) %>% 
    mutate(method_filename = gsub(".*_.*_(.*)_.*_.*_.*.mzML","\\1",basename(mzML_path))    ) %>% 
    mutate(path = gsub("^/data","",path)) %>%
    mutate(filename_disk_sans_ext = file_path_sans_ext(basename(path))) %>% 
    filter(!is.na(date)) %>% 
    slice(1) # sometimes more copies
  
  
  
  survey_total[[i]] <- file_info[i,] %>% 
    mutate(filename_db_sans_ext = file_path_sans_ext(basename(path))) %>% 
    bind_cols(survey)
  
  
  rm(mzML_path, org_filename, survey, file_start) # we don't want weird bugs to mismatch files
}




survey_total_bind <- bind_rows(survey_total)

table(survey_total_bind$instrument...5, survey_total_bind$method_raw, useNA = "ifany", dnn = c("in DB", "in raw"))



# missing info in DB
# I guess OK, just not in DB yet for some reason. but to investigate
survey_total_bind %>% filter(is.na(instrument...5))


# missing defined method from raw file
# we see what method file was used in those not yet defined
survey_total_bind %>% filter(is.na(method_raw)) %>% pull(method) %>% as.character() %>% table %>% t %>% t


# look one up
survey_total_bind %>% 
  filter(method=="HILIC1") %>% slice(1) %>% t








survey_total_bind %>% filter(is.na(method_raw))






# these methods needs to be kicked out of the system and removed ----------
# from the file list
# DONE

# get things to remove
to_rem <- survey_total_bind %>% 
              filter(method %in% c( "DAminoAcidstest1BEH", "DAminoAcidstest3", "Pyruvate_5min_03flow_50C_NH4Ac",
                                    "DAminoAcidstest7", "Pyruvate_3min_03flow_10%_50C", "Pyruvate_3min_03flow_50C",
                                    "Pyruvate_3min_03flow_50C_BEH", "Pyruvate_3min_03flow_5%_50C",
                                    "Pyruvate_3,5min_03flow_80%_50C_NH4OH", "DAminoAcidstest5", "Pyruvate_3min_03flow_80%_50C",
                                    "Pyruvate_3,5min_03flow_50%_50C_NH4OH", "DAminoAcidstest4", "DAminoAcidstest1",
                                    "DAminoAcidstest2", "EtGEtS-fast"
                                  )
                    )


file_file_md5_to_rem <- to_rem %>% pull(file_md5)
basename_to_rem <- to_rem %>% pull(path...7) %>% basename


mzML_filelist <- readLines("/data/mzML_filelist.txt")


del_lines <- basename(mzML_filelist) %in% basename_to_rem


length(mzML_filelist)
length(mzML_filelist[!del_lines])

writeLines(mzML_filelist[!del_lines], "/data/mzML_filelist.txt")



# creating list of DELETE queries with each id
delete_queries <- c(
                    paste0("DELETE FROM files_ignore WHERE (file_md5 = '", file_md5_to_rem, "');"),
                    paste0("DELETE FROM std_stat_data WHERE (file_md5 = '", file_md5_to_rem, "');"),
                    paste0("DELETE FROM cont_data WHERE (file_md5 = '", file_md5_to_rem, "');"),
                    paste0("DELETE FROM file_info WHERE (file_md5 = '", file_md5_to_rem, "');"),
                    paste0("DELETE FROM file_schedule WHERE (file_md5 = '", file_md5_to_rem, "');"),
                    paste0("DELETE FROM files WHERE (file_md5 = '", file_md5_to_rem, "');")
                    )


# executing each query
pool <- dbPool_MetabolomiQCs(30)
con <- poolCheckout(pool)
res <- map(.x = delete_queries, .f = dbExecute, conn = con)
poolReturn(con)





# Why are files that should be mkri2008 instead marked as Qnew? ---------------------
survey_total_bind %>% filter(`instrument...5`=="Qnew", method_raw == "mkri2008") %>% pull(`path...7`) %>% gsub("^/.*?/(.*?)/.*", "\\1", .) %>% unique
# all from Fruit and vegetables studies/Lxp_M143_spring2008.pro
# it seems they are in the DB with as Qnew. But filenames are correct???
# I will remove from the db. The system should pick them up correctlu.
# DONE

file_md5_to_rem <- survey_total_bind %>% 
                        filter(`instrument...5`=="Qnew", method_raw == "mkri2008")  %>% 
                        pull(file_md5)



# creating list of DELETE queries with each id
delete_queries <- c(
                    paste0("DELETE FROM files_ignore WHERE (file_md5 = '", file_md5_to_rem, "');"),
                    paste0("DELETE FROM std_stat_data WHERE (file_md5 = '", file_md5_to_rem, "');"),
                    paste0("DELETE FROM cont_data WHERE (file_md5 = '", file_md5_to_rem, "');"),
                    paste0("DELETE FROM file_info WHERE (file_md5 = '", file_md5_to_rem, "');"),
                    paste0("DELETE FROM file_schedule WHERE (file_md5 = '", file_md5_to_rem, "');"),
                    paste0("DELETE FROM files WHERE (file_md5 = '", file_md5_to_rem, "');")
                    )


# executing each query
pool <- dbPool_MetabolomiQCs(30)
con <- poolCheckout(pool)
res <- map(.x = delete_queries, .f = dbExecute, conn = con)
poolReturn(con)




# Figure those that are really Qquat but the db says Qnew -----------------
# these we mislabelled originally because of a misunderstanding of the history of the systems
# They need to be changed in the DB file_info and peak picking reset in the scheduler
# DONE

survey_total_bind %>% filter(`instrument...5`=="Qnew", method_raw == "Qquat")

file_md5_to_change <- survey_total_bind %>% 
                        filter(`instrument...5`=="Qnew", method_raw == "Qquat") %>% 
                        pull(file_md5)
                        

file_info_new <-  paste0("
                    SELECT * FROM file_info
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


# file info fix
con <- poolCheckout(pool)
    dbBegin(con)
    
    
file_info_new %>% 
      filter(file_md5 %in% file_md5_to_change) %>%
      mutate(instrument = "Qquat") %>% 
      sqlAppendTable(pool, "file_info", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE instrument = values(instrument)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)

# scheduler fix
file_schedule_new <-  paste0("
                    SELECT * FROM file_schedule
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble
    
con <- poolCheckout(pool)
    dbBegin(con)
    

file_schedule_new %>% 
      filter(file_md5 %in% file_md5_to_change, module == "TrackCmp") %>%
      mutate(priority = 1) %>% 
      sqlAppendTable(pool, "file_schedule", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE priority = values(priority)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)



# creating list of DELETE queries with each id
delete_queries <- c(
                    paste0("DELETE FROM file_schedule WHERE module = 'TrackCmp' AND priority = -1 AND (file_md5 = '", file_md5_to_change, "');")
                    )


# executing each query
pool <- dbPool_MetabolomiQCs(30)
con <- poolCheckout(pool)
res <- map(.x = delete_queries, .f = dbExecute, conn = con)
poolReturn(con)

    
    



# Why are files that should be Qquat instead marked as Qnew? ---------------------
# wrongly labelled
# fix in DB


survey_total_bind %>% filter(`instrument...5`=="Snew", method_raw == "Qquat")

file_md5_to_change <- survey_total_bind %>% 
                        filter(`instrument...5`=="Snew", method_raw == "Qquat") %>% 
                        pull(file_md5)
                        

file_info_new <-  paste0("
                    SELECT * FROM file_info
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


# file info fix
con <- poolCheckout(pool)
    dbBegin(con)
    
    
file_info_new %>% 
      filter(file_md5 %in% file_md5_to_change) %>%
      mutate(instrument = "Qquat") %>% 
      sqlAppendTable(pool, "file_info", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE instrument = values(instrument)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)

# scheduler fix
file_schedule_new <-  paste0("
                    SELECT * FROM file_schedule
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble
    
con <- poolCheckout(pool)
    dbBegin(con)
    

file_schedule_new %>% 
      filter(file_md5 %in% file_md5_to_change, module == "TrackCmp") %>%
      mutate(priority = 1) %>% 
      sqlAppendTable(pool, "file_schedule", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE priority = values(priority)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)

    
    
    
    
    
    
    
    

# Why are files that should be QSCFA instead marked as Qnew? ---------------------
# wrongly labelled
# fix in DB
# DONE


survey_total_bind %>% filter(`instrument...5`=="Qnew", method_raw == "QSCFA")

survey_total_bind %>% filter(`instrument...5`=="Qnew", method_raw == "QSCFA") %>% pull(`path...7`) %>% gsub("^/(.*?)/.*", "\\1", .) %>% unique
    
    
file_md5_to_change <- survey_total_bind %>% 
                        filter(`instrument...5`=="Qnew", method_raw == "QSCFA") %>% 
                        pull(file_md5)
                        

file_info_new <-  paste0("
                    SELECT * FROM file_info
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


# file info fix
con <- poolCheckout(pool)
    dbBegin(con)
    
    
file_info_new %>% 
      filter(file_md5 %in% file_md5_to_change) %>%
      mutate(instrument = "QSCFA") %>% 
      sqlAppendTable(pool, "file_info", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE instrument = values(instrument)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)

# scheduler fix
file_schedule_new <-  paste0("
                    SELECT * FROM file_schedule
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble
    
con <- poolCheckout(pool)
    dbBegin(con)
    

file_schedule_new %>% 
      filter(file_md5 %in% file_md5_to_change, module == "TrackCmp") %>%
      mutate(priority = 1) %>% 
      sqlAppendTable(pool, "file_schedule", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE priority = values(priority)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)

    
    
    
    
    


# Why are files that should be Snew instead marked as Sold? ---------------------
# these seem like random files that are wrong in the DB. how did that happen???
# filenames are wrong. When the other correct files in the same projects get fixed???
# DONE

survey_total_bind %>% filter(`instrument...5`=="Sold", method_raw == "Snew")

survey_total_bind %>% filter(`instrument...5`=="Sold", method_raw == "Snew") %>% pull(`path...7`)
    



file_md5_to_change <- survey_total_bind %>% 
                        filter(`instrument...5`=="Sold", method_raw == "Snew") %>% 
                        pull(file_md5)
                        

file_info_new <-  paste0("
                    SELECT * FROM file_info
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


# file info fix
con <- poolCheckout(pool)
    dbBegin(con)
    
    
file_info_new %>% 
      filter(file_md5 %in% file_md5_to_change) %>%
      mutate(instrument = "Snew") %>% 
      sqlAppendTable(pool, "file_info", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE instrument = values(instrument)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)

# scheduler fix
file_schedule_new <-  paste0("
                    SELECT * FROM file_schedule
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble
    
con <- poolCheckout(pool)
    dbBegin(con)
    

file_schedule_new %>% 
      filter(file_md5 %in% file_md5_to_change, module == "TrackCmp") %>%
      mutate(priority = 1) %>% 
      sqlAppendTable(pool, "file_schedule", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE priority = values(priority)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)

    
    


# What are those that are NA in the database??? ---------------------------

survey_total_bind %>% filter(is.na(`instrument...5`)) %>% arrange(`path...7`) %>% pull(`path...7`)
    

baddies <- survey_total_bind %>% filter(is.na(`instrument...5`)) %>% arrange(`path...7`) %>% pull(file_md5)


select <- 1

survey_total_bind %>% filter(file_md5 %in% baddies[select]) %>% t

files_ignore %>% filter(file_md5 %in% baddies[select])

file_info %>% filter(file_md5 %in% baddies[select])



# are all from the ignore list?
# YES
(baddies %in% files_ignore$file_md5) %>% all

# some are dublicate filenames. but somehow not identical
# AHA. someone changed _ to - it seems
files_ignore %>% filter(file_md5 %in% baddies[1]) %>% pull(path) %>% map(utf8ToInt) %>% do.call(setdiff, .) %>% intToUtf8

# Others are dups
# something seems to have been supposed to have been ignored but was not. I will remove from db for now.




# It looks like some mess here.
# I delete the files from everywhere so they are picked up again


# creating list of DELETE queries with each id
delete_queries <- c(
                    paste0("DELETE FROM files_ignore WHERE (file_md5 = '", baddies, "');"),
                    paste0("DELETE FROM std_stat_data WHERE (file_md5 = '", baddies, "');"),
                    paste0("DELETE FROM cont_data WHERE (file_md5 = '", baddies, "');"),
                    paste0("DELETE FROM file_info WHERE (file_md5 = '", baddies, "');"),
                    paste0("DELETE FROM file_schedule WHERE (file_md5 = '", baddies, "');"),
                    paste0("DELETE FROM files WHERE (file_md5 = '", baddies, "');")
                    )


# executing each query
pool <- dbPool_MetabolomiQCs(30)
con <- poolCheckout(pool)
res <- map(.x = delete_queries, .f = dbExecute, conn = con)
poolReturn(con)



# What are those that are missing a method in the survey? -----------------
# those tests that were removed above. Already fixed
survey_total_bind %>% filter(is.na(method_raw)) %>% pull(method) %>% unique %>% t %>% t




# Reset after changing compound settings ----------------------------------


# Change records in file_info ---------------------------------------------
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



    
file_md5_to_reset <- file_info %>% 
      filter(instrument == "Snew", mode == "pos") %>% 
      pull(file_md5)
    
    

con <- poolCheckout(pool)
    dbBegin(con)
    
        
file_schedule %>% 
      filter(file_md5 %in% file_md5_to_reset, module == "TrackCmp") %>% 
      mutate(priority = 1) %>% 
      sqlAppendTable(pool, "file_schedule", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE priority = values(priority)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)
    
    

# Who is Sold popping up again??? -----------------------------------------
# dunno. but they are Snew

file_info <-  paste0("
                    SELECT * FROM file_info
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble
    

files <-  paste0("
                    SELECT * FROM files
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble

file_info %>% 
      filter(instrument == "Sold") %>%
      left_join(files, by = "file_md5") %>% t




# file info fix
con <- poolCheckout(pool)
    dbBegin(con)
    
    
file_info %>% 
      filter(instrument == "Sold") %>%
      mutate(instrument = "Snew") %>% 
      sqlAppendTable(pool, "file_info", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE instrument = values(instrument)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)
    
    
#forgot tot fix scheduler. Will do manually

file_md5_to_reset <- c('4978bfe7d977663fc3b6452eebf88769','82e030006e028ebe020d6f2b0338ac60','d8a2a26942bab1d1eea0db8f694714f2','f0ac17bf2b1113efef45874ffedd2a80','f2d83fedc7d84ef9080f8d5705fc813c')
  
  
con <- poolCheckout(pool)
    dbBegin(con)
    
        
file_schedule %>% 
      filter(file_md5 %in% file_md5_to_reset, module == "TrackCmp") %>% 
      mutate(priority = 1) %>% 
      sqlAppendTable(pool, "file_schedule", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE priority = values(priority)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)


# Fix capitalization of QHILIC --------------------------------------------

    

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
      filter(instrument == "QHIlic") %>% 
      mutate(instrument = "QHILIC") %>% 
      sqlAppendTable(pool, "file_info", .) ->
      sql_query
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE instrument = values(instrument)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    
    res <- dbCommit(con)
    poolReturn(con)
    
    
    
    