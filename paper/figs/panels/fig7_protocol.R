# Figure 7 -- the protocol as a locked sequence, not a result.
#
# Everything in this diagram is a design choice already recorded in the bound
# protocol. It intentionally contains no observed value. Keeping the status
# banner in the same figure makes it difficult to mistake a specification for a
# completed experiment when the figure is lifted out of the manuscript.

if (!identical(as.integer(DESIGN_CONCEPTS), 2L) ||
    !identical(as.integer(N_PAIRS), 4L) ||
    !identical(as.integer(DESIGN_SEEDS), 3L) ||
    !identical(as.integer(DESIGN_PER_CONCEPT), 12L) ||
    !identical(as.integer(DESIGN_TOTAL), 24L) ||
    !identical(as.integer(2L * DESIGN_TOTAL), 48L) ||
    !identical(as.integer(DESIGN_TRAIN_RUNS), 6L)) {
  stop("protocol schematic constants no longer match the derived design")
}

if (!nzchar(as.character(predecl$declared_utc))) {
  stop("E-PREDECL lacks declared_utc")
}
if (is.null(paired$pairs_realised)) {
  stop("E-PAIRED lacks pairs_realised")
}

# Coordinates are in a unit square so that text placement is independent of
# the data ranges. Arrows describe the order in which a preregistered analyst
# encounters the objects; they are not causal arrows.
boxes <- data.frame(
  id = c("unit", "arms", "endpoints", "lock"),
  xmin = c(0.03, 0.265, 0.525, 0.785),
  xmax = c(0.235, 0.495, 0.755, 0.97),
  ymin = c(0.48, 0.48, 0.48, 0.48),
  ymax = c(0.80, 0.80, 0.80, 0.80),
  fill = c("#E8F1F8", "#F8E8E8", "#EAF4E6", "#EEE8F7"),
  border = c("#4D7EA8", "#B2182B", "#4D9221", "#7B5AA6"),
  stringsAsFactors = FALSE
)
boxes$xmid <- (boxes$xmin + boxes$xmax) / 2

box_text <- data.frame(
  x = boxes$xmid,
  y = c(0.64, 0.64, 0.64, 0.64),
  label = c(
    "PAIRING UNIT\nconcept × prompt\n× generation seed",
    "MATCHED ARMS\njoint: both attention types\ncomposed: cross + self",
    "ENDPOINTS + TESTS\nidentity difference (pooled primary)\nconcept strata descriptive\nprompt fidelity (secondary)\nexact sign test",
    "ANALYSIS LOCK\njoin by pair key\nlock then one unblind\nalpha = 0.05"
  ),
  stringsAsFactors = FALSE
)

arrows <- data.frame(
  x = boxes$xmax[c(1, 2, 3)] + 0.008,
  xend = boxes$xmin[c(2, 3, 4)] - 0.008,
  y = rep(0.64, 3),
  yend = rep(0.64, 3),
  label = c("define", "compare", "analyze"),
  stringsAsFactors = FALSE
)

# The lower strips are compact audits of the controls and design arithmetic.
# They are kept separate from the boxes so the counts cannot be mistaken for
# observed sample sizes from the historical run.
control_strip <- data.frame(
  xmin = 0.03, xmax = 0.97, ymin = 0.32, ymax = 0.43,
  stringsAsFactors = FALSE
)
control_line_one <- sprintf(
  "FIXED CONTROLS  |  same backbone  |  %s steps  |  learning rate %s  |  rank %s",
  thousands(train_joint$max_train_steps), fmt(train_joint$learning_rate, 4),
  train_joint$lora_rank
)
control_line_two <- sprintf(
  "resolution %s  |  training seed %s",
  train_joint$resolution, train_joint$seed
)

design_strip <- data.frame(
  xmin = 0.03, xmax = 0.97, ymin = 0.13, ymax = 0.25,
  stringsAsFactors = FALSE
)
design_line_one <- sprintf("DESIGN COUNTS (not observed)  |  %d concepts  |  %d prompts  |  %d seeds/prompt",
                           DESIGN_CONCEPTS, N_PAIRS, DESIGN_SEEDS)
design_line_two <- sprintf("%d pairs/concept  |  %d pairs total  |  %d generations",
                           DESIGN_PER_CONCEPT, DESIGN_TOTAL, 2L * DESIGN_TOTAL)

fig7 <- ggplot() +
  geom_rect(data = boxes, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill = boxes$fill, colour = boxes$border, linewidth = 0.65) +
  geom_text(data = box_text, aes(x = x, y = y, label = label),
            family = FIGURE_FONT_FAMILY, size = 3.0, lineheight = 0.98,
            colour = "#202020", fontface = "plain") +
  geom_segment(data = arrows, aes(x = x, xend = xend, y = y, yend = yend),
               colour = "#555555", linewidth = 0.45,
               arrow = grid::arrow(length = grid::unit(3.3, "pt"), type = "closed")) +
  geom_text(data = arrows, aes(x = (x + xend) / 2, y = y + 0.055, label = label),
            family = FIGURE_FONT_FAMILY, size = 2.35, colour = "#555555") +
  geom_rect(data = control_strip, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill = "#F8F8F8", colour = "#777777", linewidth = 0.35) +
  annotate("text", x = 0.5, y = 0.405, label = control_line_one,
           family = FIGURE_FONT_FAMILY, size = 2.25, fontface = "bold", colour = "#303030") +
  annotate("text", x = 0.5, y = 0.355, label = control_line_two,
           family = FIGURE_FONT_FAMILY, size = 2.25, colour = "#303030") +
  geom_rect(data = design_strip, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill = "#F3F3F3", colour = "#777777", linewidth = 0.4) +
  annotate("text", x = 0.5, y = 0.215, label = design_line_one,
           family = FIGURE_FONT_FAMILY, size = 2.25, fontface = "bold", colour = "#202020") +
  annotate("text", x = 0.5, y = 0.165, label = design_line_two,
           family = FIGURE_FONT_FAMILY, size = 2.45, colour = "#202020") +
  annotate("text", x = 0.5, y = 0.91,
           label = "PRE-REGISTERED SPECIFICATION — no result is shown",
           family = FIGURE_FONT_FAMILY, size = 3.35, fontface = "bold",
           colour = "#202020") +
  annotate("label", x = 0.5, y = 0.055,
           label = sprintf("DECLARED %s  ·  %d PAIRS REALISED",
                           predecl$declared_utc, as.integer(paired$pairs_realised)),
           family = FIGURE_FONT_FAMILY, size = 2.6, fontface = "bold",
           colour = "#1B4F72", fill = "#EAF3F8",
           label.padding = grid::unit(0.18, "lines")) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE, clip = "off") +
  labs(subtitle = "The protocol fixes the unit, arms, endpoints, and analysis before any new generation") +
  rtx_theme() +
  theme_void() +
  theme(
    text = element_text(family = FIGURE_FONT_FAMILY),
    plot.subtitle = element_text(family = FIGURE_FONT_FAMILY, size = 8.0,
                                 colour = "#555555", hjust = 0.5,
                                 margin = margin(b = 5)),
    plot.margin = margin(t = 8, r = 8, b = 16, l = 8)
  )

save_fig(fig7, "fig7_protocol", FIGURE_TEXT_WIDTH_IN, 4.15)
