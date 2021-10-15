folders <- c("I:/SCIENCE-NEXS-NyMetabolomics/Projects/PRIMA/In vivo study/Metabolomics+AA/mzML",
             "I:/SCIENCE-NEXS-NyMetabolomics/Projects/Marlou Dirks.pro/First run/mzML"
             )

out_file <- "I:/SCIENCE-NEXS-NyMetabolomics/Projects/mzML_filelist.txt"


files <- list.files(folders, "\\.mzML$", full.names = TRUE)


files <- gsub("I:/SCIENCE-NEXS-NyMetabolomics/Projects/", "/data/", files)


old_files <- readLines(out_file)

files <- files[!(files %in% old_files)]



if(length(files)!=0) cat(files, file = out_file, sep="\n", append=TRUE)