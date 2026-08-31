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
  geom_text(aes(label = thousands(params)), size = 2.6, colour = "white",
            position = position_stack(vjust = 0.5, reverse = TRUE)) +
  geom_hline(yintercept = total_m, linetype = "22", linewidth = 0.4, colour = "grey25") +
  annotate("text", x = 2.42, y = total_m, hjust = 1.03, vjust = 0.5, size = 2.6,
           colour = "grey25",
           label = sprintf("%s trainable parameters, either way", thousands(split_sum))) +
  coord_flip() +
  scale_fill_manual(values = c("Trained as one adapter" = "grey45",
                               "Cross-attention adapter" = "#4D7EA8",
                               "Self-attention adapter" = "#B2182B"),
                    name = NULL) +
  scale_y_continuous(name = "Trainable parameters (millions)",
                     limits = c(0, total_m * 1.02), expand = c(0, 0)) +
  scale_x_discrete(name = NULL, expand = expansion(add = c(0.6, 0.95))) +
  guides(fill = guide_legend(nrow = 1)) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.text = element_text(size = 7),
        legend.key.size = unit(0.3, "cm"), legend.margin = margin(t = -2))

save_fig(fig1, "fig1_capacity", FIGURE_TEXT_WIDTH_IN, 2.4)
