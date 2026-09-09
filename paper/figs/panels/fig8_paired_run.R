# Figure 8 -- the registered paired run: 24 identity and prompt differences.

run_pairs <- paired$pairs
if (!identical(nrow(run_pairs), as.integer(paired$pairs_realised))) {
  stop("fig8 pair table length does not match pairs_realised")
}

concept_label <- c(dog6 = "dog", clock = "clock")
run_pairs$concept_lab <- factor(concept_label[as.character(run_pairs$concept)],
                                levels = c("dog", "clock"))

endpoints <- rbind(
  data.frame(endpoint = "Identity fidelity",
             concept = run_pairs$concept_lab,
             diff = run_pairs$identity_diff,
             stringsAsFactors = FALSE),
  data.frame(endpoint = "Prompt fidelity",
             concept = run_pairs$concept_lab,
             diff = run_pairs$prompt_diff,
             stringsAsFactors = FALSE)
)
endpoints$endpoint <- factor(endpoints$endpoint,
                             levels = c("Identity fidelity", "Prompt fidelity"))
endpoints$side <- ifelse(endpoints$diff < 0, "Composed lower", "Composed higher")

summaries <- data.frame(
  endpoint = factor(c("Identity fidelity", "Prompt fidelity"),
                    levels = levels(endpoints$endpoint)),
  note = c(
    sprintf("%d of %d pairs lower\nsign test p = %s",
            ident_run$composed_lower, as.integer(paired$pairs_realised),
            fmt(ident_run$sign_test_two_sided_p)),
    sprintf("%d of %d pairs lower\nsign test p = %s",
            prompt_run$composed_lower, as.integer(paired$pairs_realised),
            fmt(prompt_run$sign_test_two_sided_p, 5))
  ),
  stringsAsFactors = FALSE
)

fig8 <- ggplot(endpoints, aes(x = diff, y = concept)) +
  geom_vline(xintercept = 0, linetype = "22", linewidth = 0.4, colour = "grey30") +
  geom_jitter(aes(colour = side, shape = side),
              position = position_jitter(height = 0.12, width = 0, seed = 20260907),
              size = 1.7) +
  geom_text(data = summaries, inherit.aes = FALSE,
            aes(x = -Inf, y = Inf, label = note),
            hjust = -0.04, vjust = 1.25, size = FIGURE_ANNOTATION_SIZE,
            colour = "grey25", lineheight = 0.95,
            family = FIGURE_FONT_FAMILY) +
  facet_wrap(~endpoint, ncol = 2, scales = "free_x") +
  scale_colour_manual(values = c("Composed lower" = "#B2182B", "Composed higher" = "#4D7EA8"),
                      name = NULL) +
  scale_shape_manual(values = c("Composed lower" = 1, "Composed higher" = 16),
                     name = NULL) +
  scale_x_continuous(name = "Composed arm minus jointly trained arm",
                     expand = expansion(mult = 0.10)) +
  scale_y_discrete(name = NULL) +
  guides(colour = guide_legend(nrow = 1)) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.text = element_text(size = 7),
        legend.key.size = unit(0.3, "cm"), legend.margin = margin(t = -2),
        axis.text.y = element_text(size = 8.0),
        strip.text = element_text(size = 8.5))

save_fig(fig8, "fig8_paired_run", FIGURE_TEXT_WIDTH_IN, 3.40)
