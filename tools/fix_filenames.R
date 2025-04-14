library(dplyr)
library(tidyr)
library(purrr)
library(glue)
library(lubridate)
library(Hmisc)
library(tools)
library(MetabolomiQCsR)
#set_QC4Metabolomics_settings_from_file("settings_remote.env")


mzML2mode <- function(file, by_lines = 100L, max_rounds = 10L ) {
  
  path <- file %>% normalizePath
  
  round <- 1L
  output <- vector( mode = "character", length = 1 )
  out_round = ""
  while( !grepl( 'accession="MS:1000130"|accession="MS:1000129"', output)  & round <= max_rounds ) {
    out_round <- readr::read_lines(path, skip = by_lines*(round-1), n_max =by_lines )
    output <- paste0(c(output, out_round), collapse="\n")
    round <- round + 1L
  }
  
  
  if(!grepl( 'accession="MS:1000130"|accession="MS:1000129"', output)) return(NA)
  

  if(grepl( 'accession="MS:1000130"', output)){  
    out <- gsub('.*<cvParam cvRef=\"MS\" accession=\"MS:1000130\" name=\"(.*?)\" value=\"\"/>.*', "\\1", output) 
    
    return(out)
  }
  
  if(grepl( 'accession="MS:1000129"', output)){  
    out <- gsub('.*<cvParam cvRef=\"MS\" accession=\"MS:1000129\" name=\"(.*?)\" value=\"\"/>.*', "\\1", output) 
    
    return(out)
  }
    
  
}





# read known files
out_file <- "/data/mzML_filelist.txt"

# read existing list
mz_files <- readLines(out_file)


# parse
file_tbl_bad <- tibble(path = mz_files) %>% 
                mutate(path = gsub("/data/","I:/SCIENCE-NEXS-NyMetabolomics/Projects/", path)) %>% 
                mutate(filename = sub("\\.[^.]*$", "", path)) %>% #remove extension
                mutate(filename = basename(filename)) %>%
        
                mutate(info = map(filename, ~ parse_filenames(.x, as.character(Sys.getenv("QC4METABOLOMICS_module_FileInfo_mask"))))) %>%
                select(-filename) %>% 
                unnest(info) %>% 
                filter(FLAG)


# get first with bad filenames
sort(table(gsub("(.*)/.*$","\\1",file_tbl_bad$path)))


