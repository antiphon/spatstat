#
#   envelope3.R
#
#   simulation envelopes for pp3 
#
#   $Revision: 1.9 $  $Date: 2014/11/10 05:59:29 $
#

envelope.pp3 <-
  function(Y, fun=K3est, nsim=99, nrank=1, ..., 
           simulate=NULL, verbose=TRUE, 
           transform=NULL, global=FALSE, ginterval=NULL,
           alternative=c("two.sided", "less", "greater"),
           savefuns=FALSE, savepatterns=FALSE, nsim2=nsim,
           VARIANCE=FALSE, nSD=2,
           Yname=NULL, maxnerr=nsim,
           do.pwrong=FALSE, envir.simul=NULL) {
  cl <- short.deparse(sys.call())
  if(is.null(Yname)) Yname <- short.deparse(substitute(Y))
  if(is.null(fun)) fun <- K3est

  if("clipdata" %in% names(list(...)))
    stop(paste("The argument", sQuote("clipdata"),
               "is not available for envelope.pp3"))
  
  envir.user <- if(!is.null(envir.simul)) envir.simul else parent.frame()
  envir.here <- sys.frame(sys.nframe())
  
  if(is.null(simulate)) {
    # ...................................................
    # Realisations of complete spatial randomness
    # will be generated by rpoispp
    # Data pattern X is argument Y
    # Data pattern determines intensity of Poisson process
    X <- Y
    sY <- summary(Y)
    Yintens <- sY$intensity
    Ydomain <- Y$domain
    # expression that will be evaluated
    simexpr <- 
      if(!is.marked(Y)) {
        # unmarked point pattern
        expression(rpoispp3(Yintens, domain=Ydomain))
      } else {
        stop("Sorry, simulation of marked 3D point patterns is not yet implemented")
      }
    # evaluate in THIS environment
    simrecipe <- simulrecipe(type = "csr",
                             expr = simexpr,
                             envir = envir.here,
                             csr   = TRUE)
  } else {
    # ...................................................
    # Simulations are determined by 'simulate' argument
    # Processing is deferred to envelopeEngine
    simrecipe <- simulate
    # Data pattern is argument Y
    X <- Y
  }
  envelopeEngine(X=X, fun=fun, simul=simrecipe,
                 nsim=nsim, nrank=nrank, ..., 
                 verbose=verbose, clipdata=FALSE,
                 transform=transform, global=global, ginterval=ginterval,
                 alternative=alternative,
                 savefuns=savefuns, savepatterns=savepatterns, nsim2=nsim2,
                 VARIANCE=VARIANCE, nSD=nSD,
                 Yname=Yname, maxnerr=maxnerr, cl=cl,
                 envir.user=envir.user,
                 expected.arg=c("rmax", "nrval"),
                 do.pwrong=do.pwrong)
}

