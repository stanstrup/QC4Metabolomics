Admin <- function(input, output, session, global_instruments_input) {

    require(DBI)
    require(DT)
    require(dplyr)
    require(tidyr)
    require(purrr)
    require(fs)

    ns <- session$ns


    # -------------------------------------------------------------------------
    # Actions tab
    # -------------------------------------------------------------------------

    file_schedule_modules <- reactive({
        settings <- get_QC4Metabolomics_settings() %>%
            filter(!is.na(module)) %>%
            filter(grepl("_enabled$|_file_schedule$", name)) %>%
            mutate(type = gsub("^QC4METABOLOMICS_module_.*?_(.*)$", "\\1", name)) %>%
            pivot_wider(id_cols = "module", values_from = "value", names_from = "type")

        if (!all(c("enabled", "file_schedule") %in% names(settings)))
            return(character(0))

        settings %>%
            filter(as.logical(enabled) & as.logical(file_schedule)) %>%
            pull(module)
    })

    output$modules_to_reset_ui <- renderUI({
        checkboxGroupInput(
            ns("modules_to_reset"),
            label    = "Modules:",
            choices  = file_schedule_modules(),
            selected = file_schedule_modules()
        )
    })


    # Reset priority ----------------------------------------------------------
    observeEvent(input$reset_priority_btn, {

        # Whitelist: only accept values that are actually known module names
        selected <- intersect(input$modules_to_reset, file_schedule_modules())

        if (length(selected) == 0) {
            output$reset_priority_result <- renderPrint(cat("No modules selected.\n"))
            return()
        }

        results <- map_chr(selected, function(mod) {
            tryCatch({
                con <- poolCheckout(pool)
                on.exit({ try(dbRollback(con), silent = TRUE); poolReturn(con) }, add = TRUE)
                n <- dbExecute(con,
                    paste0("UPDATE file_schedule SET priority = 1",
                           " WHERE module = ", dbQuoteString(con, mod),
                           " AND priority = -1"))
                paste0(mod, ": ", n, " file(s) queued for reprocessing")
            }, error = function(e) {
                paste0(mod, ": ERROR - ", conditionMessage(e))
            })
        })

        output$reset_priority_result <- renderPrint(
            cat(paste(results, collapse = "\n"), "\n")
        )
    })


    # Remove missing files — confirm first ------------------------------------
    observeEvent(input$remove_missing_btn, {
        showModal(modalDialog(
            title = "Confirm: Remove Missing Files",
            p("This will permanently delete all database records for files that no longer exist on disk."),
            p(tags$strong("This cannot be undone.")),
            footer = tagList(
                modalButton("Cancel"),
                actionButton(ns("confirm_remove_missing_btn"),
                             "Remove Missing Files", class = "btn-danger")
            )
        ))
    })

    observeEvent(input$confirm_remove_missing_btn, {
        removeModal()

        result_msg <- tryCatch({

            file_tbl <- "SELECT path, file_md5 FROM files
                         UNION ALL
                         SELECT path, file_md5 FROM files_ignore" %>%
                dbGetQuery(pool, .) %>%
                as_tibble() %>%
                mutate(path = paste0(Sys.getenv("QC4METABOLOMICS_base"), "/", path),
                       file_found = file_exists(path))

            # A md5 may appear in both files and files_ignore (duplicate tracking).
            # Only remove it when ALL its paths are gone.
            found_md5 <- file_tbl %>% filter( file_found) %>% pull(file_md5) %>% unique()
            bad_md5   <- file_tbl %>% filter(!file_found) %>% pull(file_md5) %>% unique()
            bad_md5   <- setdiff(bad_md5, found_md5)

            if (length(bad_md5) == 0) {
                "No missing files found — nothing to remove."
            } else {
                tables_to_prune <- c("std_stat_data", "cont_data", "file_schedule",
                                     "file_info", "files_ignore", "files")

                con <- poolCheckout(pool)
                on.exit({ try(dbRollback(con), silent = TRUE); poolReturn(con) }, add = TRUE)
                dbBegin(con)

                n_deleted <- 0L
                for (tbl in tables_to_prune) {
                    for (md5 in bad_md5) {
                        n_deleted <- n_deleted + dbExecute(con,
                            paste0("DELETE FROM ", tbl, " WHERE file_md5 = '", md5, "'"))
                    }
                }

                dbCommit(con)

                paste0("Removed ", length(bad_md5), " missing file(s) (",
                       n_deleted, " total row(s) deleted across all tables).")
            }

        }, error = function(e) paste0("ERROR: ", conditionMessage(e)))

        output$remove_missing_result <- renderPrint(cat(result_msg, "\n"))
    })


    # Clean old log entries — confirm first -----------------------------------
    observeEvent(input$clean_log_btn, {
        showModal(modalDialog(
            title = "Confirm: Clean Old Log Entries",
            p("This will permanently delete all log entries older than 1 month."),
            p(tags$strong("This cannot be undone.")),
            footer = tagList(
                modalButton("Cancel"),
                actionButton(ns("confirm_clean_log_btn"),
                             "Clean Old Log", class = "btn-danger")
            )
        ))
    })

    observeEvent(input$confirm_clean_log_btn, {
        removeModal()

        result_msg <- tryCatch({
            con <- poolCheckout(pool)
            on.exit({ try(dbRollback(con), silent = TRUE); poolReturn(con) }, add = TRUE)
            dbBegin(con)
            n <- dbExecute(con,
                "DELETE FROM log WHERE time < DATE_SUB(NOW(), INTERVAL 1 MONTH)")
            dbCommit(con)
            paste0("Deleted ", n, " log entry/entries older than 1 month.")
        }, error = function(e) paste0("ERROR: ", conditionMessage(e)))

        output$clean_log_result <- renderPrint(cat(result_msg, "\n"))
    })


    # Ignored files table -----------------------------------------------------
    ignored_data <- eventReactive(input$refresh_ignored_btn, {
        tryCatch(
            dbGetQuery(pool, "SELECT path, file_md5 FROM files_ignore ORDER BY path") %>%
                as_tibble(),
            error = function(e) tibble(path = character(), file_md5 = character())
        )
    }, ignoreNULL = FALSE)

    output$ignored_files_tbl <- renderDataTable(
        datatable(
            ignored_data(),
            options = list(pageLength = 25, scrollX = TRUE),
            rownames = FALSE
        )
    )


    # -------------------------------------------------------------------------
    # Stats tab
    # -------------------------------------------------------------------------

    stats_data <- eventReactive(input$refresh_stats_btn, {
        tryCatch({
            list(
                n_files   = dbGetQuery(pool, "SELECT COUNT(*) AS n FROM files")$n,
                n_ignored = dbGetQuery(pool, "SELECT COUNT(*) AS n FROM files_ignore")$n,
                n_log     = dbGetQuery(pool, "SELECT COUNT(*) AS n FROM log")$n,
                schedule  = dbGetQuery(pool, "
                    SELECT module,
                        SUM(CASE WHEN priority >  0 THEN 1 ELSE 0 END) AS pending,
                        SUM(CASE WHEN priority <  0 THEN 1 ELSE 0 END) AS done,
                        COUNT(*) AS total
                    FROM file_schedule
                    GROUP BY module
                    ORDER BY module"),
                log_cats  = dbGetQuery(pool,
                    "SELECT cat, COUNT(*) AS n FROM log GROUP BY cat ORDER BY n DESC")
            )
        }, error = function(e) list(error = conditionMessage(e)))
    }, ignoreNULL = FALSE)

    output$stats_ui <- renderUI({

        s <- stats_data()

        if (!is.null(s$error))
            return(p(paste("Error:", s$error), style = "color:red"))

        sched_rows <- lapply(seq_len(nrow(s$schedule)), function(i) {
            tags$tr(
                tags$td(s$schedule$module[i]),
                tags$td(s$schedule$pending[i]),
                tags$td(s$schedule$done[i]),
                tags$td(s$schedule$total[i])
            )
        })

        log_rows <- lapply(seq_len(nrow(s$log_cats)), function(i) {
            tags$tr(
                tags$td(s$log_cats$cat[i]),
                tags$td(s$log_cats$n[i])
            )
        })

        tagList(

            fluidRow(
                column(4, wellPanel(
                    tags$h5("Files Registered"),
                    tags$h2(s$n_files)
                )),
                column(4, wellPanel(
                    tags$h5("Files Ignored"),
                    tags$h2(s$n_ignored)
                )),
                column(4, wellPanel(
                    tags$h5("Log Entries"),
                    tags$h2(s$n_log)
                ))
            ),

            h4("Processing Queue by Module"),
            if (nrow(s$schedule) == 0) {
                p("No entries in the processing queue.")
            } else {
                tags$table(class = "table table-striped table-condensed",
                    tags$thead(tags$tr(
                        tags$th("Module"),
                        tags$th("Pending"),
                        tags$th("Done"),
                        tags$th("Total")
                    )),
                    tags$tbody(sched_rows)
                )
            },

            h4("Log Entries by Category"),
            if (nrow(s$log_cats) == 0) {
                p("No log entries.")
            } else {
                tags$table(class = "table table-striped table-condensed",
                    tags$thead(tags$tr(tags$th("Category"), tags$th("Count"))),
                    tags$tbody(log_rows)
                )
            }

        )
    })


    # -------------------------------------------------------------------------
    # Edit tab
    # -------------------------------------------------------------------------

    allowed_fields <- c("instrument", "project")

    edit_preview_data <- reactiveVal(NULL)

    observeEvent(input$edit_preview_btn, {

        field    <- input$edit_field
        from_val <- trimws(input$edit_from)

        if (!field %in% allowed_fields || nchar(from_val) == 0) {
            output$edit_result <- renderPrint(cat("Please select a field and enter a value to search for.\n"))
            edit_preview_data(NULL)
            return()
        }

        result <- tryCatch({
            con <- poolCheckout(pool)
            on.exit(poolReturn(con))
            from_q <- dbQuoteString(con, from_val)
            rows <- dbGetQuery(con, paste0("
                SELECT f.path, fi.instrument, fi.project, fi.mode, fi.sample_id, fi.time_run
                FROM file_info fi
                JOIN files f USING (file_md5)
                WHERE fi.", field, " = ", from_q, "
                ORDER BY f.path
            ")) %>% as_tibble()
            list(rows = rows, msg = paste0(nrow(rows), " file(s) match ", field, " = \"", from_val, "\""))
        }, error = function(e) {
            list(rows = NULL, msg = paste0("ERROR: ", conditionMessage(e)))
        })

        output$edit_result <- renderPrint(cat(result$msg, "\n"))
        edit_preview_data(result$rows)
    })

    output$edit_preview_tbl <- renderDataTable({
        req(edit_preview_data())
        datatable(
            edit_preview_data(),
            rownames = FALSE,
            options  = list(pageLength = 25, scrollX = TRUE)
        )
    })

    observeEvent(input$edit_apply_btn, {

        field    <- input$edit_field
        from_val <- trimws(input$edit_from)
        to_val   <- trimws(input$edit_to)

        if (!field %in% allowed_fields || nchar(from_val) == 0 || nchar(to_val) == 0) {
            output$edit_result <- renderPrint(cat("Please fill in all fields before applying.\n"))
            return()
        }

        result <- tryCatch({
            con <- poolCheckout(pool)
            on.exit({ try(dbRollback(con), silent = TRUE); poolReturn(con) }, add = TRUE)
            from_q <- dbQuoteString(con, from_val)
            to_q   <- dbQuoteString(con, to_val)
            dbBegin(con)
            n <- dbExecute(con,
                paste0("UPDATE file_info SET ", field, " = ", to_q,
                       " WHERE ", field, " = ", from_q))
            dbCommit(con)
            edit_preview_data(NULL)
            paste0("Updated ", n, " file(s): ", field, " \"", from_val, "\" → \"", to_val, "\"")
        }, error = function(e) paste0("ERROR: ", conditionMessage(e)))

        output$edit_result <- renderPrint(cat(result, "\n"))
    })

}
