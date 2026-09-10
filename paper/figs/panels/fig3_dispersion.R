# Figure 3 -- the recorded comparison, carried through to the interval its own
# four generations per arm support.

forest <- data.frame(
  contrast = c("Composed from two\nversus jointly trained",
               "Cross-attention adapter only\nversus jointly trained"),
  ratio = c(sd_comp / sd_base, sd_idon / sd_base),
  lower = c(disp_comp$sd_lower, disp_idon$sd_lower),
  upper = c(disp_comp$sd_upper, disp_idon$sd_upper),
  p = c(disp_comp$p, disp_idon$p),
  stringsAsFactors = FALSE
)
# The arm colours of the rest of the paper: the composed arm and the
# cross-attention adapter alone.
forest$colour <- c(PAL_COMPOSED, PAL_CROSS)
forest$contrast <- factor(forest$contrast, levels = rev(forest$contrast))
forest$note <- sprintf("ratio %s, 95%% interval %s to %s, p = %s",
                       fmt(forest$ratio), fmt(forest$lower), fmt(forest$upper), fmt(forest$p))

fig3 <- ggplot(forest, aes(x = ratio, y = contrast)) +
  geom_vline(xintercept = 1, linetype = "22", linewidth = 0.4, colour = PAL_RULE) +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y", width = 0.14,
                linewidth = 0.5) +
  geom_point(aes(colour = contrast), size = 2.4, show.legend = FALSE) +
  scale_colour_manual(values = setNames(forest$colour, as.character(forest$contrast))) +
  # A label rather than bare text: its white ground masks the equal-dispersion
  # rule where the note crosses it.
  geom_label(aes(label = note), vjust = -1.2, size = FIGURE_ANNOTATION_SIZE, colour = PAL_NOTE,
             family = FIGURE_FONT_FAMILY, fill = "white", linewidth = 0,
             label.padding = grid::unit(0.1, "lines")) +
  # The rule's label sits beside the rule rather than across it, in the empty
  # strip under the lower interval.
  annotate("text", x = 1.06, y = 0.48, label = "equal dispersion", hjust = 0, vjust = 0,
           size = FIGURE_ANNOTATION_SIZE, colour = PAL_RULE, family = FIGURE_FONT_FAMILY) +
  scale_x_continuous(name = "Ratio of dispersion across background prompts (log scale)",
                     trans = "log10", limits = c(0.08, 12),
                     breaks = c(0.1, 0.25, 0.5, 1, 2, 4, 8),
                     labels = c("0.1", "0.25", "0.5", "1", "2", "4", "8")) +
  scale_y_discrete(name = NULL, expand = expansion(add = c(0.7, 0.6))) +
  rtx_theme() +
  theme(axis.text.y = element_text(lineheight = 0.9))

save_fig(fig3, "fig3_dispersion", 0.9 * FIGURE_TEXT_WIDTH_IN, 2.7)
