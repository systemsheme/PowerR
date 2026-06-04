#' Launch the PowerR Shiny application
#'
#' @description
#' Starts the PowerR Shiny app in a browser. The app is shipped inside the
#' installed package at \code{inst/app/}; when the package is installed via
#' \code{remotes::install_github("systemsheme/PowerR")}, this function
#' locates the bundled app via \code{\link[base]{system.file}} and hands it
#' to \code{\link[shiny]{runApp}}.
#'
#' @param ... Forwarded to \code{\link[shiny]{runApp}} (e.g. \code{port},
#'   \code{launch.browser}, \code{host}).
#'
#' @return Invisibly, the value returned by \code{shiny::runApp()} (the
#'   function blocks until the app stops).
#' @export
#'
#' @examples
#' \dontrun{
#'   PowerR::run_app()
#'   # or pick a specific port:
#'   PowerR::run_app(port = 4567, launch.browser = FALSE)
#' }
run_app <- function(...) {
  app_dir <- system.file("app", package = "PowerR")
  if (!nzchar(app_dir)) {
    stop("Could not locate PowerR's bundled app directory. ",
         "Reinstall with: remotes::install_github(\"systemsheme/PowerR\")",
         call. = FALSE)
  }
  shiny::runApp(app_dir, ...)
}
