
#' Plot chromatogram
#'
#' @param tbl tbl with retention time and intensity to plot
#' @param RT_col Name of the rentention time column
#' @param Intensity_col  Name of the intensity column
#'
#' @return a \code{\link{ggplot}} object.
#' @export
#' 
#' @importFrom ggplot2 ggplot aes_string geom_line geom_hline
#' @importFrom ggplot2 labs scale_y_continuous expand_limits
#' @importFrom ggplot2 theme theme_bw element_blank element_line element_text
#' @importFrom scales scientific
#'
#' 

plot_chrom <- function(tbl, RT_col = "RT", Intensity_col = "Intensity"){
    
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
        theme(axis.line.x = element_line(color = "black", size = 0.5),
              axis.line.y = element_line(color = "black", size = 0.5)) + 
        labs(x="Retention time (min)", y="Intensity (counts)") +
        theme(axis.title = element_text(size = 16,face = "bold")) +
        scale_y_continuous(labels = scientific) +
        expand_limits(y = 0) +
        geom_hline(yintercept = 0, size = 0.5)
    
}




#' Bar plot of contaminants
#'
#' @param data tbl with the contamination amounts
#' @param title Plot title
#' @param x_var Column name that holds the compound/contaminant names
#' @param y_var Column name that holds the compound/contaminant values
#'
#' @return a \code{\link{ggplot}} object.
#' @export
#' 
#' @importFrom ggplot2 ggplot aes_string geom_bar
#' @importFrom ggplot2 ggtitle margin labs scale_y_continuous
#' @importFrom ggplot2 theme_classic theme element_text element_blank
#' @importFrom scales scientific
#' @importFrom magrittr extract2
#' @importFrom dplyr slice %>%
#'

plot_contaminants <- function(data, title, x_var = "comp_name", y_var = "EIC_median"){
    
                        sort_ord <- data %>% extract2(y_var) %>% order(decreasing = TRUE)
                        data[, x_var] <- factor(data %>% extract2(x_var) %>% as.character , 
                                                data %>% slice(sort_ord) %>% extract2(x_var) %>% as.character %>% unique
                                                )
    
                        
                        ggplot(data=data, aes_string(x = x_var, y = y_var)) + 
                        geom_bar(stat = "identity",fill="black") +
                        theme_classic() +
                        theme(axis.text.x = element_text(hjust=1,size = 10, angle = 90, vjust = 0.5)) +
                        theme(axis.title = element_text(size = 16,face = "bold")) +
                        theme(axis.ticks=element_blank()) +
                        ggtitle(as.character(title)) +
                        theme(plot.title = element_text(margin=margin(b = 50),face="bold",size=28)) +
                        labs(x="Contaminants", y="Median EIC") +
                        scale_y_continuous(labels=scientific)
                        
}
