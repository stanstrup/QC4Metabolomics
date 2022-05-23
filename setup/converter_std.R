library(purrr)

basedir <- "/data"

message("Starting conversion at: ", Sys.time())

# files <- list.files(basedir, recursive = TRUE, include.dirs = TRUE, pattern = "\\.raw$", full.names = TRUE)

files <- readLines(paste0(basedir,"/","raw_filelist.txt"))
files <- paste0(basedir,"/",files)
files <- gsub("\"","",files)
files <- gsub("\\\\","/",files)
files <- trimws(files)


# remove files that don't exist (anymore)
file_exist <-  file.exists(files)
files <- files[file_exist]




outdir <- paste0(dirname(files), Sys.getenv("msconvert_outdir_prefix"))


# remove files that have already been converted
files_b <- basename(files)
files_out <- paste0(outdir,"/",gsub(".raw$","",files_b),".mzML")

file_exist <-  file.exists(files_out)

files <- files[!file_exist]
outdir <- outdir[!file_exist]
files_out <- files_out[!file_exist]



# if there are new files do the conversion
if(length(files)!=0){
  
  sapply(unique(outdir), function(x) dir.create(x, recursive = TRUE, showWarnings = FALSE))
  
  cmd <- paste0('wine msconvert "',files,'" ', gsub("\\\\","",Sys.getenv("msconvert_args")), ' --outdir "',outdir,'" && echo "',files_out,'" >> "',basedir,'"/mzML_filelist.txt')
  
  sapply(cmd, possibly(system, "FAILED TO CONVERT"))
  
}
