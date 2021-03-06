# 
#  fitted.ppm.R
#
# method for 'fitted' for ppm objects
#
#   $Revision: 1.12 $   $Date: 2014/10/07 05:13:22 $
# 

fitted.ppm <- function(object, ..., type="lambda", dataonly=FALSE,
                       new.coef=NULL, leaveoneout=FALSE,
                       drop=FALSE, check=TRUE, repair=TRUE) {
  verifyclass(object, "ppm")
  
  if(check && damaged.ppm(object)) {
    if(!repair)
      stop("object format corrupted; try update(object, use.internal=TRUE)")
    message("object format corrupted; repairing it.")
    object <- update(object, use.internal=TRUE)
  }

  if(leaveoneout) {
    ## Leave-one-out calculation for data points only
    if(missing(dataonly)) dataonly <- TRUE
    if(!dataonly)
      stop("Leave-one-out calculation requires dataonly=FALSE")
    if(!is.null(new.coef))
      stop("Leave-one-out calculation requires new.coef=NULL")
  }
  
  fitcoef <- coef(object)
  if(!is.null(new.coef)) {
    # validate
    if(length(new.coef) != length(fitcoef))
      stop(paste("Argument new.coef has wrong length",
                 length(new.coef), ": should be", length(fitcoef)))
    coeffs <- new.coef
  } else {
    coeffs <- fitcoef
  }
  
  uniform <- is.poisson.ppm(object) && no.trend.ppm(object)

  typelist <- c("lambda", "cif",    "trend")
  typevalu <- c("lambda", "lambda", "trend")
  if(is.na(m <- pmatch(type, typelist)))
    stop(paste("Unrecognised choice of ", sQuote("type"),
               ": ", sQuote(type), sep=""))
  type <- typevalu[m]
  
  if(uniform) {
    lambda <- exp(coeffs[[1]])
    Q <- quad.ppm(object, drop=drop)
    lambda <- rep.int(lambda, n.quad(Q))
  } else {
    glmdata <- getglmdata(object, drop=drop)
    glmfit  <- getglmfit(object)
    Vnames <- object$internal$Vnames
    interacting <- (length(Vnames) != 0)
    
    # Modification of `glmdata' may be required
    if(interacting) 
      switch(type,
           trend={
             # zero the interaction statistics
             glmdata[ , Vnames] <- 0
           },
           lambda={
             # Find any dummy points with zero conditional intensity
             forbid <- matrowany(as.matrix(glmdata[, Vnames]) == -Inf)
             # exclude from predict.glm
             glmdata <- glmdata[!forbid, ]
           })

    # Compute predicted [conditional] intensity values
    changecoef <- !is.null(new.coef) || (object$method != "mpl")
    lambda <- GLMpredict(glmfit, glmdata, coeffs, changecoef=changecoef)
    
    # Note: the `newdata' argument is necessary in order to obtain
    # predictions at all quadrature points. If it is omitted then
    # we would only get predictions at the quadrature points j
    # where glmdata$SUBSET[j]=TRUE. Assuming drop=FALSE.

    if(interacting && type=="lambda") {
     # reinsert zeroes
      lam <- numeric(length(forbid))
      lam[forbid] <- 0
      lam[!forbid] <- lambda
      lambda <- lam
    }

  }
  if(dataonly)
    lambda <- lambda[is.data(quad.ppm(object))]

  if(leaveoneout) {
    ## Perform leverage calculation
    dfb <- dfbetas(object)
    delta <- with(dfb, 'discrete')[with(dfb, 'is.atom'),,drop=FALSE]
    ## adjust fitted value
    mom <- model.matrix(object)[is.data(quad.ppm(object)),,drop=FALSE]
    if(type == "trend" && !uniform && interacting)
      mom[, Vnames] <- 0
    lambda <- lambda * exp(- rowSums(delta * mom))
  }
  return(lambda)
}


