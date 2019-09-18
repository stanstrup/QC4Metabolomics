shinyServer(function(input, output, session) {

	# Get available instrument
	global_instruments_available <-    reactive({    "
													 SELECT DISTINCT instrument
													 FROM file_info
													" %>% 
													dbGetQuery(pool,.) %>% 
													as.matrix %>% as.character
											   })


	# build the ui
	output$global_instruments_select_ui <- renderUI({
													 
													 selectInput("global_instruments_input", 
																   label = "Instruments", 
																   choices  = global_instruments_available(),
																   selected = global_instruments_available(),
																   multiple = TRUE
																 )

	})


    # Modules
    lapply(seq_along(module_names), 
           function(i){ callModule(get(module_names[i]), paste0("name",i))
                      }
           )

})



