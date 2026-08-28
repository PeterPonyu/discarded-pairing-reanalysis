# The tests this paper reports, and the design arithmetic behind the protocol.
#
# Every test here is applied to four pairs, which is the point: two of them
# cannot reach the conventional threshold at that size no matter what the data
# do, and the third only does so by assuming a shape four points cannot show.

ALPHA <- 0.05

# Sign test on the paired differences, two-sided and exact. Ties would be
# dropped by convention; there are none here and a tie is refused rather than
# silently discarded, because with four pairs one tie changes the answer.
sign_test <- function(differences) {
  if (any(differences == 0)) stop("a paired difference is exactly zero; the sign test is undefined here")
  n <- length(differences)
  positive <- sum(differences > 0)
  list(n = n, positive = positive, negative = n - positive,
       p = stats::binom.test(positive, n)$p.value)
}

wilcoxon_paired <- function(a, b) {
  suppressWarnings(stats::wilcox.test(a, b, paired = TRUE))$p.value
}

paired_t <- function(a, b) {
  fit <- stats::t.test(a, b, paired = TRUE)
  list(estimate = unname(fit$estimate), p = fit$p.value,
       lower = fit$conf.int[1], upper = fit$conf.int[2])
}

# The comparison as it was recorded: two dispersions, each estimated from the
# same four generations, compared without reference to which prompt produced
# which value. Reported on the unbiased variances, since that is what an F
# interval is defined on.
dispersion_ratio_test <- function(a, b) {
  fit <- stats::var.test(a, b)
  list(f = unname(fit$statistic), p = fit$p.value,
       sd_lower = sqrt(fit$conf.int[1]), sd_upper = sqrt(fit$conf.int[2]))
}

# The smallest two-sided p a sign test can return at n pairs when at most
# `discordant` of them fall the wrong way. This depends on n alone, so it can be
# read before the data exist: below six pairs the test never reaches 0.05, and
# no effect size changes that.
attainable_p <- function(n, discordant = 0) {
  args <- data.frame(n = n, discordant = discordant)
  pmin(1, 2 * mapply(function(size, k) sum(choose(size, 0:k)) / 2^size,
                     args$n, args$discordant))
}

smallest_n_reaching <- function(alpha = ALPHA, discordant = 0, limit = 200) {
  n <- seq_len(limit)
  hit <- which(attainable_p(n, discordant) <= alpha)
  if (!length(hit)) stop("no pair count within the search limit reaches alpha")
  n[hit[1]]
}

# How many pairs may fall the wrong way at a given size and still leave the
# sign test able to reach alpha.
tolerated_discordant <- function(n, alpha = ALPHA) {
  failing <- which(attainable_p(n, discordant = 0:n) > alpha)
  if (!length(failing)) return(n)
  as.integer(failing[1] - 2L)
}
