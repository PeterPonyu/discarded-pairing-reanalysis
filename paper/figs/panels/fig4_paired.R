# Figure 4 -- the same generations, analysed as the pairs they were run as.

endpoints <- rbind(
  data.frame(endpoint = "Identity fidelity", prompt = pairs$prompt, diff = pairs$d_identity,
             stringsAsFactors = FALSE),
  data.frame(endpoint = "Prompt fidelity", prompt = pairs$prompt, diff = pairs$d_prompt,
             stringsAsFactors = FALSE)
)
endpoints$label <- factor(rep(PROMPT_CODES, 2L),
                          levels = rev(PROMPT_CODES))
endpoints$side <- ifelse(endpoints$diff < 0, "Composed lower", "Composed higher")

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
summaries$note <- sprintf("n = %d pairs; %s", N_PAIRS, summaries$note)

# The interval band and the note that reads it share the strip below the last
# pair, so their positions are set against each other here rather than each
# being placed independently.  The note hangs from just under the band: anchored
# by its bottom instead, a two-line note grows upward into the band and the mean
# marker is drawn through the middle of the text.
BAND_BOTTOM <- 0.52
BAND_TOP <- 0.86
NOTE_GAP <- 0.12

fig4 <- ggplot(endpoints, aes(x = diff, y = label)) +
  geom_vline(xintercept = 0, linetype = "22", linewidth = 0.4, colour = "grey30") +
  geom_rect(data = summaries, inherit.aes = FALSE,
            aes(xmin = lower, xmax = upper, ymin = BAND_BOTTOM, ymax = BAND_TOP),
            fill = "grey85", colour = NA) +
  geom_segment(data = summaries, inherit.aes = FALSE,
               aes(x = estimate, xend = estimate, y = BAND_BOTTOM, yend = BAND_TOP),
               linewidth = 0.5, colour = "grey20") +
  geom_point(aes(colour = side, shape = side), size = 1.9) +
  geom_text(data = summaries, inherit.aes = FALSE,
            aes(x = -Inf, y = BAND_BOTTOM - NOTE_GAP, label = note),
            hjust = -0.04, vjust = 1, size = FIGURE_ANNOTATION_SIZE,
            colour = "grey25", lineheight = 0.95) +
  facet_wrap(~endpoint, ncol = 2, scales = "free_x") +
  scale_colour_manual(values = c("Composed lower" = "#B2182B", "Composed higher" = "#4D7EA8"),
                      name = NULL) +
  scale_shape_manual(values = c("Composed lower" = 1, "Composed higher" = 16),
                     name = NULL) +
  scale_x_continuous(name = "Composed arm minus jointly trained arm",
                     expand = expansion(mult = 0.09)) +
  scale_y_discrete(name = NULL, expand = expansion(add = c(1.25, 0.55))) +
  guides(colour = guide_legend(nrow = 1)) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.text = element_text(size = 7),
        legend.key.size = unit(0.3, "cm"), legend.margin = margin(t = -2),
        axis.text.y = element_text(size = 7.5),
        strip.text = element_text(size = 8.5))

save_fig(fig4, "fig4_paired", FIGURE_TEXT_WIDTH_IN, 2.9)
