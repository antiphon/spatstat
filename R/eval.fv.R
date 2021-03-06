#
#     eval.fv.R
#
#
#        eval.fv()             Evaluate expressions involving fv objects
#
#        compatible.fv()       Check whether two fv objects are compatible
#
#     $Revision: 1.28 $     $Date: 2014/11/11 10:33:33 $
#

eval.fv <- local({

  # main function
  eval.fv <- function(expr, envir, dotonly=TRUE) {
    # convert syntactic expression to 'expression' object
    e <- as.expression(substitute(expr))
    # convert syntactic expression to call
    elang <- substitute(expr)
    # find names of all variables in the expression
    varnames <- all.vars(e)
    if(length(varnames) == 0)
      stop("No variables in this expression")
    # get the actual variables
    if(missing(envir)) {
      envir <- parent.frame()
    } else if(is.list(envir)) {
      envir <- list2env(envir, parent=parent.frame())
    }
    vars <- lapply(as.list(varnames), get, envir=envir)
    names(vars) <- varnames
    # find out which ones are fv objects
    fvs <- unlist(lapply(vars, is.fv))
    nfuns <- sum(fvs)
    if(nfuns == 0)
      stop("No fv objects in this expression")
    # extract them
    funs <- vars[fvs]
    # restrict to columns identified by 'dotnames'
    if(dotonly) 
      funs <- lapply(funs, restrict.to.dot)
    # test whether the fv objects are compatible
    if(nfuns > 1 && !(do.call("compatible", unname(funs)))) {
      warning(paste(if(nfuns > 2) "some of" else NULL,
                    "the functions",
                    commasep(sQuote(names(funs))),
                    "were not compatible: enforcing compatibility"))
      funs <- do.call(harmonise.fv, funs)
    }
    # copy first object as template
    result <- funs[[1]]
    labl <- attr(result, "labl")
    origdotnames   <- fvnames(result, ".")
    origshadenames <- fvnames(result, ".s")
    # determine which function estimates are supplied
    argname <- fvnames(result, ".x")
    nam <- names(result)
    ynames <- nam[nam != argname]
    # for each function estimate, evaluate expression
    for(yn in ynames) {
      # extract corresponding estimates from each fv object
      funvalues <- lapply(funs, "[[", i=yn)
      # insert into list of argument values
      vars[fvs] <- funvalues
      # evaluate
      result[[yn]] <- eval(e, vars, enclos=envir)
    }
    # determine mathematical labels.
    # 'yexp' determines y axis label
    # 'ylab' determines y label in printing and description
    # 'fname' is sprintf-ed into 'labl' for legend
    yexps <- lapply(funs, attr, which="yexp")
    ylabs <- lapply(funs, attr, which="ylab")
    fnames <- lapply(funs, getfname)
    # Repair 'fname' attributes if blank
    blank <- unlist(lapply(fnames, function(z) { !any(nzchar(z)) }))
    if(any(blank)) {
      # Set function names to be object names as used in the expression
      for(i in which(blank))
        attr(funs[[i]], "fname") <- fnames[[i]] <- names(funs)[i]
    }
    # Remove duplicated names
    # Typically occurs when combining several K functions, etc.
    # Tweak fv objects so their function names are their object names
    # as used in the expression
    if(anyDuplicated(fnames)) {
      newfnames <- names(funs)
      for(i in 1:nfuns)
        funs[[i]] <- rebadge.fv(funs[[i]], new.fname=newfnames[i])
      fnames <- newfnames
    }
    if(anyDuplicated(ylabs)) {
      flatnames <- lapply(funs, flatfname)
      for(i in 1:nfuns) {
        new.ylab <- substitute(f(r), list(f=flatnames[[i]]))
        funs[[i]] <- rebadge.fv(funs[[i]], new.ylab=new.ylab)
      }
      ylabs <- lapply(funs, attr, which="ylab")
    }
    if(anyDuplicated(yexps)) {
      newfnames <- names(funs)
      for(i in 1:nfuns) {
        new.yexp <- substitute(f(r), list(f=as.name(newfnames[i])))
        funs[[i]] <- rebadge.fv(funs[[i]], new.yexp=new.yexp)
      }
      yexps <- lapply(funs, attr, which="yexp")
    }
    # now compute y axis labels for the result
    attr(result, "yexp") <- eval(substitute(substitute(e, yexps),
                                            list(e=elang)))
    attr(result, "ylab") <- eval(substitute(substitute(e, ylabs),
                                            list(e=elang)))
    # compute fname equivalent to expression
    if(nfuns > 1) {
      # take original expression
      the.fname <- paren(flatten(deparse(elang)))
    } else if(nzchar(oldname <- flatfname(funs[[1]]))) {
      # replace object name in expression by its function name
      namemap <- list(as.name(oldname)) 
      names(namemap) <- names(funs)[1]
      the.fname <- deparse(eval(substitute(substitute(e, namemap),
                                           list(e=elang))))
    } else the.fname <- names(funs)[1]
    attr(result, "fname") <- the.fname
    # now compute the [modified] y labels
    labelmaps <- lapply(funs, fvlabelmap, dot=FALSE)
    for(yn in ynames) {
      # labels for corresponding columns of each argument
      funlabels <- lapply(labelmaps, "[[", i=yn)
      # form expression involving these columns
      labl[match(yn, names(result))] <-
        flatten(deparse(eval(substitute(substitute(e, f),
                                        list(e=elang, f=funlabels)))))
    }
    attr(result, "labl") <- labl
    # copy dotnames and shade names from template
    fvnames(result, ".") <- origdotnames[origdotnames %in% names(result)]
    if(!is.null(origshadenames) && all(origshadenames %in% names(result)))
      fvnames(result, ".s") <- origshadenames
    return(result)
  }

  # helper functions
  restrict.to.dot <- function(z) {
    argu <- fvnames(z, ".x")
    dotn <- fvnames(z, ".")
    shadn <- fvnames(z, ".s")
    ok <- colnames(z) %in% unique(c(argu, dotn, shadn))
    return(z[, ok])
  }
  getfname <- function(x) { if(!is.null(y <- attr(x, "fname"))) y else "" }
  flatten <- function(x) { paste(x, collapse=" ") }
  eval.fv
})
    
compatible <- function(A, B, ...) {
  UseMethod("compatible")
}

compatible.fv <- function(A, B, ...) {
  verifyclass(A, "fv")
  if(missing(B)) {
    answer <- if(length(...) == 0) TRUE else compatible(A, ...)
    return(answer)
  }
  verifyclass(B, "fv")
  # are columns the same?
  namesmatch <-
    identical(all.equal(names(A),names(B)), TRUE) &&
    (fvnames(A, ".x") == fvnames(B, ".x")) &&
    (fvnames(A, ".y") == fvnames(B, ".y"))
  if(!namesmatch)
    return(FALSE)
  # are 'r' values the same ?
  rA <- with(A, .x)
  rB <- with(B, .x)
  approx.equal <- function(x, y) { max(abs(x-y)) <= .Machine$double.eps }
  rmatch <- (length(rA) == length(rB)) && approx.equal(rA, rB)
  if(!rmatch)
    return(FALSE)
  # A and B are compatible
  if(length(list(...)) == 0)
    return(TRUE)
  # recursion
  return(compatible.fv(B, ...))
}

# force a list of images to be compatible with regard to 'x' values

harmonize <- harmonise <- function(...) {
  UseMethod("harmonise")
}

harmonize.fv <- harmonise.fv <- function(...) {
  argh <- list(...)
  n <- length(argh)
  if(n < 2) return(argh)
  isfv <- unlist(lapply(argh, is.fv))
  if(!all(isfv))
    stop("All arguments must be fv objects")
  ## determine range of argument
  ranges <- lapply(argh, function(f) { range(with(f, .x)) })
  xrange <- c(max(unlist(lapply(ranges, min))),
              min(unlist(lapply(ranges, max))))
  if(diff(xrange) < 0)
    stop("No overlap in ranges of argument")
  ## determine finest resolution
  xsteps <- unlist(lapply(argh, function(f) { mean(diff(with(f, .x))) }))
  finest <- which.min(xsteps)
  ## extract argument values
  xx <- with(argh[[finest]], .x)
  xx <- xx[xrange[1] <= xx & xx <= xrange[2]]
  xrange <- range(xx)
  ## convert each fv object to a function
  funs <- lapply(argh, as.function, value="*")
  ## evaluate at common argument
  result <- vector(mode="list", length=n)
  for(i in 1:n) {
    ai <- argh[[i]]
    fi <- funs[[i]]
    xxval <- list(xx=xx)
    names(xxval) <- fvnames(ai, ".x")
    starnames <- fvnames(ai, "*")
    ## ensure they are given in same order as current columns
    starnames <- colnames(ai)[colnames(ai) %in% starnames]
    yyval <- lapply(starnames,
                    function(v,xx,fi) fi(xx, v),
                    xx=xx, fi=fi)
    names(yyval) <- starnames
    ri <- do.call("data.frame", append(xxval, yyval))
    fva <- .Spatstat.FvAttrib
    attributes(ri)[fva] <- attributes(ai)[fva]
    class(ri) <- c("fv", class(ri))
    attr(ri, "alim") <- intersect.ranges(attr(ai, "alim"), xrange)
    result[[i]] <- ri
  }
  names(result) <- names(argh)
  return(result)
}
