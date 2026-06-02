# PowerR

[![Deploy to GitHub Pages](https://github.com/systemsheme/PowerR/actions/workflows/deploy.yml/badge.svg)](https://github.com/systemsheme/PowerR/actions/workflows/deploy.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Simulation-based power analysis for experiment planning.**

PowerR is a Shiny application for designing biomedical experiments. Instead
of relying on closed-form approximations, it runs Monte Carlo simulations
under the data-generating model that matches your experiment type, so the
power estimates reflect the test you actually plan to run.

## Try it live

**[systemsheme.github.io/PowerR](https://systemsheme.github.io/PowerR/)** — runs
entirely in your browser via [shinylive](https://posit-dev.github.io/r-shinylive/)
(WebAssembly). First load takes ~15–30 seconds while R and the required packages
download to your browser; thereafter it is fully interactive with no server
round-trip. Nothing you enter leaves your machine.

> For larger / faster simulations (LDA with 5,000+ iterations, very wide N
> sweeps), running the app locally with native R will be substantially faster.
> See the [Installation](#installation) section.

## Supported designs

| Design | Test simulated | Effect-size input |
| --- | --- | --- |
| Two-sample / paired / one-sample t-test | `t.test` | Cohen's *d*, or means + SDs |
| Two-proportion test | `prop.test` or Fisher's exact | p1 and p2 |
| One-way ANOVA (≥3 groups) | `aov` | Vector of group means + SD |
| Limiting Dilution Analysis (LDA) | ELDA-style cloglog-GLM LRT | Active-cell frequencies *1/f*, fold-change, or direct probabilities |
| Survival / log-rank | `survival::survdiff` | Hazard ratio + baseline rate |

For each design the app sweeps a user-specified range of sample sizes and
returns a power curve, a results table (downloadable as CSV), and the
smallest N achieving your target power.

## Limiting Dilution Analysis

LDA is the part most adjacent power tools omit. PowerR uses the standard
Poisson single-hit model (Hu & Smyth, *J. Immunol. Methods*, 2009):

> P(at least one active cell in an injection of *d* cells) = 1 − exp(−*d* · *f*)

where *f* is the active-cell frequency. The app simulates Bernoulli
responder outcomes for each mouse at each dose in each group, then tests
H₀: *f₁* = *f₂* using a likelihood-ratio test on a complementary
log-log GLM with `log(dose)` offset — the same test used by the `limdil`
function in **statmod**. Power is the fraction of simulations that
reject at level α.

Three input modes are supported, so you can specify the comparison in
whatever way fits the biology:

1. **Per-group 1/f** — e.g., 1 in 5,000 (control) vs 1 in 25,000 (treated)
2. **Reference 1/f + fold-change** — e.g., 1 in 5,000 reference, 5× rarer in treated
3. **Direct response probabilities at each dose** — bypasses the Poisson assumption

## Installation

```r
# Required packages
install.packages(c("shiny", "bslib", "ggplot2", "survival"))
```

Clone and run:

```bash
git clone https://github.com/<your-user>/PowerR.git
cd PowerR
```

```r
shiny::runApp(".")
```

Or, from any working directory:

```r
shiny::runApp("path/to/PowerR")
```

## Using the underlying functions directly

The simulation functions in `R/` can be called outside Shiny:

```r
source("R/power_ttest.R")
source("R/power_lda.R")

# T-test: how many mice per group to detect a Cohen's d of 1.0?
power_ttest(test = "two_sample", n_range = 3:20, d = 1.0, n_iter = 1000)

# LDA: how many mice per dose to detect 1/5000 vs 1/25000?
power_lda(
  doses    = c(100, 1000, 10000, 100000),
  mode     = "frequency",
  f1       = 1 / 5000,
  f2       = 1 / 25000,
  n_range  = c(3, 5, 8, 10, 12, 15),
  n_iter   = 1000
)
```

Each function returns a data frame with columns `N` (sample size per group,
or mice per dose for LDA) and `power`.

## Reproducibility

The app exposes a random seed input. Set it to a fixed value (default
`42`) for reproducible runs; clear it to get a fresh seed each click.

## Tips for accurate power estimates

- **Iterations.** Default is 500 per sample size, which gives Monte Carlo
  error of roughly ±0.02 around power = 0.5. For final results aim for
  2,000–5,000 iterations.
- **Sample-size range.** Bracket the regime of interest. If the curve
  plateaus below your target power, extend the upper end of the range.
- **LDA dose ladder.** Choose doses that span both the low end (rare
  responders) and the saturating end (≈100% response). 4–6 well-spaced
  doses is typical.
- **Survival.** The accrual + follow-up window determines administrative
  censoring; if most subjects are censored, power saturates and you may
  need a longer study, not a larger N.

## Roadmap

- Multiple testing correction options beyond Bonferroni / nominal α
- Mixed-effects designs (longitudinal, clustered)
- Closed-form sanity checks alongside the simulation
- Bayesian power / assurance for prior distributions over effect sizes

## License

MIT — see [LICENSE](LICENSE).

## Citation

If PowerR helps plan an experiment that ends up in a paper, a citation to
this repository is appreciated. The LDA component implements the test of
Hu & Smyth (2009), which should be cited alongside it.

> Hu Y, Smyth GK. ELDA: Extreme limiting dilution analysis for comparing
> depleted and enriched populations in stem cell and other assays.
> *J Immunol Methods* 347(1–2):70–8 (2009).
