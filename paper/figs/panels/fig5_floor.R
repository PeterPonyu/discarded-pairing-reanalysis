# Figure 5 -- how small a two-sided sign-test p can get at a given number of
# pairs, before the data are seen at all.

grid_n <- 3:18
floor_curves <- do.call(rbind, lapply(0:2, function(k) {
  data.frame(n = grid_n, discordant = k, p = attainable_p(grid_n, discordant = k),
             stringsAsFactors = FALSE)
}))
floor_curves$series <- factor(
  c("every pair agrees", "one pair disagrees", "two pairs disagree")[floor_curves$discordant + 1],
  levels = c("every pair agrees", "one pair disagrees", "two pairs disagree")
)
floor_curves <- floor_curves[floor_curves$p <= 1, ]

# Labels sit in the empty regions and are joined to their points by leaders, so
# no annotation crosses a curve it is not about.
marks <- data.frame(
  n = c(N_PAIRS, MIN_N_ANY, DESIGN_PER_CONCEPT),
  discordant = c(0, 0, DESIGN_TOLERANCE),
  text_x = c(6.4, 6.4, 12.6),
  text_y = c(1.7e-4, 1.2e-5, 0.62),
  label = c(sprintf("the recorded comparison:\n%d pairs cannot reach %s", N_PAIRS, fmt(ALPHA)),
            sprintf("%d pairs is the first size that can,\nand only if every pair agrees",
                    MIN_N_ANY),
            sprintf("the pre-registered design: %d pairs\nper concept, of which %d may still\ndisagree",
                    DESIGN_PER_CONCEPT, DESIGN_TOLERANCE)),
  stringsAsFactors = FALSE
)
marks$p <- attainable_p(marks$n, discordant = marks$discordant)

fig5 <- ggplot(floor_curves, aes(x = n, y = p, colour = series)) +
  geom_hline(yintercept = ALPHA, linetype = "22", linewidth = 0.4, colour = "grey30") +
  geom_vline(xintercept = N_PAIRS, linetype = "22", linewidth = 0.35, colour = "grey40") +
  geom_line(linewidth = 0.5) +
  geom_point(size = 0.9) +
  geom_segment(data = marks, inherit.aes = FALSE,
               aes(x = n, y = p, xend = text_x - 0.15, yend = text_y),
               linewidth = 0.25, colour = "grey55") +
  geom_point(data = marks, inherit.aes = FALSE, aes(x = n, y = p), size = 2.6, shape = 21,
             fill = "white", colour = "grey20", stroke = 0.7) +
  geom_text(data = marks, inherit.aes = FALSE,
            aes(x = text_x, y = text_y, label = label), hjust = 0, vjust = 0.5,
            size = 2.4, colour = "grey25", lineheight = 0.95) +
  annotate("text", x = 3, y = ALPHA, hjust = 0, vjust = -0.6, size = 2.5, colour = "grey30",
           label = sprintf("alpha = %s", fmt(ALPHA))) +
  annotate("text", x = N_PAIRS, y = 1.25, hjust = 0.5, vjust = 0,
           size = 2.35, colour = "grey35", label = sprintf("recorded n = %d", N_PAIRS)) +
  scale_colour_manual(values = c("every pair agrees" = "#B2182B",
                                 "one pair disagrees" = "#4D7EA8",
                                 "two pairs disagree" = "#4D9221"), name = NULL) +
  scale_y_continuous(name = "Smallest attainable two-sided p", trans = "log10",
                     limits = c(5e-6, 2.2),
                     breaks = c(1e-5, 1e-4, 1e-3, 1e-2, ALPHA, 1),
                     labels = c("0.00001", "0.0001", "0.001", "0.01", "0.05", "1")) +
  scale_x_continuous(name = "Pairs in the comparison", breaks = seq(4, 18, 2),
                     expand = expansion(add = c(0.6, 0.6))) +
  guides(colour = guide_legend(nrow = 1)) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.text = element_text(size = 7),
        legend.key.size = unit(0.3, "cm"), legend.margin = margin(t = -2))

save_fig(fig5, "fig5_floor", FIGURE_TEXT_WIDTH_IN, 3.4)
