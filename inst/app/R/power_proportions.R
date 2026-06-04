#' Simulation-based power for two-proportion test
#'
#' Simulates Binomial(N, p) outcomes in each group and runs a two-proportion
#' z-test (prop.test) or Fisher's exact test per iteration. Suited to
#' detecting differences in event frequencies (e.g., % CD69+ cells).
#'
#' @param p1,p2 True proportions in each group.
#' @param n_range Integer vector of per-group sample sizes.
#' @param test "prop_test" (chi-square, with continuity correction off) or
#'   "fisher" (exact).
#' @param alternative "two.sided", "less", "greater".
#' @param alpha Significance threshold.
#' @param n_iter Monte Carlo iterations per sample size.
power_proportions <- function(p1, p2, n_range,
                              test = c("prop_test", "fisher"),
                              alternative = "two.sided",
                              alpha = 0.05,
                              n_iter = 500) {
  test <- match.arg(test)
  if (p1 < 0 || p1 > 1 || p2 < 0 || p2 > 1) {
    stop("p1 and p2 must be in [0, 1].")
  }

  sim_one <- function(N) {
    sig <- logical(n_iter)
    for (i in seq_len(n_iter)) {
      x1 <- rbinom(1, N, p1)
      x2 <- rbinom(1, N, p2)
      tab <- matrix(c(x1, N - x1, x2, N - x2), nrow = 2, byrow = TRUE)
      p <- tryCatch({
        if (test == "prop_test") {
          suppressWarnings(prop.test(c(x1, x2), c(N, N),
                                     alternative = alternative,
                                     correct = FALSE)$p.value)
        } else {
          fisher.test(tab, alternative = alternative)$p.value
        }
      }, error = function(e) NA_real_)
      sig[i] <- !is.na(p) && p < alpha
    }
    mean(sig)
  }

  power_vec <- vapply(n_range, sim_one, numeric(1))
  data.frame(N = n_range, power = power_vec, p1 = p1, p2 = p2)
}
