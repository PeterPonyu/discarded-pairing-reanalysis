# Figure 2 -- the per-prompt values as lines across the three arms, and the one
# number per arm that the recorded comparison used printed beneath each arm.

levels_arm <- c("Jointly\ntrained", "Composed\nfrom two", "Cross-attention\nadapter only")

long <- rbind(
  data.frame(arm = levels_arm[1], prompt = pairs$prompt, value = pairs$base_identity),
  data.frame(arm = levels_arm[2], prompt = pairs$prompt, value = pairs$comp_identity),
  data.frame(arm = levels_arm[3], prompt = pairs$prompt, value = pairs$idon_identity)
)
long$arm <- factor(long$arm, levels = levels_arm)
long$label <- factor(rep(PROMPT_CODES, 3L), levels = PROMPT_CODES)
if (!identical(levels(long$label), names(PAL_PROMPTS))) {
  stop("the prompt palette does not enumerate the P1--P4 row codes")
}

dispersions <- data.frame(
  arm = factor(levels_arm, levels = levels_arm),
  sd = c(sd_base, sd_comp, sd_idon)
)
dispersions$text <- sprintf("dispersion\n%s", fmt(dispersions$sd, 4))

fig2 <- ggplot(long, aes(x = arm, y = value, group = label, colour = label)) +
  geom_line(linewidth = 0.5, alpha = 0.9) +
  geom_point(aes(shape = label), size = 1.9) +
  rtx_note(data = dispersions, inherit.aes = FALSE,
           aes(x = arm, y = 0.775, label = text)) +
  scale_colour_manual(values = PAL_PROMPTS, name = NULL) +
  scale_shape_manual(values = c(P1 = 16, P2 = 17, P3 = 15, P4 = 18), name = NULL) +
  scale_y_continuous(name = "Identity fidelity", limits = c(0.77, 0.885),
                     breaks = seq(0.78, 0.88, 0.02)) +
  scale_x_discrete(name = NULL) +
  guides(colour = guide_legend(nrow = 1)) +
  rtx_theme() +
  rtx_legend_bottom() +
  theme(axis.text.x = element_text(lineheight = 0.9))

save_fig(fig2, "fig2_collapse", FIGURE_TEXT_WIDTH_IN, 3.2)
