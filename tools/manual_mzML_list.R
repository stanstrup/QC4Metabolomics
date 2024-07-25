library(dplyr)

folders <- c(c(#"I:/SCIENCE-NEXS-NyMetabolomics/Projects/Xiaotian/Xiaotian.pro/mzML",
               #"I:/SCIENCE-NEXS-NyMetabolomics/Projects/DAminoAcids/DAminoAcids.pro/mzML",
               "I:/SCIENCE-NEXS-NyMetabolomics/Projects/PRIMA projects"
             ))


# folders <- list.dirs("I:/SCIENCE-NEXS-NyMetabolomics/Projects/",recursive = FALSE) %>% 
#             {tibble(dir = ., file.info(.))} %>% 
#             arrange(desc(ctime)) %>% 
#             slice(1:10) %>% 
#             pull(dir)

out_file <- "I:/SCIENCE-NEXS-NyMetabolomics/Projects/mzML_filelist.txt"


# files <- list.files(folders, "\\.mzML$", full.names = TRUE)
files <- list.files(folders, "\\.mzML$", full.names = TRUE, recursive = TRUE)


files <- gsub("I:/SCIENCE-NEXS-NyMetabolomics/Projects/", "/data/", files)

# read existing list
old_files <- readLines(out_file)

# remove all-ready found files
files <- files[!(files %in% old_files)]


# write out list with new files
if(length(files)!=0) cat(files, file = out_file, sep="\n", append=TRUE)



# Alternatively to rewrite list with only working links -------------------
files_all <- unique(c(files, old_files))
files_all <- files_all %>% 
            gsub("/data/","I:/SCIENCE-NEXS-NyMetabolomics/Projects/", .) %>% 
            {files_all[file.exists(.)]}

# write out list
if(length(files_all)!=0) writeLines(files_all, out_file)

