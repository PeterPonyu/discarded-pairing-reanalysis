# Figure entry point for 004. Emits into figs/out/.
# Refuses to draw anything that is not bound in evidence/evidence_manifest.json.
#
# Side effect by design: this script also writes tex/generated_numbers.tex and
# the generated result tables. Every quantity the manuscript prints comes from
# here, so prose cannot drift away from the bytes that were hashed.
#
# The work is split so that each file has one reason to change: figs/lib holds
# reading, joining, statistics and formatting; figs/panels holds one figure
# each; this file holds the order they run in and the checks that must pass
# before any of them run.
#
# Run from the paper directory:  Rscript figs/make_figs.R

suppressPackageStartupMessages({
  library(ggplot2)
  library(jsonlite)
})

for (unit in c("rtx_theme.R", "lib/evidence.R", "lib/pairs.R", "lib/stats.R", "lib/emit.R")) {
  source(file.path("figs", unit))
}

dir.create(file.path("figs", "out"), showWarnings = FALSE, recursive = TRUE)

manifest <- load_manifest()
read_bound <- evidence_reader(manifest, find_repo_root())

kill <- read_bound("E-KILL")
simple <- read_bound("E-SIMPLE")
panel <- read_bound("E-PANEL")
baseline <- read_bound("E-BASELINE")
composed <- read_bound("E-COMPOSED")
identity_only <- read_bound("E-IDENTITY")
train_joint <- read_bound("E-TRAIN-JOINT")
train_cross <- read_bound("E-TRAIN-CROSS")
train_self <- read_bound("E-TRAIN-SELF")
proxy <- read_bound("E-PROXY")
proxy_run <- read_bound("E-PROXY-RUN")
closeout <- read_bound("E-CLOSEOUT")
blocked <- read_bound("E-BLOCKED")
authorisation <- read_bound("E-AUTHORISATION")

## ---------------------------------------------------------------------------
## Checks that must hold before anything is drawn. Each one is a sentence the
## manuscript makes, enforced here so it cannot survive the evidence changing.
## ---------------------------------------------------------------------------

pairs <- join_arms(baseline, composed, identity_only)
N_PAIRS <- nrow(pairs)

# The recorded endpoint is a population dispersion over the per-prompt identity
# fidelities. Recomputing it is what licenses the paper to treat the two as the
# same quantity.
sd_base <- assert_recorded_dispersion(pairs$base_identity, baseline$attribute_drift_std, "baseline arm")
sd_comp <- assert_recorded_dispersion(pairs$comp_identity, composed$attribute_drift_std, "composed arm")
sd_idon <- assert_recorded_dispersion(pairs$idon_identity, identity_only$attribute_drift_std,
                                      "cross-attention-only arm")

if (!isTRUE(all.equal(kill$baseline_attribute_drift_std, sd_base)) ||
    !isTRUE(all.equal(kill$full_attribute_drift_std, sd_comp))) {
  stop("the registered comparison does not carry the same two dispersions as the arms it cites")
}
if (!identical(kill$n_backgrounds, N_PAIRS)) {
  stop("the registered comparison records a different number of backgrounds than the arms hold")
}

# The two adapters partition the parameters the joint arm trains. If that ever
# stopped being exact the comparison would no longer be matched on capacity and
# the paper's framing would be wrong.
split_sum <- train_cross$trainable_params + train_self$trainable_params
if (!identical(as.integer(split_sum), as.integer(train_joint$trainable_params))) {
  stop("the two adapters no longer partition the jointly trained parameter set")
}

shared_fields <- c("pretrained_model", "max_train_steps", "learning_rate",
                   "lora_rank", "seed", "resolution", "instance_prompt")
for (field in shared_fields) {
  values <- unique(c(train_joint[[field]], train_cross[[field]], train_self[[field]]))
  if (length(values) != 1L) stop("the three arms disagree on ", field, "; they are not matched")
}

if (!identical(simple$metrics$baseline_attribute_drift_std, kill$baseline_attribute_drift_std)) {
  stop("the ladder entry and the registered comparison disagree about the baseline dispersion")
}

## ---------------------------------------------------------------------------
## The tests. Two endpoints, four pairs, and the same four pairs each time.
## ---------------------------------------------------------------------------

pairs$d_identity <- pairs$comp_identity - pairs$base_identity
pairs$d_prompt <- pairs$comp_prompt - pairs$base_prompt
pairs$d_identity_idon <- pairs$idon_identity - pairs$base_identity

identity_sign <- sign_test(pairs$d_identity)
prompt_sign <- sign_test(pairs$d_prompt)
idon_sign <- sign_test(pairs$d_identity_idon)

identity_wilcox <- wilcoxon_paired(pairs$comp_identity, pairs$base_identity)
prompt_wilcox <- wilcoxon_paired(pairs$comp_prompt, pairs$base_prompt)

identity_t <- paired_t(pairs$comp_identity, pairs$base_identity)
prompt_t <- paired_t(pairs$comp_prompt, pairs$base_prompt)

# The comparison as recorded: dispersion against dispersion, ignoring which
# prompt produced which value.
disp_comp <- dispersion_ratio_test(pairs$comp_identity, pairs$base_identity)
disp_idon <- dispersion_ratio_test(pairs$idon_identity, pairs$base_identity)

FLOOR_AT_N <- attainable_p(N_PAIRS)
MIN_N_ANY <- smallest_n_reaching(discordant = 0)
MIN_N_ONE <- smallest_n_reaching(discordant = 1)
MIN_N_TWO <- smallest_n_reaching(discordant = 2)

## ---------------------------------------------------------------------------
## The pre-registered design, derived from the arithmetic above rather than
## chosen. Prompts are fixed by the recorded grid; concepts by the source
## design; the seed count is the smallest that leaves each concept able to
## survive a pair falling the wrong way.
## ---------------------------------------------------------------------------

DESIGN_CONCEPTS <- 2L
DESIGN_SEEDS <- as.integer(ceiling(MIN_N_ONE / N_PAIRS))
DESIGN_PER_CONCEPT <- as.integer(N_PAIRS * DESIGN_SEEDS)
DESIGN_TOTAL <- as.integer(DESIGN_PER_CONCEPT * DESIGN_CONCEPTS)

DESIGN_TOLERANCE <- tolerated_discordant(DESIGN_PER_CONCEPT)
DESIGN_POOLED_TOLERANCE <- tolerated_discordant(DESIGN_TOTAL)

DESIGN_TRAIN_RUNS <- 3L * DESIGN_CONCEPTS
train_seconds_one <- train_joint$wall_clock_sec + train_cross$wall_clock_sec + train_self$wall_clock_sec
train_seconds_all <- train_seconds_one * DESIGN_CONCEPTS

if (DESIGN_PER_CONCEPT < MIN_N_ONE) stop("the derived design cannot tolerate a single discordant pair")

## ---------------------------------------------------------------------------
## Figures. Each panel reads the objects above and writes one file.
## ---------------------------------------------------------------------------

for (unit in c("fig1_capacity.R", "fig2_collapse.R", "fig3_dispersion.R",
               "fig4_paired.R", "fig5_floor.R")) {
  source(file.path("figs", "panels", unit))
}

## ---------------------------------------------------------------------------
## Numbers and tables.
## ---------------------------------------------------------------------------

arm_label <- c(full = "Jointly trained", cross = "Cross-attention adapter", self = "Self-attention adapter")

write_generated(c(
  macro("NPairs", N_PAIRS),
  macro("NArms", 3L),
  macro("PairingLabel", gsub("_", "\\\\_", kill$eval_pairing)),
  macro("NConceptsRun", kill$n_concepts),
  macro("TrainSteps", thousands(train_joint$max_train_steps)),
  macro("TrainSeed", train_joint$seed),
  macro("LoraRank", train_joint$lora_rank),
  macro("Resolution", train_joint$resolution),
  macro("LearningRate", format(train_joint$learning_rate, scientific = FALSE)),
  macro("JointParams", thousands(train_joint$trainable_params)),
  macro("CrossParams", thousands(train_cross$trainable_params)),
  macro("SelfParams", thousands(train_self$trainable_params)),
  macro("ProxySteps", proxy$metrics$max_train_steps),
  macro("ProxyWallRun", fmt(proxy_run$metrics$train_manifest$wall_clock_sec, 1)),
  macro("ProxyWallCloseout", fmt(closeout$checks$manifest_proxy_e2e$e2e_evidence$wall_clock_sec, 1)),
  macro("SDBase", fmt(sd_base, 4)),
  macro("SDComposed", fmt(sd_comp, 4)),
  macro("SDIdentityOnly", fmt(sd_idon, 4)),
  macro("DisplayBase", panel$rows$attribute_drift_std_baseline_display[!is.na(panel$rows$attribute_drift_std_baseline_display)][1]),
  macro("DisplayComposed", panel$rows$attribute_drift_std_full_display[!is.na(panel$rows$attribute_drift_std_full_display)][1]),
  macro("SDRatioComposed", fmt(sd_comp / sd_base)),
  macro("SDRatioIdentityOnly", fmt(sd_idon / sd_base)),
  macro("DispF", fmt(disp_comp$f)),
  macro("DispP", fmt(disp_comp$p)),
  macro("DispLower", fmt(disp_comp$sd_lower)),
  macro("DispUpper", fmt(disp_comp$sd_upper)),
  macro("DispIdonLower", fmt(disp_idon$sd_lower)),
  macro("DispIdonUpper", fmt(disp_idon$sd_upper)),
  macro("DispIdonP", fmt(disp_idon$p)),
  macro("IdentityDown", identity_sign$negative),
  macro("IdentitySignP", fmt(identity_sign$p, 3)),
  macro("IdentityWilcoxP", fmt(identity_wilcox, 3)),
  macro("IdentityDiff", fmt(identity_t$estimate, 4)),
  macro("IdentityLower", fmt(identity_t$lower, 4)),
  macro("IdentityUpper", fmt(identity_t$upper, 4)),
  macro("IdentityTP", fmt(identity_t$p, 3)),
  macro("PromptDown", prompt_sign$negative),
  macro("PromptSignP", fmt(prompt_sign$p, 3)),
  macro("PromptWilcoxP", fmt(prompt_wilcox, 3)),
  macro("PromptDiff", fmt(prompt_t$estimate, 4)),
  macro("PromptLower", fmt(prompt_t$lower, 4)),
  macro("PromptUpper", fmt(prompt_t$upper, 4)),
  macro("PromptTP", fmt(prompt_t$p, 3)),
  macro("IdonDown", idon_sign$negative),
  macro("IdonSignP", fmt(idon_sign$p, 3)),
  macro("Alpha", fmt(ALPHA)),
  macro("FloorAtFour", fmt(FLOOR_AT_N, 3)),
  macro("MinNAny", MIN_N_ANY),
  macro("MinNOne", MIN_N_ONE),
  macro("MinNTwo", MIN_N_TWO),
  macro("DesignConcepts", DESIGN_CONCEPTS),
  macro("DesignSeeds", DESIGN_SEEDS),
  macro("DesignPerConcept", DESIGN_PER_CONCEPT),
  macro("DesignTotal", DESIGN_TOTAL),
  macro("DesignTolerance", DESIGN_TOLERANCE),
  macro("DesignPooledTolerance", DESIGN_POOLED_TOLERANCE),
  macro("DesignGenerations", 2L * DESIGN_TOTAL),
  macro("DesignTrainRuns", DESIGN_TRAIN_RUNS),
  macro("TrainSecondsOne", fmt(train_seconds_one, 1)),
  macro("TrainSecondsAll", fmt(train_seconds_all, 1)),
  macro("OfficialState", gsub("_", "\\\\_", kill$official_blora_1000step)),
  macro("BlockedTier", blocked$status),
  macro("AuthorisationState", gsub("_", "\\\\_", authorisation$status)),
  macro("KillFires", if (isTRUE(kill$kill_fires_on_registered_comparison)) "fires" else "does not fire")
), "generated_numbers.tex")

arms <- data.frame(
  label = c(arm_label[[train_joint$target]], arm_label[[train_cross$target]], arm_label[[train_self$target]]),
  params = c(train_joint$trainable_params, train_cross$trainable_params, train_self$trainable_params),
  seconds = c(train_joint$wall_clock_sec, train_cross$wall_clock_sec, train_self$wall_clock_sec),
  loss = c(train_joint$final_loss, train_cross$final_loss, train_self$final_loss),
  stringsAsFactors = FALSE
)

write_generated(c(
  "\\begin{tabular}{lrrr}",
  "\\toprule",
  "Adapter & Trainable parameters & Wall clock (s) & Final loss \\\\",
  "\\midrule",
  paste0(arms$label, " & ", thousands(arms$params), " & ", fmt(arms$seconds, 1), " & ",
         fmt(arms$loss, 4), " \\\\"),
  "\\midrule",
  paste0("Two adapters combined & ", thousands(split_sum), " & ",
         fmt(sum(arms$seconds[2:3]), 1), " & --- \\\\"),
  "\\bottomrule",
  "\\end{tabular}"
), "generated_table_arms.tex")

write_generated(c(
  "\\begin{tabular}{lrrrrrr}",
  "\\toprule",
  "& \\multicolumn{3}{c}{Identity fidelity} & \\multicolumn{3}{c}{Prompt fidelity} \\\\",
  "\\cmidrule(lr){2-4}\\cmidrule(lr){5-7}",
  "Background prompt & Joint & Composed & Difference & Joint & Composed & Difference \\\\",
  "\\midrule",
  paste0(
    short_prompt(pairs$prompt), " & ",
    fmt(pairs$base_identity, 4), " & ", fmt(pairs$comp_identity, 4), " & ",
    sprintf("%+.4f", pairs$d_identity), " & ",
    fmt(pairs$base_prompt, 4), " & ", fmt(pairs$comp_prompt, 4), " & ",
    sprintf("%+.4f", pairs$d_prompt), " \\\\"
  ),
  "\\midrule",
  paste0("Dispersion across prompts & ", fmt(sd_base, 4), " & ", fmt(sd_comp, 4),
         " & --- & --- & --- & --- \\\\"),
  "\\bottomrule",
  "\\end{tabular}"
), "generated_table_pairs.tex")

write_generated(c(
  "\\begin{tabular}{ll}",
  "\\toprule",
  "Element & Fixed before the run \\\\",
  "\\midrule",
  paste0("Pairing unit & one concept, one background prompt, one generation seed \\\\"),
  paste0("Arms within a pair & jointly trained adapter versus the two composed adapters \\\\"),
  paste0("Concepts & ", DESIGN_CONCEPTS, " \\\\"),
  paste0("Background prompts & ", N_PAIRS, ", the recorded grid, unchanged \\\\"),
  paste0("Generation seeds per prompt & ", DESIGN_SEEDS, " \\\\"),
  paste0("Pairs per concept & ", DESIGN_PER_CONCEPT, " \\\\"),
  paste0("Pairs in total & ", DESIGN_TOTAL, " \\\\"),
  paste0("Training budget & ", thousands(train_joint$max_train_steps),
         " steps, the budget of the arms being re-tested \\\\"),
  paste0("Primary endpoint & per-pair difference in identity fidelity \\\\"),
  paste0("Primary test & two-sided exact sign test at $\\alpha=", fmt(ALPHA), "$ \\\\"),
  paste0("Secondary test & Wilcoxon signed rank on the same pairs \\\\"),
  paste0("Discordant pairs tolerated per concept & ", DESIGN_TOLERANCE, " \\\\"),
  paste0("Discordant pairs tolerated pooled & ", DESIGN_POOLED_TOLERANCE, " \\\\"),
  paste0("Training runs required & ", DESIGN_TRAIN_RUNS, " \\\\"),
  paste0("Generations required & ", 2L * DESIGN_TOTAL, " \\\\"),
  "\\bottomrule",
  "\\end{tabular}"
), "generated_table_protocol.tex")

message(sprintf("wrote 5 figures to figs/out and 4 generated tex files to tex/"))
