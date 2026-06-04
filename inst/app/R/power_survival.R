#' Simulation-based power for the log-rank test under proportional hazards
#'
#' Simulates exponential survival times for two groups (lambda and
#' lambda * HR), applies uniform random censoring, and runs survdiff.
#'
#' @param hr Hazard ratio of group 2 vs group 1 (>1 means group 2 fails faster).
#' @param lambda Baseline hazard (events per unit time) for group 1.
#' @param n_range Integer vector of per-group sample sizes.
#' @param accrual Total study duration in same time units as 1/lambda. Subjects
#'   are uniformly accrued over the period [0, accrual] and followed to time
#'   accrual + followup; everyone alive at end of follow-up is censored.
#' @param followup Additional follow-up after accrual ends.
#' @param dropout_rate Annualized dropout rate (independent exponential
#'   censoring). Set to 0 to disable.
#' @param alpha Significance threshold.
#' @param n_iter Monte Carlo iterations per sample size.
power_survival <- function(hr,
                           lambda = 0.1,
                           n_range,
                           accrual = 12,
                           followup = 12,
                           dropout_rate = 0,
                           alpha = 0.05,
                           n_iter = 500) {
  if (!requireNamespace("survival", quietly = TRUE)) {
    stop("The 'survival' package is required for log-rank power.")
  }
  if (hr <= 0) stop("HR must be > 0.")
  if (lambda <= 0) stop("lambda must be > 0.")
  total_time <- accrual + followup

  sim_one <- function(N) {
    sig <- logical(n_iter)
    for (i in seq_len(n_iter)) {
      t1 <- rexp(N, rate = lambda)
      t2 <- rexp(N, rate = lambda * hr)
      entry <- runif(2 * N, 0, accrual)
      drop <- if (dropout_rate > 0) rexp(2 * N, rate = dropout_rate) else rep(Inf, 2 * N)
      event_time <- c(t1, t2)
      admin_censor <- total_time - entry
      obs_time <- pmin(event_time, drop, admin_censor)
      status <- as.integer(event_time <= pmin(drop, admin_censor))
      grp <- factor(c(rep("A", N), rep("B", N)))
      if (sum(status) < 2) {
        sig[i] <- FALSE
        next
      }
      fit <- tryCatch(
        survival::survdiff(survival::Surv(obs_time, status) ~ grp),
        error = function(e) NULL
      )
      if (is.null(fit)) {
        sig[i] <- FALSE
        next
      }
      pval <- pchisq(fit$chisq, df = length(fit$n) - 1, lower.tail = FALSE)
      sig[i] <- !is.na(pval) && pval < alpha
    }
    mean(sig)
  }

  power_vec <- vapply(n_range, sim_one, numeric(1))
  data.frame(N = n_range, power = power_vec, hr = hr, lambda = lambda)
}
