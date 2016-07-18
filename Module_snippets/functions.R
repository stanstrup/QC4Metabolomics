# Get contamination list for a vector of polarities -----------------------

# relies on the QC4Metabolomics.env being found globally

get_cont_list <- function(polarity,type) {
    require(magrittr)
    require(dplyr)
    require(purrr)
    library(readr)
    library(RCurl)
    
    polarity_un <- unique(polarity)
    
    if(type=="URL"){
    cont_list <- QC4Metabolomics.env$target_cont$cont_list$loc %>% 
        {data_frame(polarity = names(.),loc = as.character(.))} %>% 
        filter(polarity %in% polarity_un) %>% 
        mutate(cont_list = map_chr(loc, getURL)) %>% 
        mutate(cont_list = map(cont_list, read_tsv))
    }
    
    out <- polarity %>% 
        {data_frame(polarity=polarity)} %>% as.tbl %>% 
        left_join(cont_list, by="polarity") %>% 
        extract2("cont_list")
    
    return(out)
}




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





# function to make TIC from raw -------------------------------------------

get_TIC <- function(xraw, TIC_exclude_mz = NULL, TIC_exclude_ppm = 30){
    
    tic <- xraw %>% {data.frame(RT = .@scantime/60 , Intensity = .@tic)} %>% as.tbl
    
    # if we don't need to exclude anything from the TIC return as is
    if(is.null(TIC_exclude_mz)){
        return(tic)
    }
    
    
    # get EICs for all things to exclude and sum them
    xraws <- xraw %>% list %>% rep(length(TIC_exclude_mz)) %>% data_frame(raw = .)
    
    
    EIC_ex <- TIC_exclude_mz %>% data_frame(mz = .) %>% 
        mutate(mz_lower = mz-((TIC_exclude_ppm)/1E6)*mz, mz_upper = mz+((TIC_exclude_ppm)/1E6)*mz) %>% # make mz interval for use for the EIC
        bind_cols(xraws) %>% 
        get_EICs %>% 
        extract2("EIC") %>% 
        bind_cols %>% 
        setNames(.,make.names(names(.),unique=TRUE)) %>% 
        select(dplyr::contains("intensity")) %>% 
        transmute(EIC_sum = rowSums(.)) %>% 
        extract2("EIC_sum")
    
    
    # subtract sum of EICs from TIC
    tic %<>% mutate(Intensity = Intensity - EIC_ex)
    
    return(tic)
    
}



plot_TIC <- function(tbl, RT_col = "RT", Intensity_col = "Intensity"){
    
    ggplot(data=tbl,aes_string(x = RT_col, y = Intensity_col)) + 
        geom_line(size=0.2) +
        theme_bw() +
        theme(
            plot.background = element_blank()
            ,panel.grid.major = element_blank()
            ,panel.grid.minor = element_blank()
            ,panel.border = element_blank()
        ) +
        #draws x and y axis line
        theme(axis.line.x = element_line(color="black", size = 0.5),
              axis.line.y = element_line(color="black", size = 0.5)) + 
        labs(x="Retention time (min)", y="Intensity (counts)") +
        theme(axis.title = element_text(size = 16,face = "bold")) +
        scale_y_continuous(label=scientific) +
        expand_limits(x = 0, y = 0) +
        geom_hline(yintercept=0, size=0.5)
    
}
