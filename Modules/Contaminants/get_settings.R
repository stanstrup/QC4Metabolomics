
ini <- MetabolomiQCsR.env$general$settings_file %>% read.ini



#### Read ini file data into environment

MetabolomiQCsR.env$Contaminants$EIC_ppm                     <- ini$module_Contaminants$EIC_ppm                 %>% as.numeric
MetabolomiQCsR.env$Contaminants$cont_list$cont_list_type    <- ini$module_Contaminants$cont_list_type          %>% as.character
MetabolomiQCsR.env$Contaminants$cont_list$loc$positive      <- ini$module_Contaminants$cont_list_loc_positive  %>% as.character
MetabolomiQCsR.env$Contaminants$cont_list$loc$unknown       <- ini$module_Contaminants$cont_list_loc_unknown   %>% as.character
MetabolomiQCsR.env$Contaminants$cont_list$loc$negative      <- ini$module_Contaminants$cont_list_loc_negative  %>% as.character


# cleanup
rm(ini)
