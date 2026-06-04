# Tutorial content for the PowerR Shiny app.
# Returns a tagList suitable for use inside nav_panel("Tutorial", ...).

tutorial_panel <- function() {
  shiny::tagList(
    shiny::tags$style(shiny::HTML("
      .powerr-tutorial { max-width: 980px; padding: 8px 4px 32px 4px; }
      .powerr-tutorial h3 { margin-top: 28px; font-weight: 700;
        border-bottom: 2px solid #e2e2e2; padding-bottom: 6px; }
      .powerr-tutorial h4 { margin-top: 20px; font-weight: 600; }
      .powerr-tutorial .formula {
        background: #f6f8fa; border-left: 3px solid #1F77B4;
        padding: 8px 12px; font-family: ui-monospace, Menlo, monospace;
        margin: 8px 0; }
      .powerr-tutorial pre.tut-code {
        background: #0f172a; color: #e2e8f0;
        padding: 12px 14px; border-radius: 6px;
        font-family: ui-monospace, Menlo, Consolas, monospace;
        font-size: 0.9em; line-height: 1.45;
        overflow-x: auto; margin: 10px 0; white-space: pre; }
      .powerr-tutorial table { border-collapse: collapse; width: 100%;
        margin: 12px 0; }
      .powerr-tutorial th, .powerr-tutorial td {
        border: 1px solid #ddd; padding: 8px 10px; text-align: left;
        vertical-align: top; }
      .powerr-tutorial th { background: #f6f8fa; }
      .powerr-tutorial .callout {
        background: #fff4e5; border-left: 4px solid #E31A1C;
        padding: 10px 14px; margin: 14px 0; border-radius: 4px; }
      .powerr-tutorial .ref { font-size: 0.95em; }
    ")),
    shiny::div(
      class = "powerr-tutorial",

      shiny::h2("Tutorial: power analysis with PowerR"),
      shiny::p(
        "This page explains what a power analysis is, why PowerR uses",
        " simulation rather than a closed-form formula, what each",
        " parameter in the sidebar means, and how to read the results.",
        " If you are new to power analysis, read it once end-to-end. If",
        " you are just looking up a parameter, jump to the relevant",
        " section."
      ),

      shiny::div(class = "callout",
        shiny::tags$strong("Do I need to install anything?"),
        shiny::HTML(" <b>No.</b> If you are using the hosted version at"),
        shiny::tags$code("www.systemshematology.org/PowerR"),
        shiny::HTML(", PowerR runs entirely in your browser via"),
        shiny::tags$a(href = "https://posit-dev.github.io/r-shinylive/",
                      target = "_blank", "shinylive"),
        shiny::HTML(" — a WebAssembly build of R. The first time you"),
        " visit, your browser downloads R and the required packages",
        " (shiny, bslib, ggplot2, survival; ~50–80 MB total) and caches",
        " them, so subsequent visits start instantly. The simulations",
        " then run on your own CPU inside the browser sandbox; nothing",
        " you enter is sent to a server.",
        shiny::tags$br(), shiny::tags$br(),
        shiny::HTML("<b>Requirements:</b> a modern browser (Chrome, Firefox,"),
        " Safari, or Edge from roughly the last three years) and a few",
        " hundred MB of free RAM. Best on a laptop or desktop; mobile",
        " works but the larger simulations are slow.",
        shiny::tags$br(), shiny::tags$br(),
        shiny::HTML("<b>Prefer native speed?</b> For very large simulations"),
        " (LDA with 5,000+ Monte Carlo iterations, or a wide sample-size",
        " sweep) running PowerR locally in a real R session is",
        " substantially faster. PowerR is shipped as an R package — install",
        " once from GitHub, then launch with one command:",
        shiny::tags$pre(class = "tut-code", shiny::HTML(
"# 1. Install R 4.2+ (https://cran.r-project.org/) and, optionally, RStudio.

# 2. Install the helper package (one time):
install.packages(\"remotes\")

# 3. Install PowerR from GitHub. This pulls every R dependency in one go:
remotes::install_github(\"systemsheme/PowerR\")

# 4. Launch the app — your default browser opens to PowerR:
PowerR::run_app()
# or pick a specific port / suppress auto-open:
# PowerR::run_app(port = 4567, launch.browser = FALSE)"
        )),
        "Same UI, same controls — just no WebAssembly overhead, and your",
        " files stay where they are on your machine. To upgrade later, ",
        " re-run the same ",
        shiny::tags$code("remotes::install_github(\"systemsheme/PowerR\")"),
        " in a fresh R session.",
        shiny::tags$br(), shiny::tags$br(),
        shiny::HTML("<b>Source install instead?</b> Clone the repo with "),
        shiny::tags$code("git clone https://github.com/systemsheme/PowerR.git"),
        ", then from R run ",
        shiny::tags$code("shiny::runApp(\"PowerR/inst/app\")"),
        " — useful if you want to edit the code while it runs.",
        shiny::tags$br(), shiny::tags$br(),
        shiny::HTML("<b>Don't want to touch R at all?</b> The repo also ships"),
        " a small Python launcher that finds R on your computer, installs",
        " PowerR if missing, and opens the app in your browser. Clone the",
        " repo (above), then:",
        shiny::tags$pre(class = "tut-code", shiny::HTML(
"python3 powerr.py
# Flags: --upgrade (reinstall latest), --port 4567 (pin a port),
#        --no-browser (don't auto-open). Ctrl+C to stop."
        )),
        "Requires Python 3.8+ and an R install — no third-party Python",
        " packages."
      ),

      # ------------------------------------------------------------
      shiny::h3("1. What is statistical power?"),
      shiny::p(
        "Statistical power is the probability that your experiment will",
        " correctly detect a real effect when one exists. Formally:"
      ),
      shiny::div(class = "formula",
        "Power  =  1 − β  =  P(reject H₀ | H₁ is true)"),
      shiny::p(
        "Every hypothesis test makes two kinds of mistakes:"
      ),
      shiny::tags$ul(
        shiny::tags$li(shiny::HTML("<b>Type I error (α)</b> — rejecting the null when it is actually true (a false positive). You set this as the significance threshold, conventionally 0.05.")),
        shiny::tags$li(shiny::HTML("<b>Type II error (β)</b> — failing to reject the null when an effect really exists (a false negative). Power is 1 − β. The conventional target is 0.80, meaning you accept a 20% chance of missing a real effect."))
      ),
      shiny::p(
        "An ", shiny::tags$em("under-powered"), " study wastes resources",
        " — mice, money, time — on an experiment that probably will not",
        " detect the very effect you are looking for, and any positive",
        " result it does produce is more likely to be a fluke (the",
        ' "winner\'s curse"). An ', shiny::tags$em("over-powered"),
        " study is also wasteful and, for animal work, raises ethical",
        " concerns (the 3Rs)."
      ),

      # ------------------------------------------------------------
      shiny::h3("2. The four interlocking parameters"),
      shiny::p(
        "Power analysis ties together four quantities. Fix any three and",
        " the fourth is determined."
      ),
      shiny::tags$table(
        shiny::tags$tr(
          shiny::tags$th("Parameter"),
          shiny::tags$th("Symbol"),
          shiny::tags$th("In PowerR")
        ),
        shiny::tags$tr(
          shiny::tags$td("Significance threshold"),
          shiny::tags$td("α"),
          shiny::tags$td("Sidebar: ", shiny::tags$em("Significance threshold (alpha)"))
        ),
        shiny::tags$tr(
          shiny::tags$td("Power"),
          shiny::tags$td("1 − β"),
          shiny::tags$td("Sidebar: ", shiny::tags$em("Target power"), "; horizontal dashed line on the plot.")
        ),
        shiny::tags$tr(
          shiny::tags$td("Effect size"),
          shiny::tags$td("d, h, f, RR, HR, …"),
          shiny::tags$td("Depends on experiment type (see Section 4).")
        ),
        shiny::tags$tr(
          shiny::tags$td("Sample size"),
          shiny::tags$td("N (per group)"),
          shiny::tags$td("Sidebar: ", shiny::tags$em("Sample sizes to evaluate"), ". PowerR sweeps this list and finds the N that crosses the target.")
        )
      ),
      shiny::p(
        "Most experiment planning asks the same question: ",
        shiny::tags$em(
          'given my expected effect size and chosen α, how many subjects do I need for power ≥ 0.80?'
        ),
        " PowerR answers this by simulating across a range of candidate Ns and",
        " interpolating where the curve crosses the target."
      ),

      # ------------------------------------------------------------
      shiny::h3("3. Why simulation instead of a closed-form formula?"),
      shiny::p(
        "Closed-form power formulas exist for a handful of simple cases",
        " (Student's t-test against equal variances, balanced one-way",
        " ANOVA, two-proportion z-test, log-rank under Schoenfeld's",
        " approximation). They are convenient but make strong",
        " assumptions: normal residuals, equal variances, balanced",
        " groups, no censoring, no missing data, a single test."
      ),
      shiny::p("Simulation-based power analysis works as follows:"),
      shiny::tags$ol(
        shiny::tags$li("Specify a data-generating model that matches what your real experiment will look like."),
        shiny::tags$li("Sample a synthetic dataset of size N from that model."),
        shiny::tags$li("Run exactly the statistical test you plan to run on the real data."),
        shiny::tags$li("Record whether p < α."),
        shiny::tags$li("Repeat steps 2–4 many times (Monte Carlo). The fraction of rejections is your empirical power.")
      ),
      shiny::p("This approach has several advantages:"),
      shiny::tags$ul(
        shiny::tags$li(shiny::HTML("<b>It matches your real analysis.</b> If you plan to use a Welch t-test, an ELDA likelihood-ratio test, or a Cox model, simulate that test — not an idealized version of it.")),
        shiny::tags$li(shiny::HTML("<b>It generalizes to complex designs.</b> Limiting dilution, censoring, mixed effects, multiple comparisons — none have clean closed-form power formulas. Simulation handles them all the same way.")),
        shiny::tags$li(shiny::HTML("<b>It surfaces small-sample misbehavior.</b> Closed-form approximations break down at small N; simulation does not.")),
        shiny::tags$li(shiny::HTML("<b>It is honest about uncertainty.</b> You can vary effect-size estimates across plausible values and see the power curves side-by-side."))
      ),
      shiny::p("The trade-off is computational cost and Monte Carlo noise."),
      shiny::div(class = "callout",
        shiny::tags$strong("Monte Carlo noise."),
        shiny::HTML(" With <i>k</i> iterations, the SE of an estimated power"),
        " p is approximately √(p(1 − p) / k). At k = 500, SE ≈ 0.022 near",
        " p = 0.5. PowerR's default of 500 is enough for exploration; for",
        " final estimates use 2,000–5,000 to tighten the curve."
      ),

      # ------------------------------------------------------------
      shiny::h3("4. Effect sizes by experiment type"),
      shiny::p(
        "Effect size is the single most important — and most uncertain —",
        " input. Get it from pilot data, the literature, or a biologically",
        " meaningful minimum. If you cannot defend the value, your sample",
        " size estimate is not defensible either. Always run a sensitivity",
        " analysis across a plausible range."
      ),
      shiny::tags$table(
        shiny::tags$tr(
          shiny::tags$th("Experiment"),
          shiny::tags$th("Effect-size metric"),
          shiny::tags$th("How PowerR collects it")
        ),
        shiny::tags$tr(
          shiny::tags$td("Two-sample / paired / one-sample t-test"),
          shiny::tags$td(shiny::HTML("Cohen's <i>d</i> = (μ₂ − μ₁) / σ_pooled")),
          shiny::tags$td("Enter d directly, or supply group means and SDs and PowerR computes d.")
        ),
        shiny::tags$tr(
          shiny::tags$td("Two-proportion test"),
          shiny::tags$td("Group proportions p₁, p₂"),
          shiny::tags$td("Enter both proportions directly.")
        ),
        shiny::tags$tr(
          shiny::tags$td("One-way ANOVA"),
          shiny::tags$td(shiny::HTML("Group means + within-group SD; PowerR reports Cohen's <i>f</i>")),
          shiny::tags$td("Comma-separated vector of means and a common (or per-group) SD.")
        ),
        shiny::tags$tr(
          shiny::tags$td("Limiting Dilution (LDA)"),
          shiny::tags$td("Active-cell frequency f (or fold-change in f)"),
          shiny::tags$td("Three modes — see Section 6.")
        ),
        shiny::tags$tr(
          shiny::tags$td("Survival / log-rank"),
          shiny::tags$td("Hazard ratio (HR)"),
          shiny::tags$td("HR ≠ 1; baseline event rate λ also required.")
        )
      ),
      shiny::h4("Cohen's d benchmarks (use with caution)"),
      shiny::p(
        "Cohen (1988) proposed rough conventions for behavioural research:",
        " d ≈ 0.2 small, 0.5 medium, 0.8 large. These are field-dependent.",
        " A drug response of d = 0.3 in oncology can be transformative; a",
        " psychology effect of d = 0.3 may be unremarkable. Anchor your",
        " effect size in domain knowledge, not in Cohen's table alone."
      ),

      # ------------------------------------------------------------
      shiny::h3("5. Walk-through of PowerR's sidebar parameters"),
      shiny::tags$dl(
        shiny::tags$dt(shiny::tags$strong("Experiment type")),
        shiny::tags$dd("Selects which simulation engine to use. Each engine has its own set of effect-size inputs."),

        shiny::tags$dt(shiny::tags$strong("Significance threshold (α)")),
        shiny::tags$dd("Default 0.05. Set lower (e.g. 0.01 or 0.05 / m for m comparisons) if you are doing multiple hypothesis tests and want a Bonferroni-adjusted threshold."),

        shiny::tags$dt(shiny::tags$strong("Monte Carlo iterations")),
        shiny::tags$dd("Number of synthetic datasets simulated per sample size. More iterations → smoother curve → narrower confidence on power. Start at 500 for exploration, finish at 2,000–5,000."),

        shiny::tags$dt(shiny::tags$strong("Target power")),
        shiny::tags$dd("The horizontal dashed line on the plot. 0.80 is the conventional minimum. For grant proposals reviewers commonly expect ≥ 0.80; for confirmatory or registered work some fields target 0.90."),

        shiny::tags$dt(shiny::tags$strong("Random seed")),
        shiny::tags$dd("Fix it for a reproducible run, leave it alone (or clear it) for a fresh draw each click. Same seed + same inputs = same result, which is essential when sharing power calculations with collaborators."),

        shiny::tags$dt(shiny::tags$strong("Sample sizes to evaluate")),
        shiny::tags$dd("Comma- or space-separated list of candidate N values per group (or per dose, for LDA). Make sure the list spans low (where power is well below target) to high (where it plateaus above target) so the crossing can be interpolated."),

        shiny::tags$dt(shiny::tags$strong("Plot aspect ratio / size / font")),
        shiny::tags$dd("Cosmetic. Wide 5:3 matches GraphPad Prism's standard layout. Increase font size for talks; decrease for dense multi-panel figures."),

        shiny::tags$dt(shiny::tags$strong("Plot border, x-axis label angle, x-axis ticks")),
        shiny::tags$dd("Style options. Use a black box and 45° tick labels for a Prism-like figure; use the default open-axes Prism style for publication. Switch x-axis ticks to ", shiny::tags$em("Auto (pretty breaks)"), " when your N list is long, to avoid label overlap.")
      ),

      # ------------------------------------------------------------
      shiny::h3("6. Limiting Dilution Analysis: a primer"),
      shiny::p(
        "Limiting dilution assays ask how rare a functional cell is — for",
        " example, how many leukemia stem cells per million are competent",
        " to engraft a mouse. You inject decreasing doses of cells into",
        " groups of mice and record which mice are responders",
        " (engraftment, tumor formation, colony growth, …). The standard",
        " model is the ", shiny::tags$strong("Poisson single-hit"),
        " assumption: one active cell is sufficient to produce a response,",
        " and active cells are randomly distributed in the injection. Then"
      ),
      shiny::div(class = "formula",
        "P(at least one active cell in dose x) = 1 − exp(−x · f)"
      ),
      shiny::p(
        "where ", shiny::tags$em("f"), " is the active-cell frequency",
        " (e.g. 1 / 5,000 means one active cell per 5,000 plated cells)."
      ),
      shiny::p("PowerR detects a difference in f between two conditions using the ", shiny::tags$strong("ELDA likelihood-ratio test"), " (Hu & Smyth, 2009): a complementary log-log GLM with a log(dose) offset, fit with and without a group term. The LRT statistic is χ² with 1 degree of freedom."),
      shiny::h4("Three ways to specify the comparison"),
      shiny::tags$ul(
        shiny::tags$li(shiny::HTML("<b>Stem-cell frequencies (1/f) per group.</b> Most biologically transparent. Enter e.g. 1/5,000 (control) vs 1/25,000 (treated).")),
        shiny::tags$li(shiny::HTML("<b>Reference frequency + fold-change.</b> Equivalent to the first mode but framed as an effect size — useful when the literature reports fold-changes rather than absolute frequencies.")),
        shiny::tags$li(shiny::HTML("<b>Direct response probabilities per dose.</b> Bypasses the Poisson assumption entirely. Use this when your pilot data already gives you the response probability at each dose."))
      ),
      shiny::h4("Practical tips for LDA"),
      shiny::tags$ul(
        shiny::tags$li("Span the dose range so the lowest dose gives sparse responders (≈ 0–20%) and the highest dose saturates (≈ 95–100%). Four to six well-spaced doses is typical."),
        shiny::tags$li("Power depends much more on the dose ladder than on adding mice at a single dose. Adding a low-dose group often beats doubling mice per group."),
        shiny::tags$li("The ", shiny::tags$em("Sample sizes to evaluate"), " input represents mice per dose, per group.")
      ),

      # ------------------------------------------------------------
      shiny::h3("7. How to read a PowerR power curve"),
      shiny::tags$ul(
        shiny::tags$li(shiny::HTML("<b>X-axis</b> — sample size per group (per dose, for LDA).")),
        shiny::tags$li(shiny::HTML("<b>Y-axis</b> — simulated power, 0 to 1.")),
        shiny::tags$li(shiny::HTML("<b>Horizontal dashed line</b> — your target power.")),
        shiny::tags$li(shiny::HTML("<b>Vertical dotted line + N ≈ X label</b> — the smallest sample size the simulation estimates will reach the target. PowerR linearly interpolates between adjacent simulated points and reports the ceiling.")),
        shiny::tags$li(shiny::HTML("<b>Coloured curves</b> — one per effect-size level (for t-tests) or one per condition (otherwise). Curves that never cross the target are flagged in the summary box."))
      ),

      # ------------------------------------------------------------
      shiny::h3("8. A recommended workflow"),
      shiny::tags$ol(
        shiny::tags$li("Decide on α and target power (usually 0.05 and 0.80)."),
        shiny::tags$li("Estimate the effect size from pilot data or the literature. Document where the estimate came from."),
        shiny::tags$li("Run PowerR with a wide sample-size range and the default 500 iterations."),
        shiny::tags$li("Read off the rough N where the curve crosses the target."),
        shiny::tags$li("Tighten the range around that N and increase iterations to 2,000–5,000."),
        shiny::tags$li(shiny::HTML("Run a <b>sensitivity analysis</b>: vary the effect size by ± 30% and replot. Your real-world effect may not match your point estimate; the curves should still be reasonable across the plausible range.")),
        shiny::tags$li("Save the plot and the CSV; include both in your grant, protocol, or methods section.")
      ),

      # ------------------------------------------------------------
      shiny::h3("9. Common pitfalls"),
      shiny::tags$ul(
        shiny::tags$li(shiny::HTML("<b>Plugging in observed effects from your own data</b> as the assumed effect size for a follow-up study. This inflates power because of the winner's curse. Use a more conservative estimate.")),
        shiny::tags$li(shiny::HTML("<b>Forgetting multiple testing.</b> If you have m co-primary hypotheses, lower α to 0.05 / m (Bonferroni) before computing power.")),
        shiny::tags$li(shiny::HTML("<b>Confusing power for one comparison with power for a study.</b> A multi-arm trial needs power for the specific contrasts of interest.")),
        shiny::tags$li(shiny::HTML("<b>Reporting only a single N.</b> Always report assumptions: effect size, α, power target, design, attrition assumption, and the method used to compute it.")),
        shiny::tags$li(shiny::HTML("<b>Treating the simulated N as a hard floor.</b> It is a planning estimate; biological variation will surprise you. If feasible, plan slightly above the simulated minimum."))
      ),

      # ------------------------------------------------------------
      shiny::h3("10. References and further reading"),
      shiny::tags$ul(class = "ref",
        shiny::tags$li(shiny::HTML("Cohen J. <i>Statistical Power Analysis for the Behavioral Sciences</i>, 2nd ed. Lawrence Erlbaum (1988). The canonical textbook; introduces d, f, h and the 0.2 / 0.5 / 0.8 benchmarks.")),
        shiny::tags$li(shiny::HTML("Lakens D. Calculating and reporting effect sizes to facilitate cumulative science. <i>Front Psychol</i> 4:863 (2013). Modern, practical effect-size guide.")),
        shiny::tags$li(shiny::HTML("Lakens D. Sample size justification. <i>Collabra: Psychology</i> 8(1):33267 (2022). How to defensibly choose a sample size, including for non-traditional designs.")),
        shiny::tags$li(shiny::HTML("Champely S. <i>pwr</i>: Basic Functions for Power Analysis. R package — closed-form sanity-check companion to PowerR.")),
        shiny::tags$li(shiny::HTML("Hughes J. <i>paramtest</i>: Run a Function Iteratively While Varying Parameters. R package — the simulation backbone behind the original ", shiny::tags$code("power.R"), " script that seeded this project.")),
        shiny::tags$li(shiny::HTML("Hu Y, Smyth GK. ELDA: Extreme limiting dilution analysis for comparing depleted and enriched populations in stem cell and other assays. <i>J Immunol Methods</i> 347:70–8 (2009). The LRT that PowerR's LDA module replicates by simulation; cite alongside any LDA-based power justification.")),
        shiny::tags$li(shiny::HTML("Bonapersona V, Hoijtink H, Sarabdjitsingh R A, Joëls M. Increasing the statistical power of animal experiments with historical control data. <i>Nat Neurosci</i> 24:470–477 (2021). Argues for simulation-driven planning in animal work.")),
        shiny::tags$li(shiny::HTML("Schoenfeld DA. Sample-size formula for the proportional-hazards regression model. <i>Biometrics</i> 39:499–503 (1983). The closed-form log-rank approximation against which PowerR's survival simulator can be sanity-checked.")),
        shiny::tags$li(shiny::HTML("Green P, MacLeod CJ. SIMR: an R package for power analysis of generalized linear mixed models by simulation. <i>Methods Ecol Evol</i> 7:493–8 (2016). Excellent companion read for the simulation approach more broadly.")),
        shiny::tags$li(shiny::HTML("Gelman A, Carlin J. Beyond power calculations: assessing Type S (sign) and Type M (magnitude) errors. <i>Perspect Psychol Sci</i> 9:641–51 (2014). Why classical power is not the only thing to worry about; complement to any power analysis."))
      ),
      shiny::p(class = "ref",
        shiny::tags$em("Suggested citation for PowerR itself: this Shiny application is open-source under MIT licence; consider citing the repository (and Hu & Smyth, 2009, for LDA results) in any publication that used a PowerR power justification.")
      )
    )
  )
}
