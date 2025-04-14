dir <- "/data/OPUS studies/B260 SHOPUS urine.pro"

to_fix <- list.files(dir,"\\.mzML$" ,full.names = TRUE, recursive = TRUE)

to_fix <- grep("27062013|16092013|24022012-0001|24022012-0002|CALIBRATION|TEST|Standards|MSMS|PROP|std|VASK|test|TJEK|blank|urinmix|NAF|glu|TRAINING|uracil|water|cof|Cresol|Data/mzML", to_fix, value = TRUE, invert = TRUE)
to_fix <- grep("-", to_fix, value = TRUE, invert = FALSE)



project <- "B260 SHOPUS urine"
#instrument <- "Qnew"
date_format <- "%d%m%Y"
    


sample_list <- list.files(dir,"\\.SPL", full.names = TRUE, recursive = TRUE) %>% 
  set_names() %>% 
  gsub(" ","\\\\ ", .) %>%
  grep("MSMS|standards|Std",., value = TRUE, invert = TRUE) %>% 
  map(mdb.get, tables = "ANALYSIS") %>% 
  map(~..1[,c("FILE.NAME", "FILE.TEXT", "INLET.FILE")]) %>% 
  bind_rows(.id = "spl") %>% 
  as_tibble


idx <- match(file_path_sans_ext(basename(to_fix)), sample_list$FILE.NAME )

desc <- sample_list$FILE.TEXT[idx] %>% 
        gsub("_", "-",.) %>% 
        gsub("/", "-",.) %>% 
        gsub("!", "",.) %>% 
        trimws %>% 
        iconv("latin1", "ASCII", sub="-")


any(is.na(desc))

to_fix[is.na(desc)]



file_tab <- tibble(to_fix, desc = desc, inlet = sample_list$INLET.FILE[idx]) %>% 
              mutate(date = gsub(".*/(.*)-.*\\.mzML$", "\\1" ,to_fix)) %>%
              mutate(
                    date = case_when(
                      grepl("^2013",date) ~ as_date(date, format = "%Y%m%d"),
                      !grepl("^2013",date) ~ as_date(date, format = "%d%m%Y"),
                      .default = NA
                    )
                  ) %>% 
              mutate(batch_seq_nr = gsub(".*/.*-(.*)\\.mzML$", "\\1" ,to_fix)) %>%
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
                      inlet == "mkri6min04flow_10uL" ~ "Qold",
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
