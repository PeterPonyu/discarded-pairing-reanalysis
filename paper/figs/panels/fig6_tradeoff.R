# Figure 6 -- a paired two-endpoint change map.  It keeps the two recorded
# fidelity coordinates separate and does not turn four prompts into a trend.

if (!identical(as.integer(N_PAIRS), 4L)) {
  stop("the endpoint-change map is defined for the recorded four prompts")
}

prompt_code <- paste0("P", seq_len(N_PAIRS))
arm_levels <- c("Composed minus joint", "Cross-attention only minus joint")
delta <- rbind(
  data.frame(prompt_code = prompt_code, arm = arm_levels[1],
             delta_prompt = pairs$d_prompt,
             delta_identity = pairs$d_identity,
             stringsAsFactors = FALSE),
  data.frame(prompt_code = prompt_code, arm = arm_levels[2],
             delta_prompt = pairs$idon_prompt - pairs$base_prompt,
             delta_identity = pairs$idon_identity - pairs$base_identity,
             stringsAsFactors = FALSE)
)
delta$arm <- factor(delta$arm, levels = arm_levels)

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

# Both axes are the same quantity in the same units, so the map is drawn with
# equal scaling and symmetric limits: a change of 0.05 is the same length in
# either direction.
max_abs <- max(abs(c(delta$delta_prompt, delta$delta_identity)))
plot_limit <- ceiling((max_abs * 1.18) * 100) / 100
if (!is.finite(plot_limit) || plot_limit <= 0) stop("invalid endpoint-change range")
axis_breaks <- pretty(c(-plot_limit, plot_limit), n = 5)

# A vector from the origin to each point is a compact reminder that both axes
# are within-prompt changes.  The arrow has no temporal or causal meaning.  Each
# shaft stops a fixed distance short of its marker so the head stays visible
# instead of being hidden under the point.
ARROW_GAP <- plot_limit * 0.045
delta$len <- sqrt(delta$delta_prompt^2 + delta$delta_identity^2)
if (any(delta$len <= ARROW_GAP)) stop("a change vector is too short to draw with a visible head")
segments <- transform(delta, x = 0, y = 0,
                      xend = delta_prompt * (1 - ARROW_GAP / len),
                      yend = delta_identity * (1 - ARROW_GAP / len))

# Row codes sit just outside each marker, on the side away from the origin.
label_push <- plot_limit * 0.07
delta$label_x <- delta$delta_prompt + label_push * delta$delta_prompt / delta$len
delta$label_y <- delta$delta_identity + label_push * delta$delta_identity / delta$len

p <- ggplot(delta, aes(x = delta_prompt, y = delta_identity)) +
  geom_hline(yintercept = 0, linewidth = 0.35, colour = "grey45") +
  geom_vline(xintercept = 0, linewidth = 0.35, colour = "grey45") +
  geom_segment(data = segments, inherit.aes = FALSE,
               aes(x = x, y = y, xend = xend, yend = yend, colour = arm),
               linewidth = 0.4, alpha = 0.85,
               arrow = grid::arrow(length = grid::unit(3.2, "pt"), type = "closed")) +
  geom_point(aes(colour = arm, shape = arm), size = 2.6, stroke = 0.45) +
  geom_text(aes(x = label_x, y = label_y, label = prompt_code, colour = arm),
            size = FIGURE_ANNOTATION_SIZE, show.legend = FALSE) +
  scale_colour_manual(values = setNames(c(PAL_COMPOSED, PAL_CROSS), arm_levels), name = NULL) +
  scale_shape_manual(values = setNames(c(17, 15), arm_levels), name = NULL) +
  scale_x_continuous(name = "Change in prompt fidelity (fidelity-score units)",
                     limits = c(-plot_limit, plot_limit), breaks = axis_breaks,
                     expand = c(0, 0)) +
  scale_y_continuous(name = "Change in identity fidelity (fidelity-score units)",
                     limits = c(-plot_limit, plot_limit), breaks = axis_breaks,
                     expand = c(0, 0)) +
  coord_fixed(ratio = 1, clip = "off") +
  guides(colour = guide_legend(nrow = 1), shape = guide_legend(nrow = 1)) +
  rtx_theme() +
  rtx_legend_bottom()

save_fig(p, "fig6_tradeoff", 0.66 * FIGURE_TEXT_WIDTH_IN, 4.25)
