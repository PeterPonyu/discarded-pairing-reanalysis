# Figure 9 -- paired slopes by concept and generation seed.
# The registered run is the only source: each segment joins the two arms for
# one concept, prompt and seed. Identity remains the primary endpoint and is
# shown before the declared secondary prompt-fidelity endpoint.

if (!exists("paired") || is.null(paired$pairs)) stop("E-PAIRED pair rows are required")

rows <- paired$pairs
if (nrow(rows) != as.integer(paired$pairs_realised)) stop("fig9 pair count drifted")
concept_lookup <- c(dog6 = "dog", clock = "clock")
mapped <- unname(concept_lookup[as.character(rows$concept)])
if (anyNA(mapped)) stop("fig9 encountered an unknown or missing concept")
counts_by_concept <- table(mapped)
if (!identical(sort(names(counts_by_concept)), c("clock", "dog")) ||
    any(as.integer(counts_by_concept) != 12L)) stop("fig9 requires 12 rows per concept")
if (length(unique(rows$seed)) != 3L || length(unique(rows$background_prompt)) != 4L) {
  stop("fig9 requires three seeds and four prompts")
}
rows$pair_id <- seq_len(nrow(rows))

# The pair count is carried in the column strip rather than drawn inside the
# panel, where it competed with the highest points.
concept_strip <- c(dog = sprintf("dog (%d pairs)", counts_by_concept[["dog"]]),
                   clock = sprintf("clock (%d pairs)", counts_by_concept[["clock"]]))
rows$concept_label <- factor(concept_strip[mapped], levels = unname(concept_strip))

endpoint_levels <- c("Identity fidelity\n(registered primary)", "Prompt fidelity\n(secondary)")
direction_levels <- c("Composed lower", "Composed higher")
arm_levels <- c("Jointly trained", "Composed")

stack_endpoint <- function(endpoint, joint, composed, diff) {
  if (any(diff == 0)) stop("fig9 found a tied pair; the sign of the slope is undefined")
  base <- data.frame(pair_id = rows$pair_id, concept = rows$concept_label,
                     endpoint = endpoint,
                     direction = ifelse(diff < 0, direction_levels[1], direction_levels[2]),
                     stringsAsFactors = FALSE)
  rbind(cbind(base, arm = arm_levels[1], value = joint),
        cbind(base, arm = arm_levels[2], value = composed))
}
long <- rbind(
  stack_endpoint(endpoint_levels[1], rows$joint_identity, rows$composed_identity, rows$identity_diff),
  stack_endpoint(endpoint_levels[2], rows$joint_prompt, rows$composed_prompt, rows$prompt_diff)
)
long$endpoint <- factor(long$endpoint, levels = endpoint_levels)
long$arm <- factor(long$arm, levels = arm_levels)
long$direction <- factor(long$direction, levels = direction_levels)

# The drawn directions must be the bound counts, or the colours lie.
drawn_lower <- tapply(long$direction == direction_levels[1], long$endpoint, sum) / 2L
if (!identical(as.integer(drawn_lower[[endpoint_levels[1]]]), as.integer(ident_run$composed_lower)) ||
    !identical(as.integer(drawn_lower[[endpoint_levels[2]]]), as.integer(prompt_run$composed_lower))) {
  stop("fig9 slope directions do not reproduce the bound composed-lower counts")
}

p <- ggplot(long, aes(x = arm, y = value, group = pair_id)) +
  geom_line(aes(colour = direction), alpha = 0.75, linewidth = 0.45) +
  geom_point(aes(fill = arm), shape = 21, size = 1.8, stroke = 0.4, colour = "grey15") +
  facet_grid(endpoint ~ concept, scales = "free_y") +
  scale_colour_manual(values = c("Composed lower" = PAL_LOWER, "Composed higher" = PAL_HIGHER),
                      name = NULL) +
  scale_fill_manual(values = c("Jointly trained" = "white", "Composed" = "grey25"), name = NULL) +
  scale_x_discrete(name = NULL, expand = expansion(add = 0.45)) +
  scale_y_continuous(name = "Recorded fidelity", expand = expansion(mult = c(0.08, 0.08))) +
  guides(colour = guide_legend(nrow = 1, order = 1),
         fill = guide_legend(nrow = 1, order = 2, override.aes = list(size = 2.2))) +
  rtx_theme() +
  rtx_legend_bottom() +
  theme(strip.text.y = element_text(lineheight = 0.9),
        panel.spacing.x = unit(10, "pt"),
        plot.margin = margin(t = 6, r = 12, b = 4, l = 6))

save_fig(p, "fig9_concept_slopes", 0.8 * FIGURE_TEXT_WIDTH_IN, 3.35)
