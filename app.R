# PowerR — simulation-based power analysis for experiment planning
# Run with: shiny::runApp() from this directory.

library(shiny)
library(bslib)
library(ggplot2)

# Load modules
source("R/power_ttest.R", local = TRUE)
source("R/power_proportions.R", local = TRUE)
source("R/power_anova.R", local = TRUE)
source("R/power_lda.R", local = TRUE)
source("R/power_survival.R", local = TRUE)
source("R/plot_helpers.R", local = TRUE)
source("R/tutorial.R", local = TRUE)

EXPERIMENTS <- c(
  "T-test (means)"                        = "ttest",
  "Two-proportion test (frequencies)"     = "proportions",
  "One-way ANOVA (>=3 groups)"            = "anova",
  "Limiting Dilution Analysis (LDA)"      = "lda",
  "Survival / log-rank (hazard ratio)"    = "survival"
)

aspect_ratio <- function(key) {
  switch(key,
         "wide_5_3"  = 5 / 3,
         "wide_4_3"  = 4 / 3,
         "wide_16_9" = 16 / 9,
         "std_3_2"   = 3 / 2,
         "square"    = 1,
         "tall_3_4"  = 3 / 4,
         5 / 3)
}

parse_numeric_vec <- function(txt) {
  if (is.null(txt) || !nzchar(trimws(txt))) return(numeric(0))
  bits <- unlist(strsplit(txt, "[,\\s]+", perl = TRUE))
  bits <- bits[nzchar(bits)]
  out <- suppressWarnings(as.numeric(bits))
  out[!is.na(out)]
}

BRAND_COLOR <- "#9D4844"  # Asiri Lab muted-brick red, sampled from the logo

powerr_header <- tags$div(
  class = "powerr-header",
  tags$span(
    class = "powerr-header-title",
    "PowerR — Simulation-based Power Analysis"
  ),
  tags$a(
    href = "https://www.systemshematology.org",
    target = "_blank", rel = "noopener",
    title = "Asiri Lab — Systems Hematology",
    `aria-label` = "Visit the Asiri Lab website",
    tags$img(
      src = "asiri-lab-logo.png",
      alt = "Asiri Lab",
      class = "powerr-header-logo"
    )
  )
)

powerr_header_css <- tags$head(tags$style(HTML(sprintf("
  /* Brand header */
  header.navbar, .navbar.navbar-static-top, .bslib-page-title,
  .bslib-page-navbar, body > .navbar {
    background-color: %s !important;
    border-bottom: none !important;
  }
  .powerr-header {
    display: flex; align-items: center; justify-content: space-between;
    width: 100%%; gap: 16px;
  }
  .powerr-header-title {
    color: #ffffff; font-weight: 600; font-size: 1.05em;
    letter-spacing: 0.2px;
  }
  .powerr-header-logo {
    height: 44px; width: 44px;
    object-fit: contain;
    display: block;
    transition: opacity 0.15s ease;
  }
  .powerr-header-logo:hover { opacity: 0.85; }
", BRAND_COLOR))))

ui <- page_sidebar(
  title = powerr_header,
  theme = bs_theme(bootswatch = "flatly"),

  powerr_header_css,

  sidebar = sidebar(
    width = 360,
    selectInput("experiment", "Experiment type", choices = EXPERIMENTS),

    numericInput("alpha", "Significance threshold (alpha)",
                 value = 0.05, min = 1e-6, max = 0.5, step = 0.005),
    numericInput("n_iter", "Monte Carlo iterations",
                 value = 500, min = 50, max = 20000, step = 100),
    numericInput("target_power", "Target power", value = 0.8,
                 min = 0.5, max = 0.999, step = 0.05),
    numericInput("seed", "Random seed (optional, blank = random)",
                 value = 42),
    textInput("n_range", "Sample sizes to evaluate (comma- or space-separated)",
              value = "3, 5, 8, 10, 15, 20, 25, 30"),

    hr(),
    selectInput(
      "plot_aspect", "Plot aspect ratio",
      choices = c(
        "Wide 5:3 (Prism default)" = "wide_5_3",
        "Wide 4:3"                 = "wide_4_3",
        "Wide 16:9"                = "wide_16_9",
        "Standard 3:2"             = "std_3_2",
        "Square 1:1"               = "square",
        "Portrait 3:4"             = "tall_3_4"
      ),
      selected = "wide_5_3"
    ),
    sliderInput("plot_height", "Plot size (height, px)",
                min = 300, max = 800, value = 460, step = 20),
    sliderInput("plot_font", "Axis / label font size (pt)",
                min = 10, max = 24, value = 16, step = 1),
    selectInput(
      "plot_border", "Plot border",
      choices = c(
        "None (Prism open axes)" = "none",
        "Black box"              = "black",
        "Gray box"               = "#888888",
        "Match palette (blue)"   = "#1F77B4",
        "Custom hex..."          = "custom"
      ),
      selected = "none"
    ),
    conditionalPanel(
      "input.plot_border == 'custom'",
      textInput("plot_border_color", "Border colour (hex or name)",
                value = "#1F77B4")
    ),
    selectInput(
      "x_label_angle", "X-axis tick label angle",
      choices = c("0° (horizontal)" = "0",
                  "30°"             = "30",
                  "45°"             = "45",
                  "90° (vertical)"  = "90"),
      selected = "0"
    ),
    selectInput(
      "x_tick_mode", "X-axis ticks",
      choices = c("Auto (pretty breaks, less clutter)" = "auto",
                  "One per simulated N (may cluster)"  = "all"),
      selected = "auto"
    ),

    # ----- T-test -----
    conditionalPanel(
      "input.experiment == 'ttest'",
      hr(),
      selectInput("tt_test", "Design",
                  choices = c("Two-sample" = "two_sample",
                              "Paired"     = "paired",
                              "One-sample" = "one_sample")),
      radioButtons("tt_effect_mode", "Effect size input",
                   choices = c("Cohen's d directly" = "cohens_d",
                               "Group means + SDs" = "means_sd"),
                   selected = "cohens_d"),
      conditionalPanel(
        "input.tt_effect_mode == 'cohens_d'",
        textInput("tt_d_vec", "Cohen's d (one or more values, comma-separated)",
                  value = "0.5, 0.8, 1.2")
      ),
      conditionalPanel(
        "input.tt_effect_mode == 'means_sd'",
        numericInput("tt_m1", "Mean, group 1", value = 0),
        numericInput("tt_m2", "Mean, group 2", value = 1),
        numericInput("tt_sd1", "SD, group 1", value = 1, min = 1e-9),
        numericInput("tt_sd2", "SD, group 2 (blank = same as group 1)",
                     value = NA, min = 0)
      ),
      selectInput("tt_alt", "Alternative",
                  choices = c("two.sided", "greater", "less")),
      checkboxInput("tt_var_equal", "Assume equal variances (two-sample)",
                    value = TRUE)
    ),

    # ----- Proportions -----
    conditionalPanel(
      "input.experiment == 'proportions'",
      hr(),
      numericInput("pr_p1", "Proportion, group 1 (p1)", value = 0.10,
                   min = 0, max = 1, step = 0.01),
      numericInput("pr_p2", "Proportion, group 2 (p2)", value = 0.30,
                   min = 0, max = 1, step = 0.01),
      selectInput("pr_test", "Test",
                  choices = c("Two-proportion z-test" = "prop_test",
                              "Fisher's exact"       = "fisher")),
      selectInput("pr_alt", "Alternative",
                  choices = c("two.sided", "greater", "less"))
    ),

    # ----- ANOVA -----
    conditionalPanel(
      "input.experiment == 'anova'",
      hr(),
      textInput("an_means", "Group means (comma-separated)",
                value = "0, 0.5, 1.0"),
      textInput("an_sds",
                "Common SD, or per-group SDs (comma-separated)",
                value = "1")
    ),

    # ----- LDA -----
    conditionalPanel(
      "input.experiment == 'lda'",
      hr(),
      textInput("lda_doses",
                "Doses (cells per injection, comma-separated)",
                value = "100, 1000, 10000, 100000"),
      radioButtons(
        "lda_mode", "Group specification",
        choices = c("Stem-cell frequencies (1/f) per group" = "frequency",
                    "Reference frequency + fold-change"     = "fold_change",
                    "Direct response probabilities per dose" = "direct_prob"),
        selected = "frequency"
      ),
      conditionalPanel(
        "input.lda_mode == 'frequency'",
        numericInput("lda_finv1", "Group 1: 1 stem cell per N cells (1/f1)",
                     value = 5000, min = 1),
        numericInput("lda_finv2", "Group 2: 1 stem cell per N cells (1/f2)",
                     value = 25000, min = 1)
      ),
      conditionalPanel(
        "input.lda_mode == 'fold_change'",
        numericInput("lda_finv_ref",
                     "Reference: 1 stem cell per N cells (1/f_ref)",
                     value = 5000, min = 1),
        numericInput("lda_fc", "Fold-change (group 2 is rarer by this factor)",
                     value = 5, min = 1e-6, step = 0.5)
      ),
      conditionalPanel(
        "input.lda_mode == 'direct_prob'",
        textInput("lda_p1", "Group 1 response probs (one per dose, in same order)",
                  value = "0.02, 0.18, 0.86, 0.99"),
        textInput("lda_p2", "Group 2 response probs (one per dose, in same order)",
                  value = "0.004, 0.04, 0.33, 0.98")
      ),
      helpText("Sample sizes above are mice per dose, per group.")
    ),

    # ----- Survival -----
    conditionalPanel(
      "input.experiment == 'survival'",
      hr(),
      numericInput("sv_hr", "Hazard ratio (group 2 vs 1)", value = 1.5,
                   min = 1e-3, step = 0.1),
      numericInput("sv_lambda", "Baseline event rate (group 1)",
                   value = 0.1, min = 1e-6, step = 0.01),
      numericInput("sv_accrual", "Accrual duration", value = 12, min = 0),
      numericInput("sv_followup", "Follow-up after accrual", value = 12, min = 0),
      numericInput("sv_dropout", "Dropout rate (0 = none)", value = 0, min = 0)
    ),

    hr(),
    actionButton("run", "Run power analysis", class = "btn-primary",
                 width = "100%"),
    helpText("Larger N ranges and iteration counts increase fidelity but slow the run.")
  ),

  navset_card_tab(
    nav_panel(
      "Power curve",
      uiOutput("summary_box"),
      div(style = "overflow:auto; padding:8px 4px;",
          uiOutput("plotUI")),
      div(
        style = "display:flex; gap:8px; flex-wrap:wrap; align-items:center;",
        downloadButton("dl_png", "PNG (300 DPI)"),
        downloadButton("dl_pdf", "PDF (vector)"),
        downloadButton("dl_svg", "SVG (vector)"),
        tags$small(
          style = "color:#666; margin-left:8px;",
          "PDF and SVG are vector — open in Illustrator, Inkscape, or Affinity for editing."
        )
      )
    ),
    nav_panel(
      "Results table",
      tableOutput("table"),
      downloadButton("dl_table", "Download results (CSV)")
    ),
    nav_panel(
      "About this method",
      uiOutput("method_doc")
    ),
    nav_panel(
      "Tutorial",
      tutorial_panel()
    )
  )
)

server <- function(input, output, session) {

  results <- eventReactive(input$run, {
    if (!is.na(input$seed)) set.seed(input$seed)
    n_range <- as.integer(parse_numeric_vec(input$n_range))
    n_range <- n_range[n_range > 0]
    validate(need(length(n_range) >= 1,
                  "Provide at least one positive sample size."))
    n_iter <- max(50L, as.integer(input$n_iter))
    alpha  <- input$alpha

    withProgress(message = "Running simulations...", value = 0, {
      switch(
        input$experiment,

        "ttest" = {
          if (input$tt_effect_mode == "cohens_d") {
            ds <- parse_numeric_vec(input$tt_d_vec)
            validate(need(length(ds) >= 1, "Provide at least one Cohen's d."))
            all_rows <- lapply(seq_along(ds), function(i) {
              incProgress(1 / length(ds),
                          detail = sprintf("d = %.3g", ds[i]))
              r <- power_ttest(test = input$tt_test, n_range = n_range,
                               effect_mode = "cohens_d", d = ds[i],
                               alpha = alpha, alternative = input$tt_alt,
                               var_equal = input$tt_var_equal,
                               n_iter = n_iter)
              r$group <- sprintf("d = %.3g", ds[i])
              r
            })
            do.call(rbind, all_rows)
          } else {
            sd2 <- if (is.na(input$tt_sd2)) input$tt_sd1 else input$tt_sd2
            r <- power_ttest(test = input$tt_test, n_range = n_range,
                             effect_mode = "means_sd",
                             m1 = input$tt_m1, m2 = input$tt_m2,
                             sd1 = input$tt_sd1, sd2 = sd2,
                             alpha = alpha, alternative = input$tt_alt,
                             var_equal = input$tt_var_equal,
                             n_iter = n_iter)
            r$group <- sprintf("d = %.3g", r$d[1])
            incProgress(1)
            r
          }
        },

        "proportions" = {
          r <- power_proportions(p1 = input$pr_p1, p2 = input$pr_p2,
                                 n_range = n_range, test = input$pr_test,
                                 alternative = input$pr_alt,
                                 alpha = alpha, n_iter = n_iter)
          r$group <- sprintf("p1=%.2g vs p2=%.2g", input$pr_p1, input$pr_p2)
          incProgress(1)
          r
        },

        "anova" = {
          means <- parse_numeric_vec(input$an_means)
          sds   <- parse_numeric_vec(input$an_sds)
          validate(need(length(means) >= 2, "Provide at least two means."))
          validate(need(length(sds) %in% c(1, length(means)),
                        "SD must be a single value or one per group."))
          r <- power_anova(means = means, sd = sds, n_range = n_range,
                           alpha = alpha, n_iter = n_iter)
          r$group <- sprintf("Cohen's f = %.3g", r$cohens_f[1])
          incProgress(1)
          r
        },

        "lda" = {
          doses <- parse_numeric_vec(input$lda_doses)
          validate(need(length(doses) >= 2,
                        "LDA needs at least two doses."))
          r <- switch(
            input$lda_mode,
            "frequency" = {
              validate(need(input$lda_finv1 > 0 && input$lda_finv2 > 0,
                            "1/f must be positive."))
              power_lda(doses = doses, mode = "frequency",
                        f1 = 1 / input$lda_finv1,
                        f2 = 1 / input$lda_finv2,
                        n_range = n_range, alpha = alpha, n_iter = n_iter)
            },
            "fold_change" = {
              validate(need(input$lda_finv_ref > 0 && input$lda_fc > 0,
                            "f_ref and FC must be positive."))
              power_lda(doses = doses, mode = "fold_change",
                        f_ref = 1 / input$lda_finv_ref,
                        fold_change = input$lda_fc,
                        n_range = n_range, alpha = alpha, n_iter = n_iter)
            },
            "direct_prob" = {
              p1v <- parse_numeric_vec(input$lda_p1)
              p2v <- parse_numeric_vec(input$lda_p2)
              validate(need(length(p1v) == length(doses) &&
                              length(p2v) == length(doses),
                            "Provide one probability per dose for each group."))
              power_lda(doses = doses, mode = "direct_prob",
                        p1 = p1v, p2 = p2v,
                        n_range = n_range, alpha = alpha, n_iter = n_iter)
            }
          )
          if (!is.null(r$f1) && !is.null(r$f2)) {
            r$group <- sprintf("1/f1=%.0f vs 1/f2=%.0f",
                               1 / r$f1[1], 1 / r$f2[1])
          } else {
            r$group <- "direct probs"
          }
          incProgress(1)
          r
        },

        "survival" = {
          r <- power_survival(hr = input$sv_hr, lambda = input$sv_lambda,
                              n_range = n_range,
                              accrual = input$sv_accrual,
                              followup = input$sv_followup,
                              dropout_rate = input$sv_dropout,
                              alpha = alpha, n_iter = n_iter)
          r$group <- sprintf("HR = %.3g", input$sv_hr)
          incProgress(1)
          r
        }
      )
    })
  })

  output$plotUI <- renderUI({
    ar <- aspect_ratio(input$plot_aspect)
    h  <- as.integer(input$plot_height %||% 460)
    w  <- as.integer(round(h * ar))
    plotOutput("plot",
               width  = paste0(w, "px"),
               height = paste0(h, "px"))
  })

  resolved_border <- reactive({
    sel <- input$plot_border %||% "none"
    if (sel == "none") return(NA_character_)
    if (sel == "custom") return(input$plot_border_color %||% "#1F77B4")
    sel
  })

  output$plot <- renderPlot({
    df <- results()
    req(df)
    power_curve(df, target = input$target_power,
                title = sprintf("Power vs sample size — %s",
                                names(EXPERIMENTS)[EXPERIMENTS == input$experiment]),
                subtitle = sprintf("alpha = %.3g  |  %d MC iterations per N",
                                   input$alpha, as.integer(input$n_iter)),
                group_lab = "Effect",
                base_size = as.integer(input$plot_font %||% 16),
                border_color = resolved_border(),
                x_label_angle = as.numeric(input$x_label_angle %||% 0),
                x_tick_mode = input$x_tick_mode %||% "auto")
  }, res = 110)

  output$table <- renderTable({
    df <- results()
    req(df)
    df
  }, digits = 4)

  output$summary_box <- renderUI({
    df <- results()
    req(df)
    cr <- crossings_table(df, target = input$target_power)
    pieces <- lapply(seq_len(nrow(cr)), function(i) {
      g <- cr$group[i]
      if (is.na(cr$n_star[i])) {
        label <- sprintf(
          "<b>%s</b>: target power %.2f not reached — extend the sample-size range.",
          g, input$target_power)
      } else {
        n_min_tested <- min_n_for_power(
          if ("group" %in% names(df)) df[df$group == g, ] else df,
          input$target_power)
        label <- sprintf(
          "<b>%s</b>: estimated N ≈ <b>%.1f</b> (use <b>N = %d</b>) to reach power %.2f.%s",
          g, cr$n_star[i], cr$n_int[i], input$target_power,
          if (!is.na(n_min_tested))
            sprintf(" Smallest tested N meeting target: %d.", n_min_tested)
          else "")
      }
      tags$li(HTML(label))
    })
    div(class = "alert alert-info",
        tags$strong("Sample size estimate"),
        tags$ul(pieces),
        tags$small(HTML(
          "<em>Estimates are linearly interpolated between simulated points; ",
          "the integer value is the smallest N predicted to reach the target.</em>"
        )))
  })

  output$dl_table <- downloadHandler(
    filename = function() {
      sprintf("powerR_%s_%s.csv", input$experiment, Sys.Date())
    },
    content = function(file) {
      utils::write.csv(results(), file, row.names = FALSE)
    }
  )

  build_export_plot <- reactive({
    df <- results()
    req(df)
    power_curve(df, target = input$target_power,
                title = NULL,
                group_lab = "Effect",
                base_size = as.integer(input$plot_font %||% 16),
                border_color = resolved_border(),
                x_label_angle = as.numeric(input$x_label_angle %||% 0),
                x_tick_mode = input$x_tick_mode %||% "auto")
  })

  plot_dims_in <- reactive({
    ar <- aspect_ratio(input$plot_aspect)
    h_in <- (as.integer(input$plot_height %||% 460)) / 96
    list(w = max(h_in * ar, 4), h = max(h_in, 3))
  })

  dl_filename <- function(ext) {
    function() sprintf("powerR_%s_%s.%s", input$experiment, Sys.Date(), ext)
  }

  output$dl_png <- downloadHandler(
    filename = dl_filename("png"),
    content  = function(file) {
      d <- plot_dims_in()
      ggplot2::ggsave(file, build_export_plot(),
                      device = "png",
                      width = d$w, height = d$h, dpi = 300)
    }
  )

  output$dl_pdf <- downloadHandler(
    filename = dl_filename("pdf"),
    content  = function(file) {
      d <- plot_dims_in()
      # Use grDevices::pdf directly so we control useDingbats (improves
      # downstream editability in Illustrator / Inkscape).
      grDevices::pdf(file, width = d$w, height = d$h, useDingbats = FALSE)
      print(build_export_plot())
      grDevices::dev.off()
    }
  )

  output$dl_svg <- downloadHandler(
    filename = dl_filename("svg"),
    content  = function(file) {
      d <- plot_dims_in()
      # Prefer svglite (cleaner text, smaller file) when available; otherwise
      # fall back to base grDevices::svg so shinylive deploys without
      # svglite still work.
      if (requireNamespace("svglite", quietly = TRUE)) {
        ggplot2::ggsave(file, build_export_plot(), device = "svg",
                        width = d$w, height = d$h)
      } else {
        grDevices::svg(file, width = d$w, height = d$h)
        print(build_export_plot())
        grDevices::dev.off()
      }
    }
  )

  output$method_doc <- renderUI({
    txt <- switch(
      input$experiment,
      "ttest" = HTML("
        <h4>Simulation-based t-test power</h4>
        <p>For each candidate sample size <i>N</i>, the app draws Monte
        Carlo samples from <code>rnorm(N, 0, 1)</code> and
        <code>rnorm(N, d, 1)</code> (two-sample), or
        <code>rnorm(N, d, 1)</code> against zero (one-sample / paired),
        runs the corresponding <code>t.test</code>, and records the
        proportion of iterations with p &lt; alpha.</p>
        <p>Cohen's <i>d</i> is the standardized mean difference. If you
        supply means and SDs, <i>d</i> is computed as
        (m2 - m1) / sqrt((sd1^2 + sd2^2) / 2).</p>"),
      "proportions" = HTML("
        <h4>Two-proportion test power</h4>
        <p>Each iteration draws <code>x_g ~ Binomial(N, p_g)</code> and
        runs either a two-proportion z-test (<code>prop.test</code>,
        no continuity correction) or Fisher's exact test. Power is the
        fraction of iterations rejecting at the chosen alpha.</p>"),
      "anova" = HTML("
        <h4>One-way ANOVA power</h4>
        <p>Each iteration draws N observations per group from
        <code>rnorm(N, mu_g, sd_g)</code> and runs <code>aov</code>.
        Cohen's <i>f</i> is reported as a standardized effect size
        equal to the ratio of between-group SD of means to the pooled
        within-group SD.</p>"),
      "lda" = HTML("
        <h4>Limiting Dilution Analysis (Poisson single-hit)</h4>
        <p>Under the Poisson single-hit assumption, the probability that
        an injection of <i>d</i> cells contains at least one active cell
        is <code>1 - exp(-d * f)</code>, where <i>f</i> is the active
        cell frequency. The app simulates Bernoulli responder outcomes
        for every mouse, then tests whether two conditions share the
        same <i>f</i> using the ELDA-style likelihood-ratio test on a
        complementary log-log GLM with a log(dose) offset
        (Hu &amp; Smyth, 2009).</p>
        <p>Three input modes are supported: per-group frequency
        (<i>1/f</i>), reference frequency plus fold-change, and direct
        response probabilities per dose (which bypasses the Poisson
        model).</p>"),
      "survival" = HTML("
        <h4>Log-rank power under proportional hazards</h4>
        <p>Each iteration simulates exponential event times with rate
        <code>lambda</code> for group 1 and <code>lambda * HR</code> for
        group 2. Subjects are uniformly accrued over the accrual window
        and followed for the specified follow-up duration; optional
        independent exponential dropout is applied. Group comparison
        uses <code>survival::survdiff</code> (log-rank).</p>")
    )
    txt
  })
}

shinyApp(ui, server)
