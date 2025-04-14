dir <- c("/data//PRIMA projects/PRIMA.pro/PRIMA urin metabolomics")

to_fix <- list.files(dir,"\\.mzML$" ,full.names = TRUE, recursive = TRUE)

to_fix <- grep("/renamed/",to_fix, value = TRUE, invert = TRUE)

to_fix <- grep("mzML_with_all_functions|STD|CALIBRATION|TEST|Standards|MSMS|PROP|std|VASK|test|TJEK|blank|urinmix|NAF|glu|TRAINING|uracil|water|cof|Cresol|Data/mzML", to_fix, value = TRUE, invert = TRUE)


project <- "PRIMA urin metabolomics"
#instrument <- "Qnew"
#date_format <- "%Y-%m-%d"
    

# remove difficult characters
SPL <- list.files(dir,"\\.SPL$", full.names = TRUE, recursive = TRUE)
SPL_new <- gsub("&","_", SPL)
temp <- file.rename(SPL, SPL_new)


sample_list <- SPL_new %>% 
  set_names() %>% 
  gsub(" ","\\\\ ", .) %>%
  grep("MSMS|standards|Std",., value = TRUE, invert = TRUE) %>% 
  map(mdb.get, tables = "ANALYSIS", autodate = FALSE) %>% 
  map(~..1[,c("FILE.NAME",  "INLET.FILE")]) %>% 
  bind_rows(.id = "spl") %>% 
  as_tibble


idx <- match(file_path_sans_ext(basename(to_fix)), sample_list$FILE.NAME )

desc <- sample_list$FILE.NAME[idx] %>% 
        #gsub("_", "-",.) %>% 
        gsub("/", "-",.) %>% 
        gsub("!", "",.) %>% 
        trimws %>% 
        iconv("latin1", "ASCII", sub="-") %>% 
        gsub(".*_(.*)","\\1",.)


any(is.na(desc))

to_fix[is.na(desc)]




# single file not in sample lists. seems unimportant std or something
# to_fix <- to_fix[!is.na(desc)]
# idx <- idx[!is.na(desc)]
# desc <- desc[!is.na(desc)]




file_tab <- tibble(to_fix, desc = desc, inlet = sample_list$INLET.FILE[idx]) %>% 
              mutate(date = gsub(".*/.*?_(.*?)_.*\\.mzML$", "\\1" ,to_fix)) %>%
  
              mutate(date_chars = nchar(date)) %>% 
              mutate(
                    date = case_when(
                      date_chars==10 ~ as_date(date, format = "%Y-%m-%d"),
                      date_chars==8  & substring(date, nchar(date) - 4 + 1) %in% c(2000:2025) ~ as_date(date, format = "%d%m%Y"),
                      date_chars==8  & substring(date, 1,4) %in% c(2000:2025) & substring(date, 5,6)<=12 ~ as_date(date, format = "%Y%m%d"),
                      date_chars==8  & substring(date, 1,4) %in% c(2000:2025) & substring(date, 5,6) > 12 ~ as_date(date, format = "%Y%d%m"),
                      date_chars==9 & grepl("Q$", date, ignore.case = TRUE) ~ as_date(date, format = "%d%m%YQ"),
                      .default = NA
                    )
                  ) %>%  
  
              #mutate(date = format(as_date(date, format = date_format), "%Y%m%d")) %>%
              mutate(batch_seq_nr = gsub(".*/.*?_.*?_.*?_(.*?)_.*\\.mzML$", "\\1" ,to_fix)) %>%
              # slice(1:2) %>% 
              # mutate(mode = imap_chr(to_fix, ~{print(.y);mzML2mode(.x)})) %>%
              mutate(mode = map_chr(to_fix, mzML2mode)) %>% 
              mutate(
                      mode = case_when(
                        grepl("pos",mode) ~ "pos",
                        grepl("neg",mode) ~ "neg",
                        .default = NA
                      )
                    ) %>% 
              mutate(
                    instrument = case_when(
                      inlet == "Metabolomics_version2_7min05flow_5uL" ~ "Qnew",
                      inlet == "Metabolomics_version2_7min_05flow_5uL"~ "Snew",
                      inlet == "mkri6min04flow_10uL" ~ "Qold",
                      inlet == "STANDBY_TBarri"      ~ "Qold",
                      inlet == "Quat_metabolomic_5uL_2" ~ "Qquat",
                      .default = NA
                    )
                  ) %>% 
              mutate(fixed = glue("{gsub('/mzML','/mzML_renamed',dirname(to_fix))}/{project}_{date}_{instrument}_{batch_seq_nr}_{mode}_{desc}.mzML"))


head(file_tab$fixed)

# anything unexpected?
any(is.na(file_tab$mode))
any(is.na(file_tab$date))
any(is.na(file_tab$batch_seq_nr))
any(is.na(file_tab$desc))
any(is.na(file_tab$instrument))


# copy to new folder
file_tab$fixed %>% dirname() %>% unique() %>% walk(dir.create)

#file.symlink(file_tab$to_fix, file_tab$fixed)
#system(glue('ln -s "{file_tab$to_fix[1]}" "{file_tab$fixed[1]}"'))

file.copy(file_tab$to_fix, file_tab$fixed)


# add files to file-list
if(nrow(file_tab)!=0) cat(file_tab$fixed, file = out_file, sep="\n", append=TRUE)


# remove old filenames
mz_files <- readLines(out_file)

if(nrow(file_tab)!=0) writeLines(mz_files[!(mz_files %in% file_tab$to_fix)], out_file)
