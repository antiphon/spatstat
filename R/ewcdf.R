#
#     ewcdf.R
#
#     $Revision: 1.7 $  $Date: 2013/12/18 02:33:22 $
#
#  With contributions from Kevin Ummel
#

ewcdf <- function(x, weights=rep(1/length(x), length(x)))
{
  stopifnot(length(x) == length(weights))
  # remove NA's together
  nbg <- is.na(x) 
  x <- x[!nbg]
  weights <- weights[!nbg]
  n <- length(x)
  if (n < 1)
    stop("'x' must have 1 or more non-missing values")
  stopifnot(all(weights >= 0))
  # sort in increasing order of x value
  ox <- fave.order(x)
  x <- x[ox]
  w <- weights[ox]
  # find jump locations and match
  vals <- sort(unique(x))
  xmatch <- factor(match(x, vals), levels=seq_along(vals))
  # sum weight in each interval
  wmatch <- tapply(w, xmatch, sum)
  wmatch[is.na(wmatch)] <- 0
  cumwt <- cumsum(wmatch)
  # make function
  rval <- approxfun(vals, cumwt,
                    method = "constant", yleft = 0, yright = sum(wmatch),
                    f = 0, ties = "ordered")
  class(rval) <- c("ewcdf", "ecdf", "stepfun", class(rval))
  assign("w", w, envir=environment(rval))
  attr(rval, "call") <- sys.call()
  return(rval)
}

  # Hacked from stats:::print.ewcdf
print.ewcdf <- function (x, digits = getOption("digits") - 2L, ...) {
  cat("Weighted empirical CDF \nCall: ")
  print(attr(x, "call"), ...)
  env <- environment(x)
  xx <- get("x", envir=env)
  ww <- get("w", envir=env)
  n <- length(xx)
  i1 <- 1L:min(3L, n)
  i2 <- if (n >= 4L) max(4L, n - 1L):n else integer()
  numform <- function(x) paste(formatC(x, digits = digits), collapse = ", ")
  cat(" x[1:", n, "] = ", numform(xx[i1]), if (n > 3L) 
      ", ", if (n > 5L) 
      " ..., ", numform(xx[i2]), "\n", sep = "")
  cat(" weights[1:", n, "] = ", numform(ww[i1]), if (n > 3L) 
      ", ", if (n > 5L) 
      " ..., ", numform(ww[i2]), "\n", sep = "")
  invisible(x)
}

quantile.ewcdf <- function(x, probs=seq(0,1,0.25), names=TRUE, ...) {
  trap.extra.arguments(..., .Context="quantile.ewcdf")
  env <- environment(x)
  xx <- get("x", envir=env)
  Fxx <- get("y", envir=env)
  n <- length(xx)
  eps <- 100 * .Machine$double.eps
  if(any((p.ok <- !is.na(probs)) & (probs < -eps | probs > 1 + eps))) 
    stop("'probs' outside [0,1]")
  if (na.p <- any(!p.ok)) {
    o.pr <- probs
    probs <- probs[p.ok]
    probs <- pmax(0, pmin(1, probs))
  }
  np <- length(probs)
  if (n > 0 && np > 0) {
    qs <- numeric(np)
    for(k in 1:np) qs[k] <- xx[min(which(Fxx >= probs[k]))]
  } else {
    qs <- rep(NA_real_, np)
  }
  if (names && np > 0L) {
    dig <- max(2L, getOption("digits"))
    probnames <-
      if(np < 100) formatC(100 * probs, format="fg", width=1, digits=dig) else
      format(100 * probs, trim = TRUE, digits = dig)
    names(qs) <- paste0(probnames, "%")
  }
  if (na.p) {
    o.pr[p.ok] <- qs
    names(o.pr) <- rep("", length(o.pr))
    names(o.pr)[p.ok] <- names(qs)
    o.pr
  } else qs
}

