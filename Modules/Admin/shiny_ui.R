AdminUI <- function(id) {

    require(DT)

    ns <- NS(id)

    tabPanel("Admin",

        fluidPage(

            h3("Administration"),

            tabsetPanel(

                # Actions tab --------------------------------------------------
                tabPanel("Actions",

                    br(),

                    wellPanel(
                        h4("Reprocess Files"),
                        p("Force the system to rerun a processing step on all files, even ones it has already processed. Useful after fixing a configuration error or updating reference data. Select which processing steps to rerun."),
                        uiOutput(ns("modules_to_reset_ui")),
                        br(),
                        actionButton(ns("reset_priority_btn"), "Reprocess Files", class = "btn-warning"),
                        br(), br(),
                        verbatimTextOutput(ns("reset_priority_result"))
                    ),

                    wellPanel(
                        h4("Remove Missing Files"),
                        p("Scans all files registered in the database and removes entries for files that no longer exist on disk. Run this after deleting or moving raw data files to keep the database in sync."),
                        actionButton(ns("remove_missing_btn"), "Remove Missing Files", class = "btn-danger"),
                        br(), br(),
                        verbatimTextOutput(ns("remove_missing_result"))
                    ),

                    wellPanel(
                        h4("Clean Old Log Entries"),
                        p("Removes log entries older than 1 month to keep the database from growing indefinitely."),
                        actionButton(ns("clean_log_btn"), "Clean Old Log", class = "btn-danger"),
                        br(), br(),
                        verbatimTextOutput(ns("clean_log_result"))
                    ),

                    wellPanel(
                        h4("Ignored Files"),
                        p("Files in this list are permanently excluded from all processing. They were automatically added when the system detected they contain no MS1 data. Use this list to review what has been excluded."),
                        actionButton(ns("refresh_ignored_btn"), "Reload Table"),
                        br(), br(),
                        dataTableOutput(ns("ignored_files_tbl"))
                    )

                ),

                # Stats tab ----------------------------------------------------
                tabPanel("Stats",

                    br(),
                    actionButton(ns("refresh_stats_btn"), "Refresh"),
                    br(), br(),
                    uiOutput(ns("stats_ui"))

                ),

                # Edit tab -----------------------------------------------------
                tabPanel("Edit",

                    br(),
                    p("Replace a metadata value across all files that match it.",
                      "Preview first to see which files will be affected before applying."),

                    wellPanel(
                        fluidRow(
                            column(3,
                                selectInput(ns("edit_field"), "Field",
                                            choices = c("instrument", "project"))
                            ),
                            column(4,
                                textInput(ns("edit_from"), "Replace this value")
                            ),
                            column(4,
                                textInput(ns("edit_to"), "With this value")
                            )
                        ),
                        fluidRow(
                            column(12,
                                actionButton(ns("edit_preview_btn"), "Preview"),
                                " ",
                                actionButton(ns("edit_apply_btn"), "Apply",
                                             class = "btn-warning")
                            )
                        )
                    ),

                    verbatimTextOutput(ns("edit_result")),
                    dataTableOutput(ns("edit_preview_tbl"))

                )

            )
        )
    )
}
