## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, fig.align = "center", dev='svg')

## ----libraries, message=FALSE, warning = FALSE---------------------------
library(xcms)
library(MetabolomiQCsR)
library(purrr)
library(dplyr)
library(magrittr)
library(chemhelper)
library(massageR)
library(RColorBrewer)
library(heatmaply)

## ----read files----------------------------------------------------------
file <- "Z:/_Data/LIP1/0036_SevaMeal/mzML/0036_LIP1p_20160201_034_2_1_1.mzML"
raw <- xcmsRaw(file, profstep = 0)

raw

## ----find contaminants---------------------------------------------------
contaminants <- EIC_contaminants(raw, min_int = 1E4)

contaminants

## ----plot EIC------------------------------------------------------------
plot_chrom(contaminants$EIC[[20]], RT_col = "scan_rt", Intensity_col = "intensity")

## ----annotation----------------------------------------------------------

cont_list <- get_cont_list("positive") %>% extract2(1)

cont_names <- db.comp.assign(   mz = contaminants$mz,
                                rt = rep(0,nrow(contaminants)),
                                comp_name_db = with(cont_list, paste0(`Compound ID or species`," (",`Ion type`,")")  ),
                                mz_db = cont_list$`Monoisotopic ion mass (singly charged)`,
                                rt_db = rep(0,nrow(cont_list)),
                                mzabs=0.01,ppm=15,
                                ret_tol=Inf
                            ) %>% 
              data_frame(name = .)
 
contaminants %<>% bind_cols(cont_names)
 
contaminants

## ----EIC correlations matrix---------------------------------------------
corr <- map(contaminants$EIC, ~ .x$intensity) %>% do.call(cbind,.) %>% cor

## ----dendorgrams---------------------------------------------------------
z <- heat.clust(corr,
                scaledim =    "none", 
                zlim     =    c(-Inf,Inf),
                zlim_select = "",
                reorder  =    c("column","row"),
                scalefun =    function(x) x,
                distfun =     function(x) dist(x, method="euclidean"),
                hclustfun =   function(x) hclust(x, method="complete")
)

## ----interactive heatmap, fig.height = 8, fig.width = 9.5----------------
# row/colnames need to be unique
colnames(z$data) <- contaminants %>%    mutate(name = paste0(name,", ",round(mz,4))) %>% 
                                        extract2("name") %>% 
                                        make.unique(sep="_")

rownames(z$data) <- colnames(z$data)


heatmaply(z$data,
                   Rowv=z$Rowv,
                   Colv=z$Colv,
                   symm=TRUE,
                   scale="none",
                   colors=rev(colorRampPalette(brewer.pal(10, "RdBu"))(40)),
                   column_text_angle = 45
          ) %>% 
layout(margin = list(l = 300, b = 150)) # fix cut of labels


