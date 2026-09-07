# Figure 2 -- the per-prompt values on the left, the one number per arm that the
# recorded comparison used on the right.

levels_arm <- c("Jointly\ntrained", "Composed\nfrom two", "Cross-attention\nadapter only")

long <- rbind(
  data.frame(arm = levels_arm[1], prompt = pairs$prompt, value = pairs$base_identity),
  data.frame(arm = levels_arm[2], prompt = pairs$prompt, value = pairs$comp_identity),
  data.frame(arm = levels_arm[3], prompt = pairs$prompt, value = pairs$idon_identity)
)
long$arm <- factor(long$arm, levels = levels_arm)
long$label <- rep(PROMPT_CODES, 3L)

dispersions <- data.frame(
  arm = factor(levels_arm, levels = levels_arm),
  sd = c(sd_base, sd_comp, sd_idon)
)
dispersions$text <- sprintf("dispersion\n%s", fmt(dispersions$sd, 4))

fig2 <- ggplot(long, aes(x = arm, y = value, group = label, colour = label)) +
  geom_line(linewidth = 0.45, alpha = 0.85) +
  geom_point(size = 1.5) +
  geom_text(data = dispersions, inherit.aes = FALSE, aes(x = arm, y = 0.775, label = text),
            size = 2.5, colour = "grey25", lineheight = 0.95) +
  scale_colour_manual(values = c("#4D7EA8", "#B2182B", "#4D9221", "#8C6BB1"), name = NULL) +
  scale_y_continuous(name = "Identity fidelity", limits = c(0.77, 0.885),
                     breaks = seq(0.78, 0.88, 0.02)) +
  scale_x_discrete(name = NULL) +
  guides(colour = guide_legend(nrow = 1)) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.text = element_text(size = 7),
        legend.key.size = unit(0.3, "cm"), legend.margin = margin(t = -2),
        axis.text.x = element_text(size = 7.5, lineheight = 0.9))

save_fig(fig2, "fig2_collapse", FIGURE_TEXT_WIDTH_IN, 3.2)
