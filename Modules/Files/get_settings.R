
ini <- MetabolomiQCsR.env$general$settings_file %>% read.ini



#### Read ini file data into environment

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
rm(ini)
