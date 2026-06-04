`%||%` <- function(a, b) if (is.null(a)) b else a

#' Linearly interpolate the smallest N at which power crosses `target`.
#'
#' Walks the (sorted) N–power pairs and returns the interpolated x where the
#' curve first reaches `target`. Returns NA if power never reaches target.
#' Monte Carlo noise is handled by taking the first crossing from below.
crossing_n <- function(N, power, target) {
  N <- as.numeric(N); power <- as.numeric(power)
  o <- order(N)
  N <- N[o]; power <- power[o]
  if (length(N) == 0) return(NA_real_)
  ok <- which(power >= target)
  if (length(ok) == 0) return(NA_real_)
  i <- ok[1]
  if (i == 1) return(N[1])
  x0 <- N[i - 1]; x1 <- N[i]
  y0 <- power[i - 1]; y1 <- power[i]
  if (y1 == y0) return(x1)
  x0 + (target - y0) * (x1 - x0) / (y1 - y0)
}

#' Same as crossing_n, but also returns the integer ceiling (practical N).
crossings_table <- function(power_df, target = 0.8) {
  if (is.null(power_df) || nrow(power_df) == 0) {
    return(data.frame(group = character(0), n_star = numeric(0),
                      n_int = integer(0)))
  }
  if ("group" %in% names(power_df)) {
    split_df <- split(power_df, power_df$group)
    out <- do.call(rbind, lapply(names(split_df), function(g) {
      d <- split_df[[g]]
      ns <- crossing_n(d$N, d$power, target)
      data.frame(group = g, n_star = ns,
                 n_int = if (is.na(ns)) NA_integer_ else as.integer(ceiling(ns)))
    }))
  } else {
    ns <- crossing_n(power_df$N, power_df$power, target)
    out <- data.frame(group = "all", n_star = ns,
                      n_int = if (is.na(ns)) NA_integer_ else as.integer(ceiling(ns)))
  }
  out
}

# Prism-flavored qualitative palette (color-blind friendly).
PRISM_PALETTE <- c(
  "#1F77B4", "#E31A1C", "#33A02C", "#FF7F00",
  "#6A3D9A", "#A6761D", "#1B9E77", "#666666"
)

#' Prism-style ggplot theme.
prism_theme <- function(base_size = 16) {
  ggplot2::theme_classic(base_size = base_size) +
    ggplot2::theme(
      axis.line       = ggplot2::element_line(linewidth = 0.9, colour = "black"),
      axis.ticks      = ggplot2::element_line(linewidth = 0.9, colour = "black"),
      axis.ticks.length = ggplot2::unit(0.28, "cm"),
      axis.text       = ggplot2::element_text(colour = "black",
                                              size = base_size),
      axis.title.x    = ggplot2::element_text(face = "bold",
                                              size = base_size * 1.15,
                                              margin = ggplot2::margin(t = 8)),
      axis.title.y    = ggplot2::element_text(face = "bold",
                                              size = base_size * 1.15,
                                              margin = ggplot2::margin(r = 8)),
      plot.title      = ggplot2::element_text(face = "bold",
                                              size = base_size * 1.2,
                                              hjust = 0.5,
                                              margin = ggplot2::margin(b = 10)),
      plot.subtitle   = ggplot2::element_text(size = base_size * 0.95,
                                              hjust = 0.5,
                                              colour = "#444444"),
      # Title/subtitle/caption position relative to the whole plot (including
      # any side legend) rather than just the panel, so wide titles do not
      # get clipped on the left when a right-side legend is present.
      plot.title.position    = "plot",
      plot.caption.position  = "plot",
      legend.text     = ggplot2::element_text(size = base_size * 0.9),
      legend.title    = ggplot2::element_text(face = "bold",
                                              size = base_size * 0.95),
      legend.key.width  = ggplot2::unit(1.2, "cm"),
      legend.background = ggplot2::element_blank(),
      legend.position = "right",
      plot.margin     = ggplot2::margin(18, 22, 14, 14)
    )
}

#' Draw a Prism-style power curve, highlighting the target-power crossing.
#'
#' @param power_df data.frame with N, power, and optionally `group`.
#' @param target Target power for the horizontal reference and crossing.
#' @param show_crossings If TRUE, draw a labeled vertical line at each
#'   group's interpolated crossing point.
#' @param border_color One of NA / NULL / "" (no border, just axes — Prism
#'   open style) or a colour spec (named or hex) to draw a full panel
#'   border in that colour.
#' @param x_label_angle Rotation of x-axis tick labels in degrees.
#' @param x_tick_mode "auto" (ggplot pretty breaks) or "all" (one tick at
#'   every simulated N).
power_curve <- function(power_df, target = 0.8,
                        xlab = "Sample size (per group)",
                        ylab = "Power",
                        title = NULL,
                        subtitle = NULL,
                        group_lab = NULL,
                        base_size = 16,
                        show_crossings = TRUE,
                        border_color = NA,
                        x_label_angle = 0,
                        x_tick_mode = c("auto", "all")) {
  x_tick_mode <- match.arg(x_tick_mode)
  if (is.null(power_df) || nrow(power_df) == 0) {
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::ggtitle("No results to plot."))
  }
  has_group <- "group" %in% names(power_df) &&
    length(unique(power_df$group)) > 0

  base <- if (has_group) {
    ggplot2::ggplot(
      power_df,
      ggplot2::aes(x = N, y = power,
                   colour = factor(group), group = factor(group))
    )
  } else {
    ggplot2::ggplot(power_df, ggplot2::aes(x = N, y = power))
  }

  p <- base +
    ggplot2::annotate("rect", xmin = -Inf, xmax = Inf,
                      ymin = target, ymax = 1.02,
                      fill = "#e8f4ec", alpha = 0.45) +
    ggplot2::geom_hline(yintercept = target, linetype = "dashed",
                        colour = "#1F77B4", linewidth = 0.7) +
    ggplot2::annotate("text",
                      x = min(power_df$N),
                      y = target + 0.025,
                      label = sprintf("target power = %.2f", target),
                      hjust = 0, size = base_size * 0.28,
                      colour = "#1F77B4", fontface = "italic") +
    ggplot2::geom_line(linewidth = 1.2) +
    ggplot2::geom_point(size = 2.8, stroke = 0.6)

  if (show_crossings) {
    cr <- crossings_table(power_df, target)
    cr <- cr[!is.na(cr$n_star), , drop = FALSE]
    if (nrow(cr) > 0) {
      cr$label <- sprintf("N ≈ %d", cr$n_int)
      n_g <- nrow(cr)
      cr$y_label <- 0.06 + (seq_len(n_g) - 1) * 0.07
      if (has_group) {
        p <- p +
          ggplot2::geom_segment(
            data = cr,
            ggplot2::aes(x = n_star, xend = n_star,
                         y = 0, yend = target,
                         colour = factor(group)),
            linetype = "dotted", linewidth = 0.8,
            inherit.aes = FALSE, show.legend = FALSE
          ) +
          ggplot2::geom_point(
            data = cr,
            ggplot2::aes(x = n_star, y = target,
                         colour = factor(group)),
            size = 3.6, shape = 21, fill = "white", stroke = 1.4,
            inherit.aes = FALSE, show.legend = FALSE
          ) +
          ggplot2::geom_label(
            data = cr,
            ggplot2::aes(x = n_star, y = y_label,
                         label = label, colour = factor(group)),
            fill = "white", fontface = "bold",
            size = base_size * 0.32,
            label.padding = ggplot2::unit(0.3, "lines"),
            label.r = ggplot2::unit(0.15, "lines"),
            inherit.aes = FALSE, show.legend = FALSE
          )
      } else {
        accent <- "#E31A1C"
        p <- p +
          ggplot2::geom_segment(
            data = cr,
            ggplot2::aes(x = n_star, xend = n_star,
                         y = 0, yend = target),
            linetype = "dotted", linewidth = 0.8, colour = accent,
            inherit.aes = FALSE
          ) +
          ggplot2::geom_point(
            data = cr,
            ggplot2::aes(x = n_star, y = target),
            size = 3.8, shape = 21, fill = "white", stroke = 1.4,
            colour = accent, inherit.aes = FALSE
          ) +
          ggplot2::geom_label(
            data = cr,
            ggplot2::aes(x = n_star, y = y_label, label = label),
            fill = "white", colour = accent, fontface = "bold",
            size = base_size * 0.32,
            label.padding = ggplot2::unit(0.3, "lines"),
            label.r = ggplot2::unit(0.15, "lines"),
            inherit.aes = FALSE
          )
      }
    }
  }

  x_scale <- if (x_tick_mode == "all") {
    ggplot2::scale_x_continuous(
      breaks = sort(unique(power_df$N)),
      expand = ggplot2::expansion(mult = c(0.02, 0.04))
    )
  } else {
    ggplot2::scale_x_continuous(
      breaks = scales::pretty_breaks(n = 7),
      expand = ggplot2::expansion(mult = c(0.02, 0.04))
    )
  }

  thm <- prism_theme(base_size = base_size)

  border_on <- !is.null(border_color) && length(border_color) == 1 &&
    !is.na(border_color) && nzchar(border_color)
  if (border_on) {
    thm <- thm + ggplot2::theme(
      axis.line     = ggplot2::element_blank(),
      panel.border  = ggplot2::element_rect(colour = border_color,
                                            fill = NA, linewidth = 1.1),
      axis.ticks    = ggplot2::element_line(linewidth = 0.9,
                                            colour = border_color)
    )
  }

  if (!is.null(x_label_angle) && is.finite(x_label_angle) && x_label_angle != 0) {
    thm <- thm + ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = x_label_angle,
        hjust = if (x_label_angle >= 90) 0.5 else 1,
        vjust = if (x_label_angle >= 90) 0.5 else 1,
        size  = base_size
      )
    )
  }

  p <- p +
    ggplot2::scale_colour_manual(values = PRISM_PALETTE) +
    ggplot2::scale_y_continuous(limits = c(0, 1.02),
                                breaks = seq(0, 1, 0.2),
                                expand = c(0, 0)) +
    x_scale +
    ggplot2::labs(x = xlab, y = ylab, title = title, subtitle = subtitle,
                  colour = group_lab %||% "Group") +
    thm

  p
}

#' Smallest tested N achieving target power (legacy helper).
min_n_for_power <- function(power_df, target = 0.8) {
  ok <- power_df$power >= target
  if (!any(ok)) return(NA_integer_)
  as.integer(min(power_df$N[ok]))
}
