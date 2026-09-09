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
rows$concept_label <- factor(mapped, levels = c("dog", "clock"))
counts_by_concept <- table(as.character(rows$concept))
if (!identical(sort(names(counts_by_concept)), c("clock", "dog6")) ||
    any(as.integer(counts_by_concept) != 12L)) stop("fig9 requires 12 rows per concept")
if (length(unique(rows$seed)) != 3L || length(unique(rows$background_prompt)) != 4L) {
  stop("fig9 requires three seeds and four prompts")
}
rows$pair_id <- seq_len(nrow(rows))

long <- rbind(
  data.frame(pair_id = rows$pair_id, concept = rows$concept_label, seed = rows$seed,
             endpoint = "Identity fidelity", arm = "Jointly trained", value = rows$joint_identity),
  data.frame(pair_id = rows$pair_id, concept = rows$concept_label, seed = rows$seed,
             endpoint = "Identity fidelity", arm = "Composed", value = rows$composed_identity),
  data.frame(pair_id = rows$pair_id, concept = rows$concept_label, seed = rows$seed,
             endpoint = "Prompt fidelity", arm = "Jointly trained", value = rows$joint_prompt),
  data.frame(pair_id = rows$pair_id, concept = rows$concept_label, seed = rows$seed,
             endpoint = "Prompt fidelity", arm = "Composed", value = rows$composed_prompt)
)
long$endpoint <- factor(long$endpoint, levels = c("Identity fidelity", "Prompt fidelity"))
long$arm <- factor(long$arm, levels = c("Jointly trained", "Composed"))

counts <- aggregate(pair_id ~ endpoint + concept, long, function(x) length(unique(x)))
counts$label <- sprintf("n = %d pairs", counts$pair_id)

p <- ggplot(long, aes(x = arm, y = value, group = pair_id)) +
  geom_line(alpha = 0.35, colour = "grey35", linewidth = 0.35) +
  geom_point(aes(fill = arm), shape = 21, size = 1.8, stroke = 0.35) +
  facet_grid(endpoint ~ concept, scales = "free_y") +
  geom_text(data = counts, inherit.aes = FALSE,
            aes(x = 1.5, y = Inf, label = label), vjust = 1.3,
            size = FIGURE_ANNOTATION_SIZE, family = FIGURE_FONT_FAMILY,
            colour = "grey25") +
  scale_fill_manual(values = c("Jointly trained" = "white", "Composed" = "#B2182B"), name = NULL) +
  scale_y_continuous(name = "Recorded fidelity", expand = expansion(mult = c(0.08, 0.16))) +
  labs(x = NULL, subtitle = "Each slope is one matched prompt × seed pair; identity is primary") +
  rtx_theme() +
  theme(legend.position = "bottom", legend.text = element_text(size = 7),
        plot.subtitle = element_text(size = FIGURE_SUBTITLE_SIZE, colour = "grey25"),
        strip.text = element_text(size = FIGURE_STRIP_TEXT_SIZE),
        axis.text.x = element_text(size = 7.2))

save_fig(p, "fig9_concept_slopes", FIGURE_TEXT_WIDTH_IN, 3.35)
