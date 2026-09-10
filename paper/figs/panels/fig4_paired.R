# Figure 4 -- the same generations, analysed as the pairs they were run as.

endpoints <- rbind(
  data.frame(endpoint = "Identity fidelity", prompt = pairs$prompt, diff = pairs$d_identity,
             stringsAsFactors = FALSE),
  data.frame(endpoint = "Prompt fidelity", prompt = pairs$prompt, diff = pairs$d_prompt,
             stringsAsFactors = FALSE)
)
# The pair rows read top-down as P1..P4; a fifth row beneath them carries the
# mean paired difference and its interval, so the summary has a row of its own
# instead of being drawn under the last pair.
SUMMARY_ROW <- "mean"
row_levels <- c(SUMMARY_ROW, rev(PROMPT_CODES))
endpoints$label <- factor(rep(PROMPT_CODES, 2L), levels = row_levels)
endpoints$side <- factor(ifelse(endpoints$diff < 0, "Composed lower", "Composed higher"),
                         levels = c("Composed lower", "Composed higher"))

summaries <- data.frame(
  endpoint = c("Identity fidelity", "Prompt fidelity"),
  estimate = c(identity_t$estimate, prompt_t$estimate),
  lower = c(identity_t$lower, prompt_t$lower),
  upper = c(identity_t$upper, prompt_t$upper),
  down = c(identity_sign$negative, prompt_sign$negative),
  sign_p = c(identity_sign$p, prompt_sign$p),
  stringsAsFactors = FALSE
)
summaries$note <- sprintf("mean %s, 95%% interval %s to %s\n%d of %d pairs lower, sign test p = %s",
                          fmt(summaries$estimate, 3), fmt(summaries$lower, 3),
                          fmt(summaries$upper, 3), summaries$down, N_PAIRS,
                          fmt(summaries$sign_p, 3))
summaries$label <- factor(SUMMARY_ROW, levels = row_levels)

BAND_HALF <- 0.30
NOTE_Y <- 1 - BAND_HALF - 0.22

fig4 <- ggplot(endpoints, aes(x = diff, y = label)) +
  geom_vline(xintercept = 0, linetype = "22", linewidth = 0.4, colour = PAL_RULE) +
  geom_rect(data = summaries, inherit.aes = FALSE,
            aes(xmin = lower, xmax = upper, ymin = 1 - BAND_HALF, ymax = 1 + BAND_HALF),
            fill = "grey85", colour = NA) +
  geom_segment(data = summaries, inherit.aes = FALSE,
               aes(x = estimate, xend = estimate, y = 1 - BAND_HALF, yend = 1 + BAND_HALF),
               linewidth = 0.6, colour = "grey20") +
  geom_point(aes(colour = side, shape = side), size = 2.1, stroke = 0.6) +
  # A label rather than bare text: its white ground masks the zero rule where
  # the note would otherwise be struck through by it.
  geom_label(data = summaries, inherit.aes = FALSE,
             aes(x = -Inf, y = NOTE_Y, label = note), hjust = -0.02, vjust = 1,
             size = FIGURE_ANNOTATION_SIZE, colour = PAL_NOTE, family = FIGURE_FONT_FAMILY,
             lineheight = 0.95, fill = "white", linewidth = 0,
             label.padding = grid::unit(0.12, "lines")) +
  facet_wrap(~endpoint, ncol = 2, scales = "free_x") +
  scale_colour_manual(values = c("Composed lower" = PAL_LOWER, "Composed higher" = PAL_HIGHER),
                      name = NULL) +
  scale_shape_manual(values = c("Composed lower" = 1, "Composed higher" = 16),
                     name = NULL) +
  scale_x_continuous(name = "Composed arm minus jointly trained arm",
                     expand = expansion(mult = 0.09)) +
  scale_y_discrete(name = NULL, drop = FALSE, expand = expansion(add = c(1.35, 0.6))) +
  guides(colour = guide_legend(nrow = 1)) +
  rtx_theme() +
  rtx_legend_bottom()

save_fig(fig4, "fig4_paired", FIGURE_TEXT_WIDTH_IN, 3.0)
