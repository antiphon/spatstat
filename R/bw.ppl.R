#
#   bw.ppl.R
#
#   Likelihood cross-validation for kernel smoother of point pattern
#
#   $Revision: 1.3 $ $Date: 2014/01/09 03:51:59 $
#

bw.ppl <- function(X, ..., srange=NULL, ns=16) {
  stopifnot(is.ppp(X))
  if(!is.null(srange)) check.range(srange) else {
    nnd <- nndist(X)
    srange <- c(min(nnd[nnd > 0]), diameter(as.owin(X))/2)
  }
  sigma <- exp(seq(log(srange[1]), log(srange[2]), length=ns))
  cv <- numeric(ns)
  for(i in 1:ns) {
    si <- sigma[i]
    lamx <- density(X, sigma=si, at="points", leaveoneout=TRUE)
    lam <- density(X, sigma=si)
    cv[i] <- sum(log(lamx)) - integral.im(lam)
  }
  result <- bw.optim(cv, sigma, iopt=which.max(cv), 
                     creator="bw.ppl",
                     criterion="Likelihood Cross-Validation")
  return(result)
}
