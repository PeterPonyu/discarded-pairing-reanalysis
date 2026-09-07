# Figure 6 -- a paired two-endpoint change map.  It keeps the two recorded
# fidelity coordinates separate and does not turn four prompts into a trend.

if (!identical(as.integer(N_PAIRS), 4L)) {
  stop("the endpoint-change map is defined for the recorded four prompts")
}

prompt_code <- paste0("P", seq_len(N_PAIRS))
delta <- rbind(
  data.frame(prompt_code = prompt_code, arm = "Composed minus joint",
             delta_prompt = pairs$d_prompt,
             delta_identity = pairs$d_identity,
             stringsAsFactors = FALSE),
  data.frame(prompt_code = prompt_code, arm = "Cross-only minus joint",
             delta_prompt = pairs$idon_prompt - pairs$base_prompt,
             delta_identity = pairs$idon_identity - pairs$base_identity,
             stringsAsFactors = FALSE)
)
delta$arm <- factor(delta$arm,
                    levels = c("Composed minus joint", "Cross-only minus joint"))

if (any(!is.finite(delta$delta_prompt)) ||
    any(!is.finite(delta$delta_identity)) || nrow(delta) != 2L * N_PAIRS) {
  stop("the endpoint-change map contains a non-finite or incomplete cell")
}

# The bound record is used to illustrate that the two endpoints need not move
# together.  Keep this descriptive statement fail-closed if the evidence is
# ever replaced by a different four-row record.
if (!all(pairs$d_prompt < 0) ||
    !any(pairs$d_identity < 0) || !any(pairs$d_identity > 0)) {
  stop("the recorded endpoint-change pattern is not the one described here")
}

# A vector from the origin to each point is a compact reminder that both axes
# are within-prompt changes.  The arrow has no temporal or causal meaning.
delta$label_x <- delta$delta_prompt +
  ifelse(delta$arm == levels(delta$arm)[1], 1, -1) *
  max(0.004, diff(range(delta$delta_prompt)) * 0.035)
delta$label_y <- delta$delta_identity +
  ifelse(delta$arm == levels(delta$arm)[1], 1, -1) *
  max(0.003, diff(range(delta$delta_identity)) * 0.035)

segments <- transform(delta, x = 0, y = 0,
                      xend = delta_prompt, yend = delta_identity)
max_abs <- max(abs(c(delta$delta_prompt, delta$delta_identity)))
plot_limit <- ceiling((max_abs * 1.20) * 100) / 100
if (!is.finite(plot_limit) || plot_limit <= 0) stop("invalid endpoint-change range")
axis_breaks <- pretty(c(-plot_limit, plot_limit), n = 5)

p <- ggplot(delta, aes(x = delta_prompt, y = delta_identity)) +
  geom_hline(yintercept = 0, linewidth = 0.35, colour = "grey45") +
  geom_vline(xintercept = 0, linewidth = 0.35, colour = "grey45") +
  geom_segment(data = segments, inherit.aes = FALSE,
               aes(x = x, y = y, xend = xend, yend = yend, colour = arm),
               linewidth = 0.35, alpha = 0.8,
               arrow = grid::arrow(length = grid::unit(3, "pt"), type = "closed")) +
  geom_point(aes(colour = arm, shape = arm), size = 2.5, stroke = 0.45) +
  geom_text(aes(x = label_x, y = label_y, label = prompt_code, colour = arm),
            size = 2.35, show.legend = FALSE) +
  scale_colour_manual(values = c("Composed minus joint" = "#B2182B",
                                 "Cross-only minus joint" = "#4D9221"),
                      name = NULL) +
  scale_shape_manual(values = c("Composed minus joint" = 17,
                                "Cross-only minus joint" = 15), name = NULL) +
  scale_x_continuous(name = "Change in prompt fidelity (fidelity-score units)",
                     limits = c(-plot_limit, plot_limit), breaks = axis_breaks,
                     expand = c(0, 0)) +
  scale_y_continuous(name = "Change in identity fidelity (fidelity-score units)",
                     limits = c(-plot_limit, plot_limit), breaks = axis_breaks,
                     expand = c(0, 0)) +
  labs(subtitle = "n = 4 recorded prompt pairs (P1--P4); zero means no within-prompt change") +
  guides(colour = guide_legend(nrow = 1), shape = guide_legend(nrow = 1)) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.text = element_text(size = 7),
        legend.key.size = unit(0.3, "cm"), legend.margin = margin(t = -2),
        axis.text = element_text(size = 7.2),
        plot.subtitle = element_text(size = 7.1, colour = "grey25"))

save_fig(p, "fig6_tradeoff", FIGURE_TEXT_WIDTH_IN, 3.85)
