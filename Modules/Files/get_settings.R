setwd("../")
library(stringr)
library(ini)
library(MetabolomiQCsR)
setwd("Files")


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

MetabolomiQCsR.env$module_Files$base                              <- ini$module_Files$base %>% as.character
MetabolomiQCsR.env$module_Files$include_ext                       <- ini$module_Files$include_ext %>% as.character
MetabolomiQCsR.env$module_Files$include_path                      <- ini$module_Files$include_path %>% as.character
MetabolomiQCsR.env$module_Files$exclude_path                      <- ini$module_Files$exclude_path %>% as.character

MetabolomiQCsR.env$module_Files$mask                              <- ini$module_Files$mask     %>% as.character
MetabolomiQCsR.env$module_Files$datemask                          <- ini$module_Files$datemask %>% as.character

MetabolomiQCsR.env$module_Files$mode_from_other_field             <- ini$module_Files$mode_from_other_field            %>% as.logical
MetabolomiQCsR.env$module_Files$mode_from_other_field_which       <- ini$module_Files$mode_from_other_field_which      %>% as.character
MetabolomiQCsR.env$module_Files$mode_from_other_field_pos_trigger <- ini$module_Files$mode_from_other_field_pos_trigger %>% as.character
MetabolomiQCsR.env$module_Files$mode_from_other_field_neg_trigger <- ini$module_Files$mode_from_other_field_neg_trigger %>% as.character

# cleanup
rm(ini, ini_file)
