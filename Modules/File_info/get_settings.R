
ini <- MetabolomiQCsR.env$general$settings_file %>% read.ini



#### Read ini file data into environment

MetabolomiQCsR.env$module_File_info$mask                              <- ini$module_File_info$mask     %>% as.character
MetabolomiQCsR.env$module_File_info$datemask                          <- ini$module_File_info$datemask %>% as.character

MetabolomiQCsR.env$module_File_info$mode_from_other_field             <- ini$module_File_info$mode_from_other_field            %>% as.logical
MetabolomiQCsR.env$module_File_info$mode_from_other_field_which       <- ini$module_File_info$mode_from_other_field_which      %>% as.character
MetabolomiQCsR.env$module_File_info$mode_from_other_field_pos_trigger <- ini$module_File_info$mode_from_other_field_pos_trigger %>% as.character
MetabolomiQCsR.env$module_File_info$mode_from_other_field_neg_trigger <- ini$module_File_info$mode_from_other_field_neg_trigger %>% as.character

# cleanup
rm(ini)
