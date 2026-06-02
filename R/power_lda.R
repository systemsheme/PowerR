#' Simulation-based power for Limiting Dilution Analysis (LDA)
#'
#' Models responders/non-responders across dose groups under a Poisson
#' single-hit assumption (Hu & Smyth 2009), then tests whether two
#' conditions have different active-cell frequencies using the ELDA-style
#' likelihood-ratio test on a complementary log-log GLM with log(dose) offset.
#'
#' Three input modes:
#'  - "frequency": user supplies f1 and f2 (active cell frequencies, e.g.
#'    1/1000 means one stem cell per 1000 plated cells). Responder
#'    probability at dose d is 1 - exp(-d * f).
#'  - "fold_change": user supplies a reference frequency f_ref and a
#'    fold-change FC; group 2 has frequency f_ref / FC (rarer means larger
#'    1/f). Internally converted to frequency mode.
#'  - "direct_prob": user supplies vectors of per-dose response
#'    probabilities for each group. Bypasses the Poisson model but still
#'    uses the same LRT.
#'
#' @param doses Numeric vector of doses (cells per injection).
#' @param mode One of "frequency", "fold_change", "direct_prob".
#' @param f1,f2 Active cell frequencies (mode = "frequency").
#' @param f_ref Reference frequency (mode = "fold_change").
#' @param fold_change Fold-change of group 2 vs reference (>1 means rarer).
#' @param p1,p2 Response probability vectors aligned with `doses`
#'   (mode = "direct_prob").
#' @param n_range Integer vector of mice-per-dose values to evaluate (each
#'   value is applied to every dose, in both groups).
#' @param alpha Significance threshold.
#' @param n_iter Monte Carlo iterations per sample size.
#'
#' @return data.frame with columns N (mice per dose per group), power, and
#'   the model parameters used for the run.
power_lda <- function(doses,
                      mode = c("frequency", "fold_change", "direct_prob"),
                      f1 = NULL, f2 = NULL,
                      f_ref = NULL, fold_change = NULL,
                      p1 = NULL, p2 = NULL,
                      n_range,
                      alpha = 0.05,
                      n_iter = 500) {
  mode <- match.arg(mode)
  if (any(doses <= 0)) stop("All doses must be > 0.")

  if (mode == "frequency") {
    if (is.null(f1) || is.null(f2)) stop("frequency mode needs f1 and f2.")
    if (f1 <= 0 || f2 <= 0) stop("Frequencies must be > 0.")
    p1 <- 1 - exp(-doses * f1)
    p2 <- 1 - exp(-doses * f2)
  } else if (mode == "fold_change") {
    if (is.null(f_ref) || is.null(fold_change)) {
      stop("fold_change mode needs f_ref and fold_change.")
    }
    if (f_ref <= 0 || fold_change <= 0) stop("f_ref and FC must be > 0.")
    f1 <- f_ref
    f2 <- f_ref / fold_change
    p1 <- 1 - exp(-doses * f1)
    p2 <- 1 - exp(-doses * f2)
  } else {
    if (is.null(p1) || is.null(p2)) stop("direct_prob mode needs p1, p2.")
    if (length(p1) != length(doses) || length(p2) != length(doses)) {
      stop("p1 and p2 must align with doses.")
    }
    if (any(p1 < 0 | p1 > 1) || any(p2 < 0 | p2 > 1)) {
      stop("All probabilities must be in [0, 1].")
    }
  }

  lda_lrt <- function(r, n, dose, group) {
    # Reduced model: groups share the same frequency
    # Full model: groups have distinct frequencies
    # cloglog link with log(dose) offset gives the Poisson single-hit model.
    df <- data.frame(r = r, nr = n - r, dose = dose, group = factor(group))
    df <- df[df$dose > 0, , drop = FALSE]
    offset_term <- log(df$dose)
    fit_full <- tryCatch(
      suppressWarnings(
        glm(cbind(r, nr) ~ group, family = binomial(link = "cloglog"),
            offset = offset_term, data = df)
      ),
      error = function(e) NULL
    )
    fit_red <- tryCatch(
      suppressWarnings(
        glm(cbind(r, nr) ~ 1, family = binomial(link = "cloglog"),
            offset = offset_term, data = df)
      ),
      error = function(e) NULL
    )
    if (is.null(fit_full) || is.null(fit_red)) return(NA_real_)
    lr <- fit_red$deviance - fit_full$deviance
    if (!is.finite(lr) || lr < 0) return(NA_real_)
    pchisq(lr, df = 1, lower.tail = FALSE)
  }

  sim_one <- function(N) {
    sig <- logical(n_iter)
    n_per <- rep(N, length(doses))
    for (i in seq_len(n_iter)) {
      r1 <- rbinom(length(doses), n_per, p1)
      r2 <- rbinom(length(doses), n_per, p2)
      r <- c(r1, r2)
      n <- c(n_per, n_per)
      d <- c(doses, doses)
      g <- c(rep("A", length(doses)), rep("B", length(doses)))
      pval <- lda_lrt(r, n, d, g)
      sig[i] <- !is.na(pval) && pval < alpha
    }
    mean(sig)
  }

  power_vec <- vapply(n_range, sim_one, numeric(1))
  out <- data.frame(N = n_range, power = power_vec)
  out$mode <- mode
  if (!is.null(f1)) out$f1 <- f1
  if (!is.null(f2)) out$f2 <- f2
  out
}
