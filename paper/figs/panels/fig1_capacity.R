# Figure 1 -- the two arms train the same parameters, split or not.

capacity <- rbind(
  data.frame(arm = "Jointly trained", part = "Trained as one adapter",
             params = train_joint$trainable_params, stringsAsFactors = FALSE),
  data.frame(arm = "Composed from two", part = "Cross-attention adapter",
             params = train_cross$trainable_params, stringsAsFactors = FALSE),
  data.frame(arm = "Composed from two", part = "Self-attention adapter",
             params = train_self$trainable_params, stringsAsFactors = FALSE)
)
capacity$arm <- factor(capacity$arm, levels = c("Composed from two", "Jointly trained"))
capacity$part <- factor(capacity$part, levels = c("Trained as one adapter",
                                                  "Cross-attention adapter",
                                                  "Self-attention adapter"))

total_m <- split_sum / 1e6

fig1 <- ggplot(capacity, aes(x = arm, y = params / 1e6, fill = part)) +
  geom_col(width = 0.52, colour = "white", linewidth = 0.3,
           position = position_stack(reverse = TRUE)) +
  geom_text(aes(label = thousands(params)), size = FIGURE_CELL_SIZE, colour = "white",
            position = position_stack(vjust = 0.5, reverse = TRUE)) +
  geom_hline(yintercept = total_m, linetype = "22", linewidth = 0.4, colour = PAL_RULE) +
  annotate("text", x = 2.42, y = total_m, hjust = 1.03, vjust = 0.5,
           size = FIGURE_ANNOTATION_SIZE, colour = PAL_NOTE,
           label = sprintf("%s trainable parameters, either way", thousands(split_sum))) +
  coord_flip() +
  scale_fill_manual(values = c("Trained as one adapter" = PAL_JOINT,
                               "Cross-attention adapter" = PAL_CROSS,
                               "Self-attention adapter" = PAL_SELF),
                    name = NULL) +
  scale_y_continuous(name = "Trainable parameters (millions)",
                     limits = c(0, total_m * 1.02), expand = c(0, 0)) +
  scale_x_discrete(name = NULL, expand = expansion(add = c(0.6, 0.95))) +
  guides(fill = guide_legend(nrow = 1)) +
  rtx_theme() +
  rtx_legend_bottom()

save_fig(fig1, "fig1_capacity", FIGURE_TEXT_WIDTH_IN, 2.4)
