library(dplyr)

files <- readRDS(paste0(Sys.getenv("QC4METABOLOMICS_base"),"/raw_files_survey_parsed.rds"))


files <- files %>% 
            arrange(desc(time)) %>% 
            mutate(mzML_path = paste0(dirname(file),"/../mzML/", gsub("\\.raw$",".mzML",basename(file)))) %>% 
            mutate(file_exists = file.exists(mzML_path))


table(files$file_exists)


files_mzML_path <- files %>% filter(!file_exists) %>% pull(mzML_path)


unique(gsub("(.*)mzML/.*","\\1",files_mzML_path))


out_file <- "/data/mzML_filelist.txt"

# read existing list
old_files <- readLines(out_file)

# remove all-ready found files
files_mzML_path <- files_mzML_path[!(files_mzML_path %in% old_files)]






files %>% 
  filter(time<as.POSIXct.Date(as.Date("2025-01-01")), time>as.POSIXct.Date(as.Date("2022-03-01"))) %>% 
  pull(file)


files %>% 
  filter(time<as.Date("2023-01-01"), time>as.Date("2022-03-01")) %>% 
  pull(mzML_path) %>% 
  {unique(gsub("(.*)/Data/../mzML/.*","\\1",.))} %>% 
  grep("\\.mzML$", ., value=TRUE, invert=T)






# files %>% give me ~ 50,000 files
files_filt <- files %>% 
  filter(file_exists) %>% 
  filter(!(normalizePath(mzML_path) %in% normalizePath(old_files)))




files_filt %>% #slice(1:50000) %>% 
  pull(mzML_path) %>% 
  {unique(gsub("(.*)/Data/../mzML/.*","\\1",.))} %>% 
  grep("\\.mzML$", ., value=TRUE, invert=T) %>% sort %>% dput





# write out list with new files
if(length(files)!=0) cat(files, file = out_file, sep="\n", append=TRUE)





