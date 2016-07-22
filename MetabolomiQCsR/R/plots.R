
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
