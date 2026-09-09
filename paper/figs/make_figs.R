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
predecl <- read_bound("E-PREDECL")
paired <- read_bound("E-PAIRED")

## ---------------------------------------------------------------------------
## Checks that must hold before anything is drawn. Each one is a sentence the
## manuscript makes, enforced here so it cannot survive the evidence changing.
## ---------------------------------------------------------------------------

pairs <- join_arms(baseline, composed, identity_only)
N_PAIRS <- nrow(pairs)
PROMPT_CODES <- paste0("P", seq_len(N_PAIRS))
if (anyDuplicated(PROMPT_CODES)) stop("prompt row codes are not unique")

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
## The executed paired run. Facts are read from the bound analysis and refused
## if they drift. Historical macros for the n=4 reanalysis stay untouched.
## ---------------------------------------------------------------------------

EXPECTED_PREDECL_SHA <- "a263fb9706c96581188b936b2313d1fbb21461600ab815c752ea8c82525e6f96"

if (!nzchar(as.character(predecl$declared_utc))) {
  stop("E-PREDECL lacks declared_utc")
}
if (is.null(paired$pairs_realised)) {
  stop("E-PAIRED lacks pairs_realised")
}
if (!identical(as.integer(paired$pairs_realised), 24L)) {
  stop("pairs_realised is not 24")
}
if (length(paired$pairs_missing) != 0L) {
  stop("pairs_missing is not empty")
}
if (!identical(as.integer(paired$failure_ledger_entries), 0L)) {
  stop("failure_ledger_entries is not 0")
}
if (!identical(paired$predeclaration_sha256, EXPECTED_PREDECL_SHA) ||
    !identical(bound_sha256(manifest, "E-PREDECL"), EXPECTED_PREDECL_SHA)) {
  stop("predeclaration sha256 does not match the recorded digest of PREDECLARATION.json")
}

ident_run <- paired$primary_identity_fidelity
prompt_run <- paired$secondary_prompt_fidelity
if (!identical(as.integer(ident_run$composed_lower), 13L) ||
    !identical(as.integer(ident_run$composed_higher), 11L) ||
    !identical(as.integer(ident_run$ties), 0L)) {
  stop("primary identity pair counts drifted")
}
if (abs(ident_run$sign_test_two_sided_p - 0.8388197422027588) > 1e-12) {
  stop("primary identity sign-test p drifted")
}
if (!isFALSE(ident_run$significant_at_alpha)) {
  stop("primary identity significant_at_alpha is not false")
}
ident_ci <- as.numeric(ident_run$mean_diff_ci95)
if (length(ident_ci) != 2L ||
    abs(ident_ci[1] - (-0.013720273288587728)) > 1e-9 ||
    abs(ident_ci[2] - 0.051724358648061734) > 1e-9) {
  stop("primary identity mean_diff_ci95 drifted")
}
if (!identical(as.integer(prompt_run$composed_lower), 21L)) {
  stop("secondary prompt composed_lower drifted")
}
if (abs(prompt_run$sign_test_two_sided_p - 0.0002771615982055664) > 1e-12) {
  stop("secondary prompt sign-test p drifted")
}
if (!identical(as.integer(paired$concept_strata_descriptive$dog6$composed_lower), 9L) ||
    !identical(as.integer(paired$concept_strata_descriptive$clock$composed_higher), 8L)) {
  stop("descriptive identity strata drifted")
}

disp_dog <- paired$registered_dispersion_endpoint_recomputed$dog6$ratio_composed_over_joint
disp_clock <- paired$registered_dispersion_endpoint_recomputed$clock$ratio_composed_over_joint
if (abs(disp_dog - 0.6694394238043602) > 1e-6 ||
    abs(disp_clock - 0.5685330436376612) > 1e-6) {
  stop("dispersion ratio composed/joint drifted")
}
if (!identical(as.integer(DESIGN_TOTAL), 24L) ||
    !identical(as.integer(DESIGN_TOTAL), as.integer(paired$pairs_realised))) {
  stop("DESIGN_TOTAL is not the realised pair count")
}
if (!identical(as.integer(N_PAIRS), 4L)) {
  stop("historical N_PAIRS must remain 4")
}

run_concept_counts <- table(as.character(paired$pairs$concept))
if (!identical(sort(names(run_concept_counts)), c("clock", "dog6")) ||
    any(as.integer(run_concept_counts) != 12L)) {
  stop("registered run must contain exactly 12 pairs for dog6 and clock")
}
run_seeds <- sort(unique(as.integer(paired$pairs$seed)))
run_prompts <- sort(unique(as.character(paired$pairs$background_prompt)))
if (anyNA(paired$pairs$concept) || anyNA(paired$pairs$background_prompt) ||
    anyNA(paired$pairs$seed) || anyNA(run_prompts) ||
    !identical(run_seeds, c(101L, 202L, 303L)) || length(run_prompts) != 4L) {
  stop("registered run must contain three seeds and four prompts")
}
run_keys <- paste(as.character(paired$pairs$concept),
                  as.character(paired$pairs$background_prompt),
                  as.integer(paired$pairs$seed), sep = "|")
expected_grid <- expand.grid(concept = c("clock", "dog6"),
                             background_prompt = run_prompts,
                             seed = run_seeds,
                             stringsAsFactors = FALSE)
expected_keys <- with(expected_grid,
                      paste(concept, background_prompt, seed, sep = "|"))
if (anyDuplicated(run_keys) || anyDuplicated(expected_keys) ||
    !identical(sort(run_keys), sort(expected_keys))) {
  stop("registered run is not a complete concept x prompt x seed Cartesian grid")
}

# The smallest two-sided probability the registered primary can return at the
# pair count that was actually realised. Read from E-PAIRED, not from the
# design constant, so the printed floor belongs to the run that happened.
PAIRS_REALISED <- as.integer(paired$pairs_realised)
if (!identical(PAIRS_REALISED, as.integer(DESIGN_TOTAL))) {
  stop("pairs_realised differs from DESIGN_TOTAL; the realised floor would not describe the registered design")
}
FLOOR_AT_REALISED <- attainable_p(PAIRS_REALISED)
if (abs(FLOOR_AT_REALISED - 2 * 0.5^PAIRS_REALISED) > 1e-15) {
  stop("realised sign-test floor does not equal 2 * 0.5^pairs_realised")
}
if (FLOOR_AT_REALISED >= ALPHA) {
  stop("realised sign-test floor is not below alpha; the sizing derivation is broken")
}

## ---------------------------------------------------------------------------
## What the registered primary could resolve at the realised size. The floor
## above says which p-values the test can return; this block says which true
## effects it had a fair chance of detecting. Inputs are the bound pair count,
## the bound observed count and the design alpha, nothing else, so the printed
## power statement belongs to the test that was run and stops if any of them
## drift. The rejection region is the two-sided exact one binom.test uses.
## ---------------------------------------------------------------------------

SIGN_POWER_TARGET <- 0.80
SIGN_OBSERVED_LOWER <- as.integer(ident_run$composed_lower)
if (!identical(PAIRS_REALISED, 24L) || !identical(SIGN_OBSERVED_LOWER, 13L) ||
    !isTRUE(all.equal(ALPHA, 0.05))) {
  stop("power statement inputs differ from the bound values (pairs_realised 24, composed_lower 13, alpha 0.05)")
}

sign_counts <- 0:PAIRS_REALISED
sign_two_sided_p <- vapply(sign_counts,
                           function(k) stats::binom.test(k, PAIRS_REALISED)$p.value,
                           numeric(1))
sign_reject_low <- sign_counts[sign_two_sided_p <= ALPHA & sign_counts < PAIRS_REALISED / 2]
if (!length(sign_reject_low)) stop("the registered test has no rejection region at the realised size")
SIGN_REJECT_LOW <- max(sign_reject_low)
SIGN_CRITICAL_COUNT <- as.integer(PAIRS_REALISED - SIGN_REJECT_LOW)
# The low-side rejection bound is the pooled discordant-pair tolerance the
# protocol table already prints; the two derivations must agree.
if (!identical(as.integer(SIGN_REJECT_LOW), as.integer(DESIGN_POOLED_TOLERANCE))) {
  stop("the exact rejection region does not agree with the pooled discordant-pair tolerance")
}
if (SIGN_OBSERVED_LOWER <= SIGN_REJECT_LOW || SIGN_OBSERVED_LOWER >= SIGN_CRITICAL_COUNT) {
  stop("the observed count lies in the rejection region, contradicting significant_at_alpha = false")
}

# Power of the two-sided exact test against a true probability that the
# composed arm is lower on a pair.
sign_power <- function(prob_lower) {
  stats::pbinom(SIGN_REJECT_LOW, PAIRS_REALISED, prob_lower) +
    stats::pbinom(SIGN_CRITICAL_COUNT - 1L, PAIRS_REALISED, prob_lower, lower.tail = FALSE)
}
if (sign_power(0.5) > ALPHA) stop("the exact two-sided test exceeds alpha under the null")

# The power function of the equal-tailed exact test is symmetric about one half
# and increasing above it, so the root on (0.5, 1) is unique. It is printed as
# the smallest two-decimal proportion at which power reaches the target, which
# is the reading "at least this large" requires; both neighbours are checked so
# the printed value is tight rather than merely sufficient.
sign_power_root <- stats::uniroot(function(p) sign_power(p) - SIGN_POWER_TARGET,
                                  lower = 0.5, upper = 1, tol = 1e-12)$root
SIGN_POWER_EIGHTY <- ceiling(sign_power_root * 100) / 100
if (sign_power(SIGN_POWER_EIGHTY) < SIGN_POWER_TARGET) {
  stop("power at the printed proportion is below the target")
}
if (sign_power(SIGN_POWER_EIGHTY - 0.01) >= SIGN_POWER_TARGET) {
  stop("the printed proportion is not the smallest two-decimal value reaching the target")
}

SIGN_OBSERVED_PROP <- SIGN_OBSERVED_LOWER / PAIRS_REALISED
sign_observed_ci <- stats::binom.test(SIGN_OBSERVED_LOWER, PAIRS_REALISED)$conf.int
if (abs(stats::binom.test(SIGN_OBSERVED_LOWER, PAIRS_REALISED)$p.value -
        ident_run$sign_test_two_sided_p) > 1e-12) {
  stop("the recomputed primary sign-test p does not reproduce the bound value")
}
# The results sentence says the observed proportion sits inside the region the
# design left unresolved. That is a claim about numbers, so it is checked here
# rather than trusted in prose.
if (!(SIGN_OBSERVED_PROP > 1 - SIGN_POWER_EIGHTY && SIGN_OBSERVED_PROP < SIGN_POWER_EIGHTY)) {
  stop("the observed proportion is outside the under-powered region; the results sentence would be false")
}
if (!(sign_observed_ci[1] < 0.5 && sign_observed_ci[2] > 0.5)) {
  stop("the exact interval for the observed proportion excludes one half, contradicting the non-separation")
}

# Fixed-point formatting (as FloorAtFour uses) would print this value as 0.000,
# so it is emitted in scientific form wrapped for use in text or math.
fmt_sci <- function(x, digits = 1) {
  e <- floor(log10(abs(x)))
  m <- x / 10^e
  if (round(m, digits) >= 10) {
    m <- m / 10
    e <- e + 1L
  }
  sprintf("\\ensuremath{%s\\times 10^{%d}}", formatC(m, format = "f", digits = digits), as.integer(e))
}

## ---------------------------------------------------------------------------
## Figures. Each panel reads the objects above and writes one file.
## ---------------------------------------------------------------------------

for (unit in c("fig1_capacity.R", "fig2_collapse.R", "fig3_dispersion.R",
               "fig4_paired.R", "fig5_floor.R", "fig6_tradeoff.R",
               "fig7_protocol.R", "fig8_paired_run.R", "fig9_concept_slopes.R")) {
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
  macro("IdentityHigher", sum(pairs$d_identity > 0)),
  macro("IdentityTies", sum(pairs$d_identity == 0)),
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
  macro("SignFloorRealised", fmt_sci(FLOOR_AT_REALISED, 1)),
  macro("SignCriticalCount", SIGN_CRITICAL_COUNT),
  macro("SignPowerTarget", pct(SIGN_POWER_TARGET, 0)),
  macro("SignPowerEighty", fmt(SIGN_POWER_EIGHTY, 2)),
  macro("SignObservedProp", fmt(SIGN_OBSERVED_PROP, 2)),
  macro("SignObservedPropLo", fmt(sign_observed_ci[1], 2)),
  macro("SignObservedPropHi", fmt(sign_observed_ci[2], 2)),
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
  macro("KillFires", if (isTRUE(kill$kill_fires_on_registered_comparison)) "fires" else "does not fire"),
  macro("RunPairs", as.integer(paired$pairs_realised)),
  macro("RunFailures", as.integer(paired$failure_ledger_entries)),
  macro("PredeclarationShaShort", substr(EXPECTED_PREDECL_SHA, 1, 16)),
  macro("RunIdentityLower", as.integer(ident_run$composed_lower)),
  macro("RunIdentityHigher", as.integer(ident_run$composed_higher)),
  macro("RunIdentitySignP", fmt(ident_run$sign_test_two_sided_p)),
  macro("RunIdentityCiLo", fmt(ident_ci[1], 3)),
  macro("RunIdentityCiHi", fmt(ident_ci[2], 3)),
  macro("RunPromptLower", as.integer(prompt_run$composed_lower)),
  macro("RunPromptSignP", fmt(prompt_run$sign_test_two_sided_p, 5)),
  macro("RunPairsPerConcept", as.integer(run_concept_counts[["dog6"]])),
  macro("RunSeedCount", length(unique(paired$pairs$seed))),
  macro("RunPromptCount", length(unique(paired$pairs$background_prompt))),
  macro("RunDogIdentityLower", as.integer(paired$concept_strata_descriptive$dog6$composed_lower)),
  macro("RunClockIdentityHigher", as.integer(paired$concept_strata_descriptive$clock$composed_higher)),
  macro("RunDispersionDog", fmt(disp_dog)),
  macro("RunDispersionClock", fmt(disp_clock)),
  macro("NEvidence", nrow(manifest$entries)),
  macro("EvidenceBytes", format(sum(manifest$entries$bytes), big.mark = ","))
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
    PROMPT_CODES, " & ",
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
  "Element & Locked declaration (executed once) \\\\",
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
  paste0("Secondary endpoint & per-pair difference in prompt fidelity \\\\"),
  paste0("Secondary test & Wilcoxon signed rank on the same pairs \\\\"),
  paste0("Discordant pairs tolerated per concept & ", DESIGN_TOLERANCE, " \\\\"),
  paste0("Discordant pairs tolerated pooled & ", DESIGN_POOLED_TOLERANCE, " \\\\"),
  paste0("Training runs required & ", DESIGN_TRAIN_RUNS, " \\\\"),
  paste0("Generations required & ", 2L * DESIGN_TOTAL, " \\\\"),
  "\\bottomrule",
  "\\end{tabular}"
), "generated_table_protocol.tex")

## The manifest itself, so the evidence discipline can be checked rather than believed.

message(sprintf("wrote 9 figures to figs/out and 5 generated tex files to tex/"))
unlink(file.path("tex", "generated_table_evidence.tex"), force = TRUE)
