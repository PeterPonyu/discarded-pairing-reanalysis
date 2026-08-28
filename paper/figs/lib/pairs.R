# Rebuilding the pairs the recorded endpoint threw away.
#
# The three arms were generated over the same four background prompts, so the
# per-prompt rows join on the prompt text. Nothing here estimates anything; it
# only puts back the correspondence that a per-arm dispersion number discards.

# The order the drift reports were written in. Joining on the text rather than
# on position, because a silent reordering would otherwise pair the wrong rows.
join_arms <- function(baseline, composed, identity_only) {
  prompts <- baseline$per_prompt$background_prompt
  pick <- function(arm, column) {
    idx <- match(prompts, arm$per_prompt$background_prompt)
    if (anyNA(idx)) stop("an arm does not cover the same background prompts as the baseline")
    arm$per_prompt[[column]][idx]
  }
  data.frame(
    prompt = prompts,
    base_identity = pick(baseline, "identity_fidelity"),
    comp_identity = pick(composed, "identity_fidelity"),
    idon_identity = pick(identity_only, "identity_fidelity"),
    base_prompt = pick(baseline, "prompt_fidelity"),
    comp_prompt = pick(composed, "prompt_fidelity"),
    idon_prompt = pick(identity_only, "prompt_fidelity"),
    stringsAsFactors = FALSE
  )
}

# The dispersion the runs reported divides by n, not by n-1. The distinction
# matters here because the whole comparison is between two such numbers, so the
# check is run rather than assumed.
population_sd <- function(x) sqrt(sum((x - mean(x))^2) / length(x))

assert_recorded_dispersion <- function(values, recorded, label, tol = 1e-9) {
  recomputed <- population_sd(values)
  if (abs(recomputed - recorded) > tol) {
    stop(sprintf("%s: recorded dispersion %.12g does not match the per-prompt values (%.12g)",
                 label, recorded, recomputed))
  }
  recomputed
}

# Short axis labels. The manuscript prints the recorded prompt text, so the two
# never disagree about which generation is being named.
short_prompt <- function(x) {
  x <- sub("^on a ", "", x)
  x <- sub("^in a ", "", x)
  x <- sub(" at sunset$", ", sunset", x)
  x <- sub(" at night$", ", night", x)
  x
}
