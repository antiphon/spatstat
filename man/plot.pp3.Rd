\name{plot.pp3}
\Rdversion{1.1}
\alias{plot.pp3}
\title{
  Plot a three-dimensional point pattern
}
\description{
  Plots a three-dimensional point pattern.
}
\usage{
 \method{plot}{pp3}(x, ...)
}
\arguments{
  \item{x}{
    Three-dimensional point pattern (object of class \code{"pp3"}).
  }
  \item{\dots}{
    Arguments passed to \code{scatterplot3d} controlling the plot.
  }
}
\details{
  This is the plot method for objects of class \code{"pp3"}.
  
  This function requires the \pkg{scatterplot3d} package. The
  coordinates of the point pattern are passed to the function
  \code{scatterplot3d} along with any extra arguments \code{\dots}.
}
\value{
  Null.
}
\author{Adrian Baddeley
  \email{Adrian.Baddeley@uwa.edu.au}
  \url{http://www.maths.uwa.edu.au/~adrian/}
  and Rolf Turner
  \email{r.turner@auckland.ac.nz}
}
\seealso{
  \code{\link{pp3}}
}
\examples{
  if(require(scatterplot3d)) {
    X <- osteo$pts[[1]]
    plot(X, tick.marks=FALSE, xlab="", ylab="", zlab="",
         main="Osteocyte lacunae, animal 1, brick 1",
         mar=rep(0.5,4), cex.symbols=1.5, pch=16, type="h")
  }
}
\keyword{spatial}
\keyword{hplot}
