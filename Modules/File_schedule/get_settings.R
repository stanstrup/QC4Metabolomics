setwd("../")
library(magrittr)
library(rlist)
library(ini)
library(MetabolomiQCsR)
setwd("File_schedule")


# search locations
ini_file <- c("./MetabolomiQCs.conf", # if file in working dir use that
              "../../MetabolomiQCs.conf", # two folder back
              "~/MetabolomiQCs.conf", # if file in home folder
              system.file("extdata", "MetabolomiQCs.conf", package = "MetabolomiQCsR") # If no file found use the one from the package
)


# check if we can find any config file at all
if(all(!file.exists(ini_file))) stop("No MetabolomiQCs.conf found.\n
                                     This should not happen since the packages comes with a default configuration file.")


# Get the first of the module_Files in the above list
ini_file <- ini_file[file.exists(ini_file)][1]

# read the ini file
message(paste0("Using MetabolomiQCsR configuration file in: ",normalizePath(ini_file)))
ini <- read.ini(normalizePath(ini_file))



#### Read ini file data into environment

MetabolomiQCsR.env$module_File_schedule$enabled_modules  <- ini %>%
                                                            list.match("module_.*") %>% 
                                                            list.filter(file_schedule == TRUE & enabled == TRUE) %>%
                                                            names


# cleanup
rm(ini, ini_file)
