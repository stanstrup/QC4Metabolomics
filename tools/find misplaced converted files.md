```r
# find misplaced converted files
library(dplyr)
library(purrr)
Sys.time()
mzMLdirs <- system('find "/data" -type d -iname mzML', intern = TRUE)

mzMLfiles <- list.files(mzMLdirs, "*.mzML$", recursive = TRUE, full.names = TRUE)

mzMLfiles_info <- file.info(mzMLfiles) %>% 
                    as_tibble %>% 
                    bind_cols(tibble(files = mzMLfiles, dir = dirname(files)),.) %>% 
                    mutate(cmd=paste0('find "',dir,'/.."',' -maxdepth 2 -type d -name ',gsub(".mzML",".raw",basename(files)))) %>% 
                    mutate(raw_file = map(cmd,system, intern = TRUE)) %>% 
                    mutate(raw_exist = map_lgl(raw_file, ~length(..1)>0))

# delete files where there is no .raw one level down
mzMLfiles_info %>% 
    filter(ctime>as.POSIXct(as.Date("2019-09-01")), mtime>as.POSIXct(as.Date("2019-09-01"))) %>% 
    filter(!raw_exist) %>% 
    pull(files) %>% 
    file.remove()

Sys.time()
```

