
# logifySlider javascript function
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



tabPanel("Contaminations",
                            fluidPage(  tags$head(tags$script(HTML(JS.logify))),
                                        tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode", function(message) { eval(message.value); });'))),
                                        
                                        
                                        fluidRow(
                                                    column(2,
                                                            uiOutput(ns("project_select_ui")),
                                                            actionButton(ns("resetButton"), "Reset filters")
                                                           ),
                                                    column(2,uiOutput(ns("mode_select_ui"))),
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
                                                               
                                                                
                                                               
                                                               
                                                              ) 
                                        )
                                        
                                        
                                        
                                    )
        )
