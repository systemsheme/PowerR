#' Simulation-based power for one-way ANOVA
#'
#' Simulates k groups with specified means and a common SD, then runs aov().
#' Useful for dose-response designs with >=3 arms.
#'
#' @param means Numeric vector of true group means.
#' @param sd Common within-group SD (or vector of length k for unequal SDs).
#' @param n_range Integer vector of per-group sample sizes.
#' @param alpha Significance threshold.
#' @param n_iter Monte Carlo iterations per sample size.
power_anova <- function(means, sd, n_range, alpha = 0.05, n_iter = 500) {
  k <- length(means)
  if (k < 2) stop("Provide at least 2 group means.")
  if (length(sd) == 1) sd <- rep(sd, k)
  if (length(sd) != k) stop("sd must be length 1 or length(means).")
  if (any(sd <= 0)) stop("All SDs must be > 0.")

  sim_one <- function(N) {
    sig <- logical(n_iter)
    for (i in seq_len(n_iter)) {
      grp <- factor(rep(seq_len(k), each = N))
      y <- unlist(lapply(seq_len(k), function(g) rnorm(N, means[g], sd[g])))
      p <- tryCatch({
        summary(aov(y ~ grp))[[1]][["Pr(>F)"]][1]
      }, error = function(e) NA_real_)
      sig[i] <- !is.na(p) && p < alpha
    }
    mean(sig)
  }

  power_vec <- vapply(n_range, sim_one, numeric(1))

  # Cohen's f effect size for reference
  grand <- mean(means)
  f_effect <- sqrt(mean((means - grand)^2) / mean(sd^2))
  data.frame(N = n_range, power = power_vec, cohens_f = f_effect)
}
