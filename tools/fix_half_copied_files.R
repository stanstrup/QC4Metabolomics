library(dplyr)
library(tidyr)
library(purrr)
library(fs)
library(glue)

# Find files --------------------------------------------------------------
files <- tibble(path = c(
                              #list.files("I:/SCIENCE-NEXS-NyMetabolomics/Projects/M237 PRIMA/", "\\.raw$", recursive = TRUE, include.dirs = TRUE, full.names = TRUE),
                              list.files("I:/SCIENCE-NEXS-NyMetabolomics/Projects/M237 PRIMA DDA/", "\\.raw$", recursive = TRUE, include.dirs = TRUE, full.names = TRUE),
                              list.files("I:/SCIENCE-NEXS-NyMetabolomics/Projects/PrimaFecal/", "\\.raw$", recursive = TRUE, include.dirs = TRUE, full.names = TRUE)
                          )
              ) %>% 
         filter(grepl(".*NOQC_from_._drive.*\\.raw$", path))


# Figure source -----------------------------------------------------------
files <- files %>% 
            mutate(file = basename(normalizePath(path))) %>% 
            mutate(source = if_else(grepl("from_c_drive", path),"c",NA_character_)) %>% 
            mutate(source = if_else(grepl("from_i_drive", path),"i",source))




# Who are good and bad ----------------------------------------------------
# if there is only one version of the file we assume it is good
good <- files %>% nest(data = -file) %>% mutate(n = map_int(data, nrow)) %>% filter(n==1)

bad <- files %>% nest(data = -file) %>% mutate(n = map_int(data, nrow)) %>% filter(n>1)


# Copy good ---------------------------------------------------------------
good %>% 
  unnest(data) %>% 
  mutate(destination = gsub("NOQC_from_._drive", "fixed", path)) %>% 
  {walk2(.$path, .$destination, dir_copy)}


# Figure what to copy from where for the bad files ------------------------
# get all "subfiles"
bad <- bad %>% 
        unnest(data) %>%  
        mutate(subfiles = map(path, ~list.files(..1, full.names = TRUE))) %>% 
        unnest(subfiles)


# Copy unique subfiles
bad_unique <- bad %>% 
                mutate(subfiles_base = basename(subfiles)) %>% 
                select(-n) %>% 
                nest(data = -c(file, subfiles_base)) %>% 
                mutate(n = map_int(data, nrow)) %>% 
                filter(n==1) %>% 
                unnest(data) %>% 
                mutate(destination = gsub("NOQC_from_._drive", "fixed", subfiles))



dir_create(unique(dirname(bad_unique$destination)), recurse = TRUE)

bad_unique %>% {walk2(.$subfiles, .$destination, file.copy)}





# when not unique take from c, but not _INLET.INF
bad_nonunique <- bad %>% 
                    mutate(subfiles_base = basename(subfiles)) %>% 
                    select(-n) %>% 
                    nest(data = -c(file, subfiles_base)) %>% 
                    mutate(n = map_int(data, nrow)) %>% 
                    filter(n!=1) %>% 
                    unnest(data) %>% 
                    mutate(destination = gsub("NOQC_from_._drive", "fixed", subfiles))


bad_nonunique %>%   filter(source == "c") %>% 
                    filter(!grepl("_INLET.INF", subfiles_base)) %>% 
                    {walk(unique(dirname(.$destination)), dir.create, recursive = TRUE, showWarnings = FALSE)}


bad_nonunique %>%   filter(source == "c") %>% 
                    filter(!grepl("_INLET.INF", subfiles_base)) %>% 
                    {walk2(.$subfiles, .$destination, file.copy, overwrite  = TRUE, recursive = TRUE)}







# patch _INLET.INF (i + c)

fun_copy <- function(x, n){
i <- x %>% filter(source == "i") %>% pull(subfiles)
c <- x %>% filter(source == "c") %>% pull(subfiles)
d <- x %>% pull(destination) %>% unique

# cat("\n")
# cat(n)
# cat("\n")
# cat(dirname(d))
d %>% dirname() %>% unique %>% dir.create(recursive = TRUE)


temp <<- glue('copy /b "{i}" + "{c}" "{d}"') %>% gsub("/", "\\\\", .) %>%
  gsub("\\\\\\\\", "\\\\", .) %>% gsub("\\b", "/b", ., fixed = TRUE) %>%
  system("cmd.exe", input = ., intern = TRUE)
}


bad_nonunique %>% 
          filter(grepl("_INLET.INF", subfiles_base)) %>% 
          nest(data = -c(file, subfiles_base)) %>% 
          {walk2(.$data, 1:length(.$data), fun_copy)}




