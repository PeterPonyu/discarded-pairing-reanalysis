# Figure 5 -- how small a two-sided sign-test p can get at a given number of
# pairs, before the data are seen at all.  The pair axis runs to the size the
# registered run realised, so the historical floor and the realised floor sit
# on the same curve.

if (!exists("FLOOR_AT_REALISED") || !exists("PAIRS_REALISED") ||
    !exists("DESIGN_POOLED_TOLERANCE")) {
  stop("fig5 needs the realised floor, the realised pair count and the pooled tolerance")
}
if (abs(FLOOR_AT_REALISED - attainable_p(PAIRS_REALISED)) > 1e-15) {
  stop("the realised floor is not the all-agreeing floor at the realised pair count")
}

grid_n <- 3:PAIRS_REALISED
floor_curves <- do.call(rbind, lapply(0:2, function(k) {
  data.frame(n = grid_n, discordant = k, p = attainable_p(grid_n, discordant = k),
             stringsAsFactors = FALSE)
}))
series_levels <- c("every pair agrees", "one pair disagrees", "two pairs disagree")
floor_curves$series <- factor(series_levels[floor_curves$discordant + 1], levels = series_levels)
floor_curves <- floor_curves[floor_curves$p <= 1, ]

# Four marked sizes, lettered on the curves and explained in a key that sits in
# the empty region above the curves, so no leader has to cross a curve.  Every
# number in the key is the derived constant the manuscript prints.
floor_decimal <- formatC(FLOOR_AT_REALISED, format = "f", digits = 8)
floor_one_in <- thousands(round(1 / FLOOR_AT_REALISED))
if (!identical(floor_decimal, "0.00000012") || !identical(floor_one_in, "8,388,608")) {
  stop("the realised floor no longer prints as 0.00000012 = 1 in 8,388,608; re-read the key text")
}

marks <- data.frame(
  letter = c("a", "b", "c", "d"),
  n = c(N_PAIRS, MIN_N_ANY, DESIGN_PER_CONCEPT, PAIRS_REALISED),
  discordant = c(0, 0, DESIGN_TOLERANCE, 0),
  stringsAsFactors = FALSE
)
marks$p <- attainable_p(marks$n, discordant = marks$discordant)
if (abs(marks$p[4] - FLOOR_AT_REALISED) > 1e-15) stop("mark d is not the realised floor")
# Letters sit just above-right of their mark, except c, which sits below-right
# so it stays clear of the key printed above the two-discordant curve.
marks$letter_y <- marks$p * c(1.9, 1.9, 1 / 1.9, 1.9)

key <- data.frame(
  letter = c("a", "b", "c", "d", ""),
  text = c(
    sprintf("the recorded comparison: %d pairs cannot reach %s", N_PAIRS, fmt(ALPHA)),
    sprintf("%d pairs is the first size that can, only if every pair agrees", MIN_N_ANY),
    sprintf("the design per concept: %d pairs, of which %d may disagree",
            DESIGN_PER_CONCEPT, DESIGN_TOLERANCE),
    sprintf("the registered run pooled: %d pairs, of which %d may disagree;",
            PAIRS_REALISED, DESIGN_POOLED_TOLERANCE),
    sprintf("its floor is %s, one in %s", floor_decimal, floor_one_in)
  ),
  stringsAsFactors = FALSE
)
# Rows are spaced 0.38 decades apart from the top of the key downwards; the
# lowest row still clears the alpha rule and the two-discordant curve.
KEY_X <- 11.3
KEY_TOP <- 3.0
key$y <- KEY_TOP / 10^(0.38 * (seq_len(nrow(key)) - 1))

fig5 <- ggplot(floor_curves, aes(x = n, y = p, colour = series)) +
  geom_hline(yintercept = ALPHA, linetype = "22", linewidth = 0.4, colour = PAL_RULE) +
  geom_line(aes(group = series), linewidth = 0.55) +
  geom_point(aes(shape = series), size = 1.2) +
  geom_point(data = marks, inherit.aes = FALSE, aes(x = n, y = p), size = 3.0, shape = 21,
             fill = "white", colour = "grey20", stroke = 0.7) +
  geom_text(data = marks, inherit.aes = FALSE,
            aes(x = n + 0.45, y = letter_y, label = letter), hjust = 0, vjust = 0.5,
            size = FIGURE_ANNOTATION_SIZE, fontface = "bold", colour = "grey20",
            family = FIGURE_FONT_FAMILY) +
  geom_text(data = key, inherit.aes = FALSE,
            aes(x = KEY_X, y = y, label = letter), hjust = 0, vjust = 0.5,
            size = FIGURE_ANNOTATION_SIZE, fontface = "bold", colour = "grey20",
            family = FIGURE_FONT_FAMILY) +
  rtx_note(data = key, inherit.aes = FALSE,
           aes(x = KEY_X + 0.75, y = y, label = text), hjust = 0, vjust = 0.5) +
  annotate("text", x = 26.3, y = ALPHA, hjust = 1, vjust = 1.5, size = FIGURE_ANNOTATION_SIZE,
           colour = PAL_RULE, family = FIGURE_FONT_FAMILY,
           label = sprintf("alpha = %s", fmt(ALPHA))) +
  scale_colour_manual(values = setNames(PAL_ORDERED3, series_levels), name = NULL) +
  scale_shape_manual(values = setNames(c(16, 17, 15), series_levels), name = NULL) +
  scale_y_continuous(name = "Smallest attainable two-sided p (log scale)", trans = "log10",
                     limits = c(6e-8, 4.2),
                     breaks = c(1e-7, 1e-6, 1e-5, 1e-4, 1e-3, 1e-2, ALPHA, 1),
                     labels = c("0.0000001", "0.000001", "0.00001", "0.0001",
                                "0.001", "0.01", "0.05", "1")) +
  scale_x_continuous(name = "Pairs in the comparison", breaks = seq(4, PAIRS_REALISED, 2),
                     limits = c(2.5, 26.5), expand = c(0, 0)) +
  guides(colour = guide_legend(nrow = 1)) +
  rtx_theme() +
  rtx_legend_bottom()

save_fig(fig5, "fig5_floor", FIGURE_TEXT_WIDTH_IN, 3.8)
