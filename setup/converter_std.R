message("Starting conversion at: ", Sys.time())

files <- list.files("/data", recursive = TRUE, include.dirs = TRUE, pattern = ".raw", full.names = TRUE)

outdir <- paste0(dirname(files), Sys.getenv("msconvert_outdir_prefix"))



# remove files that already exist
files_b <- basename(files)
files_out <- paste0(outdir,"/",gsub(".raw$","",files_b),".mzML")
file_exist <-  file.exists(files_out)
files <- files[!file_exist]
outdir <- outdir[!file_exist]


# if there are new files do the conversion
if(length(files)!=0){
  
  sapply(unique(outdir), function(x) dir.create(x, recursive = TRUE, showWarnings = FALSE))
  
  cmd <- paste0('wine msconvert "',files,'" ', Sys.getenv("msconvert_args"), ' --outdir "',outdir,'"')
  
  sapply(cmd, system)
  
}
