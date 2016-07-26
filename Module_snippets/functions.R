# gg contamination barplot to plotly --------------------------------------
# with fixed tooltip

cont_screen_gg2plotly <- function(x){
    require(magrittr)
    require(dplyr)
    require(plotly)
    
    gg <- plotly_build(x)
    
    gg$data[[1]]$text <- paste0("<b>Compound:</b> ",   x %>% extract2("data") %>% arrange(desc(EIC_median)) %>% extract2("comp_name") %>% as.character, "<br>",
                               "<b>EIC Median:</b> ", x %>% extract2("data") %>% arrange(desc(EIC_median)) %>% extract2("EIC_median") %>% round(0)
    )
    
    return(gg)
}




get_EICs <- function(tbl){
    require(xcms)
    require(purrr)
    require(plyr)
    
    
    tbl %>%     
        mutate(EIC   = pmap(list(raw,mz_lower,mz_upper),   function(raw,lower,upper) rawEIC(raw, as.matrix(data.frame(mzmin=lower,mzmax=upper)))   )) %>% # get the EICs
        mutate(EIC   = map(EIC,  ~ do.call(cbind.data.frame,.) %>% as.tbl  )) %>%     # EICs are lists. make nice data.frame
        mutate(EIC   = map2(EIC,raw, function(EIC,raw) mutate(EIC,scan_rt = raw@scantime[EIC$scan]/60)   )) %>% # convert scans to retention times
        mutate(EIC_median   = map_dbl(EIC,  ~ median(.$intensity)   )) %>%  # get the median intensity of each EIC
        mutate(EIC_mean     = map_dbl(EIC,  ~ mean(.$intensity)   )) %>%    # get the median intensity of each EIC
        mutate(EIC_sd       = map_dbl(EIC,  ~ sd(.$intensity)   )) %>%      # get the sd intensity of each EIC
        mutate(EIC_max      = map_dbl(EIC,  ~ max(.$intensity)   )) %>%     # get the max intensity of each EIC
        mutate(EIC_max      = map_dbl(EIC,  ~ max(.$intensity)   )) ->      # get the max intensity of each EIC
        out
    
    return(out)
    
}

