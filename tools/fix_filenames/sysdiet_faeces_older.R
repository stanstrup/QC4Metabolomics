# Fix SYSDIET feaces -------------------------------------------------------

#to_fix <- list.files("I:/SCIENCE-NEXS-NyMetabolomics/Projects/SYSDIET/Sysdiet multicenter intervention_feaces samples/mzML", full.names = TRUE, recursive = TRUE)
to_fix <- list.files("/data/SYSDIET/Sysdiet multicenter intervention_feaces samples/Data/mzML", full.names = TRUE, recursive = TRUE)

project <- "SYSDIET-feaces"
instrument <- "Qnew"
date_format <- "%d%m%Y"
          


sample_list <- "/data/SYSDIET/Sysdiet multicenter intervention_feaces samples/SampleDB/Sysdiet_feacesPlate1+2.SPL" %>% 
                gsub(" ","\\\\ ", .) %>% 
  mdb.get(tables = "ANALYSIS") %>% 
  as_tibble


idx <- match(file_path_sans_ext(basename(to_fix)), sample_list$FILE.NAME )

desc <- sample_list$FILE.TEXT[idx] %>% 
        trimws %>% 
        gsub("_", "-",.) %>% 
        iconv("latin1", "ASCII", sub="-")


any(is.na(desc))

 


file_tab <- tibble(to_fix, desc = desc) %>% 
              mutate(date = gsub(".*/(.*)-.*\\.mzML$", "\\1" ,to_fix)) %>%
              mutate(date = format(as_date(date, format = "%d%m%Y"), "%Y%m%d")) %>%
              mutate(batch_seq_nr = gsub(".*/.*-(.*)\\.mzML$", "\\1" ,to_fix)) %>%
              # slice(1:2) %>% 
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
dir.create(unique(dirname(file_tab$fixed)))

#file.symlink(file_tab$to_fix, file_tab$fixed)
#system(glue('ln -s "{file_tab$to_fix[1]}" "{file_tab$fixed[1]}"'))

file.copy(file_tab$to_fix, file_tab$fixed)


# add files to file-list
if(nrow(file_tab)!=0) cat(file_tab$fixed, file = out_file, sep="\n", append=TRUE)


# remove old filenames
mz_files <- readLines(out_file)

if(nrow(file_tab)!=0) writeLines(mz_files[!(mz_files %in% file_tab$to_fix)], out_file)
