require(ini)
require(dplyr)
require(stringr)

ini <- read.ini("settings.ini")

## When/if this in a package we need to use <<- instead of <-
QC4Metabolomics.env                                         <- new.env()
QC4Metabolomics.env$target_cont$EIC_ppm                     <- ini$target_cont$EIC_ppm                 %>% as.numeric
QC4Metabolomics.env$target_cont$cont_list$cont_list_type    <- ini$target_cont$cont_list_type          %>% as.character
QC4Metabolomics.env$target_cont$cont_list$loc$positive      <- ini$target_cont$cont_list_loc_positive  %>% as.character
QC4Metabolomics.env$target_cont$cont_list$loc$unknown       <- ini$target_cont$cont_list_loc_unknown   %>% as.character
QC4Metabolomics.env$target_cont$cont_list$loc$negative      <- ini$target_cont$cont_list_loc_negative  %>% as.character
QC4Metabolomics.env$TIC$TIC_exclude                         <- ini$visualization$TIC_exclude %>% str_split(",") %>% unlist %>% as.numeric
QC4Metabolomics.env$TIC$TIC_exclude_ppm                     <- ini$visualization$TIC_exclude_ppm %>% as.numeric
rm(ini)
