#
#    relrisk.R
#
#   Estimation of relative risk
#
#  $Revision: 1.26 $  $Date: 2014/11/15 01:02:37 $
#

relrisk <- local({

  relrisk <- function(X, sigma=NULL, ..., varcov=NULL, at="pixels",
                      relative=FALSE,
                      casecontrol=TRUE, control=1, case) {
    stopifnot(is.ppp(X))
    stopifnot(is.multitype(X))
    control.given <- !missing(control)
    case.given <- !missing(case)
    if(!relative && (control.given || case.given)) {
      aa <- c("control", "case")[c(control.given, case.given)]
      nn <- length(aa)
      warning(paste(ngettext(nn, "Argument", "Arguments"),
                    paste(sQuote(aa), collapse=" and "),
                    ngettext(nn, "was", "were"),
                    "ignored, because relative=FALSE"))
    }
    Y <- split(X)
    ntypes <- length(Y)
    if(ntypes == 1)
      stop("Data contains only one type of points")
    marx <- marks(X)
    imarks <- as.integer(marx)
    lev <- levels(marx)
    ## trap arguments
    dotargs <- list(...)
    isbwarg <- names(dotargs) %in% c("method", "nh", "hmin", "hmax", "warn")
    bwargs <- dotargs[isbwarg]
    dargs  <- dotargs[!isbwarg]
    ## bandwidth
    if(is.null(sigma) && is.null(varcov)) 
      sigma <- do.call(bw.relrisk, append(list(X), bwargs))
    ## compute probabilities
    if(ntypes == 2 && casecontrol) {
      if(control.given || !case.given) {
        stopifnot(length(control) == 1)
        if(is.numeric(control)) {
          icontrol <- control <- as.integer(control)
          stopifnot(control %in% 1:2)
        } else if(is.character(control)) {
          icontrol <- match(control, levels(marks(X)))
          if(is.na(icontrol)) stop(paste("No points have mark =", control))
        } else
          stop(paste("Unrecognised format for argument", sQuote("control")))
        if(!case.given)
          icase <- 3 - icontrol
      }
      if(case.given) {
        stopifnot(length(case) == 1)
        if(is.numeric(case)) {
          icase <- case <- as.integer(case)
          stopifnot(case %in% 1:2)
        } else if(is.character(case)) {
          icase <- match(case, levels(marks(X)))
          if(is.na(icase)) stop(paste("No points have mark =", case))
        } else stop(paste("Unrecognised format for argument", sQuote("case")))
        if(!control.given) 
          icontrol <- 3 - icase
      }
      ## compute densities
      Deach <- do.call(density.splitppp,
                       append(list(Y, sigma=sigma, varcov=varcov, at=at),
                              dargs))
      Dall <- Reduce("+", Deach)
      ## compute probability of case
      switch(at,
             pixels= {
               Dcase <- Deach[[icase]]
               result <- eval.im(Dcase/Dall)
               ## correct small numerical errors
               result <- clamp01(result)
               ## trap NaN values
               nbg <- badvalues(result)
               if(any(nbg)) {
                 ## apply l'Hopital's rule:
                 ##     p(case) = 1{nearest neighbour is case}
                 distcase <- distmap(Y[[icase]], xy=result)
                 distcontrol <- distmap(Y[[icontrol]], xy=result)
                 closecase <- eval.im(as.integer(distcase < distcontrol))
                 result[nbg] <- closecase[nbg]
               }
               if(relative)
                 result <- eval.im(ifelse(result < 1, result/(1-result), NA))
             },
             points={
               result <- numeric(npoints(X))
               isCase <- (imarks == icase)
               result[isCase] <- Deach[[icase]]/Dall[isCase]
               result[!isCase] <- 1 - Deach[[icontrol]]/Dall[!isCase]
               ## correct small numerical errors
               result <- clamp01(result)
               ## trap NaN values
               if(any(nbg <- badvalues(result))) {
                 ## apply l'Hopital's rule
                 nntype <- imarks[nnwhich(X)]
                 result[nbg] <- as.integer(nntype[nbg] == icase)
               }
               if(relative)
                 result <- result/(1-result)
             })
    } else {
      ## several types
      if(relative) {
        ## need 'control' type
        stopifnot(length(control) == 1)
        if(is.numeric(control)) {
          icontrol <- control <- as.integer(control)
          stopifnot(control %in% 1:ntypes)
        } else if(is.character(control)) {
          icontrol <- match(control, levels(marks(X)))
          if(is.na(icontrol)) stop(paste("No points have mark =", control))
        } else
          stop(paste("Unrecognised format for argument", sQuote("control")))
      }
      switch(at,
             pixels={
               Deach <- do.call(density.splitppp,
                                append(list(Y, sigma=sigma, varcov=varcov,
                                            at=at),
                                       dargs))
               Dall <- Reduce("+", Deach)
               result <- as.listof(lapply(Deach,
                                          function(d, dall) { eval.im(d/dall) },
                                          dall = Dall))
               ## correct small numerical errors
               result <- as.listof(lapply(result, clamp01))
               ## trap NaN values
               nbg <- lapply(result, badvalues)
               nbg <- Reduce("|", nbg)
               if(any(nbg)) {
                 ## apply l'Hopital's rule
                 distX <- distmap(X, xy=Dall)
                 whichnn <- attr(distX, "index")
                 typenn <- eval.im(imarks[whichnn])
                 typennsub <- as.matrix(typenn)[nbg]
                 for(k in seq_along(result)) 
                   result[[k]][nbg] <- (typennsub == k)
               }
               if(relative) {
                 result <-
                   as.listof(lapply(result,
                                    function(z, d) {
                                      eval.im(ifelse(d > 0, z/d, NA))
                                    },
                                    d = result[[icontrol]]))
               }
             },
             points = {
               npts <- npoints(X)
               ## dummy variable matrix
               dumm <- matrix(0, npts, ntypes)
               dumm[cbind(seq_len(npts), imarks)] <- 1
               colnames(dumm) <- lev
               ## compute probability of each type
               Z <- X %mark% dumm
               result <- do.call(Smooth,
                                 append(list(Z, sigma=sigma, varcov=varcov,
                                             at="points"),
                                        dargs))
               ## correct small numerical errors
               result <- clamp01(as.matrix(result))
               ## trap NaN values
               bad <- badvalues(result)
               badrow <- apply(bad, 1, any)
               if(any(badrow)) {
                 ## apply l'Hopital's rule
                 typenn <- imarks[nnwhich(X)]
                 result[badrow, ] <- (typenn == col(result))[badrow, ]
               }
               if(relative) 
                 result <- result/result[,icontrol]
            })
    }
    attr(result, "sigma") <- sigma
    attr(result, "varcov") <- varcov
    return(result)
  }

  clamp01 <- function(x) {
    if(is.im(x)) return(eval.im(pmin(pmax(x, 0), 1)))
    return(pmin(pmax(x, 0), 1))
  }

  badvalues <- function(x) {
    if(is.im(x)) x <- as.matrix(x)
    return(!(is.finite(x) | is.na(x)))
  }
  
  relrisk
})


bw.stoyan <- function(X, co=0.15) {
  ## Stoyan's rule of thumb
  stopifnot(is.ppp(X))
  n <- npoints(X)
  W <- Window(X)
  a <- area(W)
  stoyan <- co/sqrt(5 * n/a)
  return(stoyan)
}


bw.relrisk <- function(X, method="likelihood",
                       nh=spatstat.options("n.bandwidth"),
                       hmin=NULL, hmax=NULL, warn=TRUE) {
  stopifnot(is.ppp(X))
  stopifnot(is.multitype(X))
  ## rearrange in ascending order of x-coordinate (for C code)
  X <- X[fave.order(X$x)]
  ##
  Y <- split(X)
  ntypes <- length(Y)
  if(ntypes == 1)
    stop("Data contains only one type of points")
  marx <- marks(X)
  method <- pickoption("method", method,
                       c(likelihood="likelihood",
                         leastsquares="leastsquares",
                         ls="leastsquares",
                         LS="leastsquares",
                         weightedleastsquares="weightedleastsquares",
                         wls="weightedleastsquares",
                         WLS="weightedleastsquares"))
  ## 
  if(method != "likelihood") {
    ## dummy variables for each type
    imarks <- as.integer(marx)
    if(ntypes == 2) {
      ## 1 = control, 2 = case
      indic <- (imarks == 2)
      y01   <- as.integer(indic)
    } else {
      indic <- matrix(FALSE, n, ntypes)
      indic[cbind(seq_len(n), imarks)] <- TRUE
      y01  <- indic * 1
    }
    X01 <- X %mark% y01
  }
  ## cross-validated bandwidth selection
  ## determine a range of bandwidth values
  n <- npoints(X)
  if(is.null(hmin) || is.null(hmax)) {
    W <- Window(X)
    a <- area(W)
    d <- diameter(as.rectangle(W))
    ## Stoyan's rule of thumb applied to the least and most common types
    mcount <- table(marx)
    nmin <- max(1, min(mcount))
    nmax <- max(1, max(mcount))
    stoyan.low <- 0.15/sqrt(nmax/a)
    stoyan.high <- 0.15/sqrt(nmin/a)
    if(is.null(hmin)) 
      hmin <- max(minnndist(unique(X)), stoyan.low/5)
    if(is.null(hmax)) {
      hmax <- min(d/4, stoyan.high * 20)
      hmax <- max(hmax, hmin * 2)
    }
  } else stopifnot(hmin < hmax)
  ##
  h <- exp(seq(from=log(hmin), to=log(hmax), length.out=nh))
  cv <- numeric(nh)
  ## 
  ## compute cross-validation criterion
  switch(method,
         likelihood={
           methodname <- "Likelihood"
           ## for efficiency, only compute the estimate of p_j(x_i)
           ## when j = m_i = mark of x_i.
           Dthis <- numeric(n)
           for(i in seq_len(nh)) {
             Dall <- density.ppp(X, sigma=h[i], at="points", edge=FALSE,
                                 sorted=TRUE)
             Deach <- density.splitppp(Y, sigma=h[i], at="points", edge=FALSE,
                                       sorted=TRUE)
             split(Dthis, marx) <- Deach
             pthis <- Dthis/Dall
             cv[i] <- -mean(log(pthis))
           }
         },
         leastsquares={
           methodname <- "Least Squares"
           for(i in seq_len(nh)) {
             phat <- Smooth(X01, sigma=h[i], at="points", leaveoneout=TRUE,
                            sorted=TRUE)
             cv[i] <- mean((y01 - phat)^2)
           }
         },
         weightedleastsquares={
           methodname <- "Weighted Least Squares"
           ## need initial value of h from least squares
           h0 <- bw.relrisk(X, "leastsquares", nh=ceiling(nh/4))
           phat0 <- Smooth(X01, sigma=h0, at="points", leaveoneout=TRUE,
                           sorted=TRUE)
           var0 <- phat0 * (1-phat0)
           var0 <- pmax.int(var0, 1e-6)
           for(i in seq_len(nh)) {
             phat <- Smooth(X01, sigma=h[i], at="points", leaveoneout=TRUE,
                            sorted=TRUE)
             cv[i] <- mean((y01 - phat)^2/var0)
           }
         })
  ## optimize
  iopt <- which.min(cv)
  ##
  if(warn && (iopt == nh || iopt == 1)) 
    warning(paste("Cross-validation criterion was minimised at",
                  if(iopt == 1) "left-hand" else "right-hand",
                  "end of interval",
                  "[", signif(hmin, 3), ",", signif(hmax, 3), "];",
                  "use arguments hmin, hmax to specify a wider interval"))
  ##    
  result <- bw.optim(cv, h, iopt,
                     hname="sigma", 
                     creator="bw.relrisk",
                     criterion=paste(methodname, "Cross-Validation"))
  return(result)
}

which.max.im <- function(x) {
  .Deprecated("im.apply", "spatstat",
              "which.max.im(x) is deprecated: use im.apply(x, which.max)")
  ans <- im.apply(x, which.max)
  return(ans)
}

