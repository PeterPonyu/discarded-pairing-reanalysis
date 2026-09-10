# Figure 8 -- the registered paired run: 24 identity and 24 prompt differences.
#
# Two panels, one per endpoint, at the rank the protocol gave them.  Panel A is
# the registered primary (identity fidelity) and takes the larger share of the
# measure (1.85:1); Panel B is the declared secondary (prompt fidelity), drawn
# narrower and on a tinted panel so a reader cannot mistake it for a second
# primary.

run_pairs <- paired$pairs
if (!identical(nrow(run_pairs), as.integer(paired$pairs_realised))) {
  stop("fig8 pair table length does not match pairs_realised")
}
if (is.null(ident_run$mean_diff_ci95) || is.null(prompt_run$mean_diff_ci95) ||
    is.null(ident_run$mean_diff) || is.null(prompt_run$mean_diff)) {
  stop("E-PAIRED lacks the mean paired difference or its interval for an endpoint")
}

concept_label <- c(dog6 = "dog", clock = "clock")
POOLED_ROW <- "pooled\nmean"
# Discrete rows read top-down as dog, clock, then the pooled summary.
row_levels <- c(POOLED_ROW, "clock", "dog")
run_pairs$concept_lab <- factor(concept_label[as.character(run_pairs$concept)],
                                levels = row_levels)
if (anyNA(run_pairs$concept_lab)) stop("fig8 encountered an unknown concept")

# Within a concept the three generation seeds are drawn on three fixed sub-rows
# (seed order from the top), so the spread is structure rather than jitter and
# the same pair lands in the same place on every rebuild.
seed_levels <- sort(unique(as.integer(run_pairs$seed)))
if (length(seed_levels) != 3L) stop("fig8 expects exactly three generation seeds")
SEED_OFFSET <- c(0.24, 0, -0.24)
run_pairs$y <- as.numeric(run_pairs$concept_lab) +
  SEED_OFFSET[match(as.integer(run_pairs$seed), seed_levels)]

build_endpoint <- function(diff, summary, strip, ci_digits, p_digits, point_size, tinted) {
  d <- data.frame(y = run_pairs$y, diff = diff, stringsAsFactors = FALSE)
  d$side <- factor(ifelse(d$diff < 0, "Composed lower", "Composed higher"),
                   levels = c("Composed lower", "Composed higher"))
  if (!identical(sum(d$diff < 0), as.integer(summary$composed_lower))) {
    stop("the drawn lower count does not match the bound summary for ", strip)
  }
  ci <- as.numeric(summary$mean_diff_ci95)
  band <- data.frame(lower = ci[1], upper = ci[2], estimate = as.numeric(summary$mean_diff))
  band$note <- sprintf("%d of %d pairs lower, p = %s\nmean %s, 95%% CI %s to %s",
                       as.integer(summary$composed_lower), as.integer(paired$pairs_realised),
                       fmt(summary$sign_test_two_sided_p, p_digits),
                       fmt(band$estimate, ci_digits), fmt(ci[1], ci_digits), fmt(ci[2], ci_digits))
  d$strip <- strip
  band$strip <- strip
  BAND_HALF <- 0.30
  ground <- if (tinted) "grey95" else "white"
  p <- ggplot(d, aes(x = diff, y = y)) +
    geom_vline(xintercept = 0, linetype = "22", linewidth = 0.4, colour = PAL_RULE) +
    geom_rect(data = band, inherit.aes = FALSE,
              aes(xmin = lower, xmax = upper, ymin = 1 - BAND_HALF, ymax = 1 + BAND_HALF),
              fill = "grey82", colour = NA) +
    geom_segment(data = band, inherit.aes = FALSE,
                 aes(x = estimate, xend = estimate, y = 1 - BAND_HALF, yend = 1 + BAND_HALF),
                 linewidth = 0.6, colour = "grey20") +
    geom_point(aes(colour = side, shape = side), size = point_size, stroke = 0.6) +
    # A label rather than bare text: its ground, matched to the panel, masks the
    # zero rule where the note would otherwise be struck through by it.
    geom_label(data = band, inherit.aes = FALSE,
               aes(x = -Inf, y = 1 - BAND_HALF - 0.2, label = note), hjust = -0.02, vjust = 1,
               size = FIGURE_ANNOTATION_SIZE, colour = PAL_NOTE, family = FIGURE_FONT_FAMILY,
               lineheight = 0.95, fill = ground, linewidth = 0,
               label.padding = grid::unit(0.12, "lines")) +
    facet_wrap(~strip) +
    scale_colour_manual(values = c("Composed lower" = PAL_LOWER, "Composed higher" = PAL_HIGHER),
                        name = NULL, drop = FALSE) +
    scale_shape_manual(values = c("Composed lower" = 1, "Composed higher" = 16),
                       name = NULL, drop = FALSE) +
    scale_x_continuous(name = "Composed arm minus jointly trained arm",
                       expand = expansion(mult = 0.08)) +
    scale_y_continuous(name = NULL, breaks = seq_along(row_levels), labels = row_levels,
                       limits = c(1 - BAND_HALF - 1.25, length(row_levels) + 0.55),
                       expand = c(0, 0)) +
    # The two panels draw their points at different sizes; the legend keys are
    # pinned to one size so patchwork can collect the two legends into one.
    guides(colour = guide_legend(nrow = 1, override.aes = list(size = 2.1)),
           shape = guide_legend(nrow = 1)) +
    rtx_theme() +
    rtx_legend_bottom() +
    theme(panel.grid.major.y = element_blank(),
          axis.text.y = element_text(lineheight = 0.9))
  if (tinted) {
    p <- p + theme(panel.background = element_rect(fill = "grey95", colour = NA),
                   strip.text = element_text(colour = "grey30"),
                   axis.text.y = element_blank(),
                   axis.ticks.y = element_blank())
  }
  p
}

left <- build_endpoint(run_pairs$identity_diff, ident_run,
                       "Identity fidelity (registered primary)",
                       ci_digits = 3, p_digits = 2, point_size = 2.1, tinted = FALSE)
right <- build_endpoint(run_pairs$prompt_diff, prompt_run,
                        "Prompt fidelity (secondary)",
                        ci_digits = 3, p_digits = 5, point_size = 1.8, tinted = TRUE)

fig8 <- patchwork::wrap_plots(panel_label(left, "A"), panel_label(right, "B"),
                              widths = c(1.85, 1)) +
  patchwork::plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

save_fig(fig8, "fig8_paired_run", FIGURE_TEXT_WIDTH_IN, 4.15)
