#' Simulation-based power analysis for t-tests
#'
#' Supports two-sample, paired, and one-sample t-tests. Effect size can be
#' supplied as Cohen's d directly, or computed from group means/SDs.
#'
#' @param test One of "two_sample", "paired", "one_sample".
#' @param n_range Integer vector of per-group sample sizes to evaluate.
#' @param effect_mode "cohens_d" (use `d` directly) or "means_sd" (compute d
#'   from `m1`, `m2`, `sd1`, `sd2`).
#' @param d Cohen's d (used when effect_mode == "cohens_d").
#' @param m1,m2,sd1,sd2 Means and SDs for the two groups (means_sd mode).
#'   For one-sample, m1 is the population mean under H0, m2 the true mean,
#'   sd1 the population SD (sd2 ignored).
#' @param alpha Significance threshold.
#' @param alternative "two.sided", "less", or "greater".
#' @param var_equal Pool variance? (two-sample only)
#' @param n_iter Monte Carlo iterations per sample size.
#'
#' @return data.frame with columns N, power, and the d used.
power_ttest <- function(test = c("two_sample", "paired", "one_sample"),
                        n_range,
                        effect_mode = c("cohens_d", "means_sd"),
                        d = NULL,
                        m1 = NULL, m2 = NULL, sd1 = NULL, sd2 = NULL,
                        alpha = 0.05,
                        alternative = "two.sided",
                        var_equal = TRUE,
                        n_iter = 500) {
  test <- match.arg(test)
  effect_mode <- match.arg(effect_mode)

  if (effect_mode == "means_sd") {
    if (is.null(m1) || is.null(m2) || is.null(sd1)) {
      stop("means_sd mode requires m1, m2, and sd1.")
    }
    if (is.null(sd2)) sd2 <- sd1
    pooled_sd <- sqrt((sd1^2 + sd2^2) / 2)
    if (pooled_sd <= 0) stop("Pooled SD must be > 0.")
    d <- (m2 - m1) / pooled_sd
  }
  if (is.null(d)) stop("Effect size d could not be determined.")

  sim_one <- function(N) {
    sig <- logical(n_iter)
    for (i in seq_len(n_iter)) {
      if (test == "two_sample") {
        x1 <- rnorm(N, 0, 1)
        x2 <- rnorm(N, d, 1)
        p <- tryCatch(
          t.test(x1, x2, var.equal = var_equal, alternative = alternative)$p.value,
          error = function(e) NA_real_
        )
      } else if (test == "paired") {
        diffs <- rnorm(N, d, 1)
        p <- tryCatch(
          t.test(diffs, alternative = alternative)$p.value,
          error = function(e) NA_real_
        )
      } else {
        x <- rnorm(N, d, 1)
        p <- tryCatch(
          t.test(x, mu = 0, alternative = alternative)$p.value,
          error = function(e) NA_real_
        )
      }
      sig[i] <- !is.na(p) && p < alpha
    }
    mean(sig)
  }

  power_vec <- vapply(n_range, sim_one, numeric(1))
  data.frame(N = n_range, power = power_vec, d = d)
}
