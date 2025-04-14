library(dplyr)


folders <- c(#"I:/SCIENCE-NEXS-NyMetabolomics/Projects/Urolithin/Data",
             # "I:/SCIENCE-NEXS-NyMetabolomics/Projects/Ida plants/Conjugated std Synapt/Data",
             # "I:/SCIENCE-NEXS-NyMetabolomics/Projects/Klaus Muller.pro/Data",
             # "I:/SCIENCE-NEXS-NyMetabolomics/Projects/PRIMA/Prima fecal metabolomic/Data",
             # "I:/SCIENCE-NEXS-NyMetabolomics/Projects/Ping Ping mice/Data",
             # 
             # "I:/SCIENCE-NEXS-NyMetabolomics/Projects/M237 PRIMA/fixed/M237 PRIMA.pro/Data",
             # "I:/SCIENCE-NEXS-NyMetabolomics/Projects/M237 PRIMA DDA/fixed/M237 PRIMA DDA.pro/Data",
             # "I:/SCIENCE-NEXS-NyMetabolomics/Projects/PrimaFecal/fixed/PrimaFecal.pro/Data",
             # "I:/SCIENCE-NEXS-NyMetabolomics/Projects/PRIMA/PRIMA urin metabolomics/Data",
             #"I:/SCIENCE-NEXS-NyMetabolomics/Projects/DanORC studies/PPL 95A plasma/Data",
             # "I:/SCIENCE-NEXS-NyMetabolomics/Projects/Tomato Foodball/Data"
              "I:/SCIENCE-NEXS-NyMetabolomics/Projects/PRIMA projects/D-AA analysis/Dataset1-plate1+2.pro/Data"
             )







out_file <- "I:/SCIENCE-NEXS-NyMetabolomics/Projects/raw_filelist.txt"


files <- list.files(folders, "\\.raw$", full.names = TRUE, recursive = TRUE, include.dirs = TRUE)


files <- gsub("I:/SCIENCE-NEXS-NyMetabolomics/Projects/", "", files)


files <- files %>% gsub("/","\\\\", .) %>% paste0('"', ., '"')


old_files <- readLines(out_file)

files <- files[!(files %in% old_files)]



if(length(files)!=0) cat(files, file = out_file, sep="\n", append=TRUE)

















# from inside docker
files <- list.files(folders, "\\.raw$", full.names = TRUE, recursive=TRUE, include.dirs=TRUE)
files %>%  gsub("^/data/","", .) %>% gsub("/","\\\\", .)  %>% paste0('"', ., '"') %>% writeLines( "/data/list_raw_files.txt")


