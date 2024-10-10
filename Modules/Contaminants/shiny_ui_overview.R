
# logifySlider javascript function
# modified from http://stackoverflow.com/questions/30502870/shiny-slider-on-logarithmic-scale
JS.logify <-
"
// function to logify a sliderInput
function logifySlider (sliderId, sci = false) {
  if (sci) {
    // scientific style
    $('#'+sliderId).data('ionRangeSlider').update({
      'prettify': function (num) { return ('10<sup>'+num+'</sup>'); }
    })
  } else {
    // regular number style
    $('#'+sliderId).data('ionRangeSlider').update({
      'prettify': function (num) { return (Math.pow(10, num)); }
    })
  }
}"

input_css <- "
 .pro-select-parent .selectize-input {
    max-height: 10em;
    overflow-y: auto;
 }
"

tabPanel("Contaminations",
                            fluidPage(  tags$style(type='text/css', input_css),
                                        tags$head(tags$script(HTML(JS.logify))),
                                        tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode", function(message) { eval(message.value); });'))),
                                        
                                        fluidRow(
                                                    column(4,
                                                            uiOutput(ns("project_select_ui"), class="pro-select-parent"),
                                                            actionButton(ns("resetButton"), "Reset filters")
                                                           ),
                                                    column(1,uiOutput(ns("mode_select_ui"))),
                                                    column(2,
                                                               textInput(ns("sample_id"), "Sample ID", ""),
                                                               checkboxInput(ns("sample_id_inv"), label = "Inverse", value = FALSE),
                                                               helpText(HTML('<a href="https://www.tutorialspoint.com/mysql/mysql-regexps.htm">REGEXP</a>  supported.'))
                                                           ),
                                                    column(2,uiOutput(ns("file_date_range_ui")))
                                                ),
                            
                                        
                                        br(),br(),br(),
                                            
                                        tabsetPanel(
                                                      tabPanel("Overview",
                                                               br(),
                                                               fluidRow(
                                                                         column(2,
                                                                                    selectInput(ns("int_type"), "Selected intensity over chromatograms", choices = c(Max = "EIC_max", Median = "EIC_median", Mean = "EIC_mean"), selected=c(Median = "EIC_max"), multiple = FALSE)
                                                                                ),
                                                                         column(2,
                                                                                    uiOutput(ns("int_cutoff_ui"))
                                                                                )
                                                                        ),
                                                               br(),
                                                               div(style = "width: 1400px; margin:0 auto;",
                                                                        plotOutput(ns("heatmap"), height = "1000px")
                                                                  )
                                                               
                                                                
                                                               
                                                               
                                                              ),
                                                      
                                                      
                                                      
                                                      tabPanel("Time view",
                                                               br(),
                                                               fluidRow(
                                                                         column(2,
                                                                                    selectInput(ns("time_int"), "Selected intensity over chromatograms", choices = c(Max = "EIC_max", Median = "EIC_median", Mean = "EIC_mean"), selected=c(Median = "EIC_max"), multiple = FALSE)
                                                                                ),
                                                                         column(2,
                                                                                   uiOutput(ns("cont_select_ui")) 
                                                                                )
                                                                        ),
                                                               div(style = "width: 1000px; margin:0 auto;",
                                                                        plotlyOutput(ns("time_plot"), height = "700px")
                                                                  )
                                                               
                                                              ),
                                                      
                                                      
                                                      tabPanel("File screening",
                                                               br(),
                                                               fluidRow(
                                                                         column(2,
                                                                                    selectInput(ns("file_int"), "Selected intensity over chromatograms", choices = c(Max = "EIC_max", Median = "EIC_median", Mean = "EIC_mean"), selected=c(Median = "EIC_max"), multiple = FALSE)
                                                                                ),
                                                                         column(2,
                                                                                    uiOutput(ns("file_select_ui"))
                                                                                )
                                                                        ),
                                                               div(style = "width: 1400px; margin:0 auto;",
                                                                        plotlyOutput(ns("file_screen_plot"), height = "1400px")
                                                                  )
                                                               
                                                              ) 
                                                      
                                                  )
                                        
                                        
                                        
                                    )
        )
