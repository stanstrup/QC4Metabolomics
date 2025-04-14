dir <- "/data/Fruit and vegetables studies/Lxp_M143_spring2008.pro"

to_fix <- list.files(dir,"\\.mzML$" ,full.names = TRUE, recursive = TRUE)

to_fix <- grep("CALIBRATION|TEST|MSMS|PROP|std|VASK|test|TJEK|blank|urinmix|NAF|glu|TRAINING|uracil|water|cof|Cresol|Data/mzML|140308|100608|22012015|26012015|020608|030608|041207|060608|090608|300508|040608", to_fix, value = TRUE, invert = TRUE)
to_fix <- grep("-", to_fix, value = TRUE, invert = FALSE)

project <- "M143"
instrument <- "mkri2008"
date_format <- "%d%m%y"
    


sample_list <-  list.files(dir,"\\.SPL", full.names = TRUE, recursive = TRUE) %>% 
  set_names() %>% 
  gsub(" ","\\\\ ", .) %>%
  map(mdb.get, tables = "ANALYSIS") %>% 
  map(~..1[,c("FILE.NAME", "FILE.TEXT")]) %>% 
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



file_tab <- tibble(to_fix, desc = desc) %>% 
              mutate(date = gsub(".*/(.*)-.*\\.mzML$", "\\1" ,to_fix)) %>%
              mutate(date = format(as_date(date, format = date_format), "%Y%m%d")) %>%
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
              mutate(fixed = glue("{gsub('/mzML','/mzML_renamed',dirname(to_fix))}/{project}_{date}_{instrument}_{batch_seq_nr}_{mode}_{desc}.mzML"))


head(file_tab$fixed)

# anything unexpected?
any(is.na(file_tab$mode))
any(is.na(file_tab$date))
any(is.na(file_tab$batch_seq_nr))
any(is.na(file_tab$desc))


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
