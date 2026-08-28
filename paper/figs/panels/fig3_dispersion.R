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
forest$contrast <- factor(forest$contrast, levels = rev(forest$contrast))
forest$note <- sprintf("ratio %s, interval %s to %s, p = %s",
                       fmt(forest$ratio), fmt(forest$lower), fmt(forest$upper), fmt(forest$p))

fig3 <- ggplot(forest, aes(x = ratio, y = contrast)) +
  geom_vline(xintercept = 1, linetype = "22", linewidth = 0.4, colour = "grey30") +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y", width = 0.12,
                linewidth = 0.45) +
  geom_point(size = 2.2, colour = "#B2182B") +
  geom_text(aes(label = note), vjust = -1.5, size = 2.5, colour = "grey25") +
  annotate("text", x = 1, y = 0.55, label = "no difference in dispersion", size = 2.5,
           colour = "grey30", vjust = 0) +
  scale_x_continuous(name = "Ratio of dispersion across background prompts",
                     trans = "log10", limits = c(0.09, 12),
                     breaks = c(0.1, 0.25, 0.5, 1, 2, 4, 8),
                     labels = c("0.1", "0.25", "0.5", "1", "2", "4", "8")) +
  scale_y_discrete(name = NULL, expand = expansion(add = c(0.75, 0.55))) +
  rtx_theme() +
  theme(axis.text.y = element_text(size = 7.5, lineheight = 0.9))

save_fig(fig3, "fig3_dispersion", 6.1, 2.7)
