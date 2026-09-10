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
# encounters the objects; they are not causal arrows.  Box widths follow the
# longest line each box has to hold, at the shared 8 pt cell size, so no line
# can run past its border.
boxes <- data.frame(
  id = c("unit", "arms", "endpoints", "lock"),
  xmin = c(0.020, 0.250, 0.500, 0.815),
  xmax = c(0.215, 0.465, 0.780, 0.980),
  ymin = 0.555,
  ymax = 0.865,
  heading = c("PAIRING UNIT", "MATCHED ARMS", "ENDPOINTS AND TESTS", "ANALYSIS LOCK"),
  body = c(
    "one concept\n\u00d7 one background prompt\n\u00d7 one generation seed",
    "joint: one adapter,\nboth attention types\ncomposed: cross + self\nadapters, same budget",
    sprintf("primary: identity difference,\npooled exact sign test at %s\nsecondary: prompt fidelity\nconcept strata descriptive",
            fmt(ALPHA)),
    "join by pair key\nlock, then one\nunblinding\nno re-run"
  ),
  stringsAsFactors = FALSE
)
boxes$xmid <- (boxes$xmin + boxes$xmax) / 2

arrows <- data.frame(
  x = boxes$xmax[1:3] + 0.006,
  xend = boxes$xmin[2:4] - 0.006,
  y = (boxes$ymin[1] + boxes$ymax[1]) / 2
)

# The lower strips are compact audits of the controls and design arithmetic.
# They are kept separate from the boxes so the counts cannot be mistaken for
# observed sample sizes from the historical run.
strips <- data.frame(
  xmin = 0.020, xmax = 0.980,
  ymin = c(0.385, 0.215),
  ymax = c(0.500, 0.330),
  heading = c("FIXED CONTROLS, SHARED BY EVERY ARM", "DESIGN COUNTS, DECLARED BEFORE THE RUN"),
  body = c(
    sprintf("same backbone  \u00b7  %s training steps  \u00b7  learning rate %s  \u00b7  rank %s  \u00b7  resolution %s  \u00b7  training seed %s",
            thousands(train_joint$max_train_steps), fmt(train_joint$learning_rate, 4),
            train_joint$lora_rank, train_joint$resolution, train_joint$seed),
    sprintf("%d concepts  \u00b7  %d background prompts  \u00b7  %d seeds per prompt  \u00b7  %d pairs per concept  \u00b7  %d pairs in total  \u00b7  %d generations",
            DESIGN_CONCEPTS, N_PAIRS, DESIGN_SEEDS, DESIGN_PER_CONCEPT, DESIGN_TOTAL, 2L * DESIGN_TOTAL)
  ),
  stringsAsFactors = FALSE
)

fig7 <- ggplot() +
  geom_rect(data = boxes, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill = "#F3F5F7", colour = "grey30", linewidth = 0.5) +
  geom_text(data = boxes, aes(x = xmid, y = ymax - 0.045, label = heading),
            family = FIGURE_FONT_FAMILY, size = FIGURE_CELL_SIZE, fontface = "bold",
            colour = "black", vjust = 1) +
  geom_text(data = boxes, aes(x = xmid, y = ymax - 0.115, label = body),
            family = FIGURE_FONT_FAMILY, size = FIGURE_ANNOTATION_SIZE, lineheight = 1.0,
            colour = "#202020", vjust = 1) +
  geom_segment(data = arrows, aes(x = x, xend = xend, y = y, yend = y),
               colour = "grey30", linewidth = 0.5,
               arrow = grid::arrow(length = grid::unit(3.4, "pt"), type = "closed")) +
  geom_rect(data = strips, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill = "#FAFAFA", colour = "grey50", linewidth = 0.4) +
  geom_text(data = strips, aes(x = 0.5, y = ymax - 0.028, label = heading),
            family = FIGURE_FONT_FAMILY, size = FIGURE_ANNOTATION_SIZE, fontface = "bold",
            colour = "#303030", vjust = 1) +
  geom_text(data = strips, aes(x = 0.5, y = ymin + 0.030, label = body),
            family = FIGURE_FONT_FAMILY, size = FIGURE_ANNOTATION_SIZE,
            colour = "#202020", vjust = 0) +
  annotate("text", x = 0.5, y = 0.955,
           label = "PRE-REGISTERED SPECIFICATION \u2014 no result is shown",
           family = FIGURE_FONT_FAMILY, size = 3.2, fontface = "bold",
           colour = "#202020") +
  annotate("label", x = 0.5, y = 0.095,
           label = sprintf("DECLARED %s  \u00b7  %d PAIRS REALISED",
                           predecl$declared_utc, as.integer(paired$pairs_realised)),
           family = FIGURE_FONT_FAMILY, size = FIGURE_ANNOTATION_SIZE, fontface = "bold",
           colour = "#1B4F72", fill = "#EAF3F8", linewidth = 0.35,
           label.padding = grid::unit(0.22, "lines")) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE, clip = "off") +
  theme_void(base_family = FIGURE_FONT_FAMILY) +
  theme(
    text = element_text(family = FIGURE_FONT_FAMILY),
    plot.margin = margin(t = 4, r = 4, b = 4, l = 4)
  )

save_fig(fig7, "fig7_protocol", FIGURE_TEXT_WIDTH_IN, 3.4)
