shinyServer(function(input, output, session) {

  
  db_tables <- paste0("SELECT table_name
        FROM information_schema.tables
        WHERE table_type='BASE TABLE'
        AND table_schema = '",Sys.getenv("MYSQL_DATABASE"),"'"
       ) %>%  
  dbGetQuery(pool,.) 
  
  validate(need(nrow(db_tables)>0, "No tables in the DB. Probably not done initializing."))

  
  
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
													 
	  tags$div(id = "inline", selectInput("global_instruments_input", 
																   label = "Instruments", 
																   choices  = global_instruments_available(),
																   selected = global_instruments_available(),
																   multiple = TRUE
																 ))

	})


		global_instruments_input_react <- reactive(input$global_instruments_input)

		
    # Modules
    lapply(seq_along(module_names), 
           function(i){ callModule(get(module_names[i]), paste0("name",i), global_instruments_input = global_instruments_input_react)
                      }
           )

})



