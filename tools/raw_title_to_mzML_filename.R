library(dplyr)
library(purrr)
library(readr)



# 95B ---------------------------------------------------------------------
# get file paths
mzMLFiles <- list.files("/data/DanORC studies/95B Aarhus_plasma samples_Pos&Neg/Plasma Plate 95B Arhus Samples_pos.PRO", "*.mzML",full.names = TRUE, recursive = TRUE) %>% 
             tibble(mzMLFiles = .) %>% 
             mutate(basename = gsub("(.*)\\.mzML","\\1",basename(mzMLFiles)))

raw_files <- list.files("/data/DanORC studies/95B Aarhus_plasma samples_Pos&Neg/Plasma Plate 95B Arhus Samples_pos.PRO", "*.raw", full.names = TRUE, recursive = TRUE, include.dirs = TRUE) %>% 
             tibble(raw_files = .) %>% 
             mutate(basename = gsub("(.*)\\.raw","\\1",basename(raw_files)))

# match
all_files <- left_join(mzMLFiles, raw_files, by = "basename")



# extract info from header and format
all_files <- all_files %>% 
              mutate(header = map(raw_files, ~ readLines(paste0(..1,"/_HEADER.TXT"), , encoding = "latin1"))) %>%
              mutate(header = map(header, ~grep("Sample Description", ..1, value=TRUE))) %>%
              mutate(title = map_chr(header, ~ gsub(".*: (.*)", "\\1",..1))) %>% 
              mutate(title = gsub("_","-",title)) %>% 
              mutate(project = "95B") %>% 
              mutate(date = gsub(".*/(.*)-.*","\\1",mzMLFiles) %>% as.Date(format="%d%m%y") %>% format("%Y%m%d")) %>%
              mutate(seq = gsub(".*/.*-(.*).mzML$","\\1",mzMLFiles)) %>% 
              mutate(newname = paste(project, date, "Qold", seq, "pos", title, sep="_")) %>%
              mutate(newpath = paste0(dirname(mzMLFiles),"/renamed/", newname, ".mzML"))
              
              
# rename
dir.create(unique(dirname(all_files$newpath)), recursive = TRUE)
walk2(all_files$mzMLFiles, all_files$newpath, ~file.symlink(..1,..2))


# add to list of files
write(all_files$newpath,file="/data/mzML_filelist.txt",append=TRUE)






# Sample storage test -----------------------------------------------------
# get file paths
mzMLFiles <- list.files("/data/Sample storage test", "*.mzML",full.names = TRUE, recursive = TRUE) %>% 
  tibble(mzMLFiles = .) %>% 
  mutate(basename = gsub("(.*)\\.mzML","\\1",basename(mzMLFiles)))

raw_files <- list.files("/data/Sample storage test", "*.raw", full.names = TRUE, recursive = TRUE, include.dirs = TRUE) %>% 
  tibble(raw_files = .) %>% 
  mutate(basename = gsub("(.*)\\.raw","\\1",basename(raw_files)))

# match
all_files <- left_join(mzMLFiles, raw_files, by = "basename")



# extract info from header and format
all_files <- all_files %>% 
  mutate(header = map(raw_files, ~ readLines(paste0(..1,"/_HEADER.TXT"), , encoding = "latin1"))) %>%
  
  mutate(header_t = map(header, ~grep("Sample Description", ..1, value=TRUE))) %>%
  mutate(title = map_chr(header_t, ~ gsub(".*: .*_(.*)$", "\\1",..1))) %>% 
  mutate(title = gsub("_","-",title)) %>%
  mutate(title = gsub(".*: (.*)","\\1",title)) %>%
  mutate(title = trimws(title)) %>% 
  mutate(title = gsub(" ","-",title)) %>%
  
  mutate(project = "B210") %>% 
  mutate(date = gsub(".*/(.*)S-.*","\\1",mzMLFiles) %>% as.Date(format="%Y%m%d") %>% format("%Y%m%d")) %>%
  mutate(seq = gsub(".*/.*S-(.*).mzML$","\\1",mzMLFiles)) %>% 
  
  mutate(header_m = map(header, ~grep("MS Method", ..1, value=TRUE))) %>%
  mutate(mode = map_chr(header_m, ~ gsub(".*\\ldra-(.*)6min.*$", "\\1",..1))) %>% 
  
  mutate(newname = paste(project, date, "S", seq, mode, title, sep="_")) %>%
  mutate(newpath = paste0(dirname(mzMLFiles),"/renamed/", newname, ".mzML"))


# rename
dir.create(unique(dirname(all_files$newpath)), recursive = TRUE)
walk2(all_files$mzMLFiles, all_files$newpath, ~file.symlink(..1,..2))


# add to list of files
write(all_files$newpath,file="/data/mzML_filelist.txt",append=TRUE)