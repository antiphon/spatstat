## stienen.R
##
##  Stienen diagram with border correction
##
##  $Revision: 1.5 $ $Date: 2014/09/22 11:15:42 $

stienen <- function(X, ..., bg="grey", border=list(bg=NULL)) {
  Xname <- short.deparse(substitute(X))
  stopifnot(is.ppp(X))
  if(npoints(X) <= 1) {
    do.call(plot,
            resolve.defaults(list(x=Window(X)),
                             list(...),
                             list(main=Xname)))
    return(invisible(NULL))
  }
  d <- nndist(X)
  b <- bdist.points(X)
  Y <- X %mark% d
  gp <- graphicsPars("symbols")
  do.call.plotfun(plot.ppp,
                  resolve.defaults(list(x=Y[b >= d],
                                        markscale=1),
                                   list(...),
                                   list(bg=bg),
                                   list(main=Xname)),
                  extrargs=gp)
  do.call.plotfun(plot.ppp,
                  resolve.defaults(list(x=Y[b < d],
                                        markscale=1,
                                        add=TRUE),
                                   border,
                                   list(...),
                                   list(bg=bg),
                                   list(cols="grey", lwd=2)),
                  extrargs=gp)
  return(invisible(NULL))
}

stienenSet <- function(X, edge=TRUE) {
  stopifnot(is.ppp(X))
  nnd <- nndist(X)
  if(!edge) {
    ok <- bdist.points(X) >= nnd
    X <- X[ok]
    nnd <- nnd[ok]
  }
  n <- npoints(X)
  if(n == 0) return(emptywindow(Window(X)))
  if(n == 1) return(Window(X))
  d <- nnd/2
  delta <- 2 * pi * max(d)/128
  Z <- disc(d[1], X[1], delta=delta)
  for(i in 2:n) Z <- union.owin(Z, disc(d[i], X[i], delta=delta))
  return(Z)
}
