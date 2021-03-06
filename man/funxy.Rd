\name{funxy}
\Rdversion{1.1}
\alias{funxy}
\title{
  Spatial Function Class
}
\description{
  A simple class of functions of spatial location
}
\usage{
  funxy(f, W)
}
\arguments{
  \item{f}{
    A \code{function} in the \R language
    with arguments \code{x,y} (at least)
  }
  \item{W}{
    Window (object of class \code{"owin"}) inside which the
    function is well-defined.
  }
}
\details{
  This creates an object of class \code{"funxy"}.
  This is a simple mechanism for handling a function
  of spatial location \eqn{f(x,y)} to make it easier to display
  and manipulate.

  \code{f} should be a \code{function} in the \R language.
  The first two arguments of \code{f} must be named \code{x} and \code{y}
  respectively.

  \code{W} should be a window (object of class \code{"owin"}) inside which the
  function \code{f} is well-defined.

  The function \code{f} should be vectorised: that is,
  if \code{x} and \code{y} are numeric vectors of the same length
  \code{n}, then \code{v <- f(x,y)} should be a vector of length \code{n}.
}
\value{
  A \code{function}, in fact a copy of \code{f},
  which also belongs to the class \code{"funxy"}.
  This class has methods for
  \code{print}, \code{plot}, \code{contour} and \code{persp}.
}
\seealso{
  \code{\link{plot.funxy}}
}
\examples{
   f <- function(x,y) { x^2 + y^2 - 1} 
   g <- funxy(f, square(2))
   g(0.2, 0.3)
   g
}
\author{Adrian Baddeley
  \email{Adrian.Baddeley@uwa.edu.au}
  \url{http://www.maths.uwa.edu.au/~adrian/}
  and Rolf Turner
  \email{r.turner@auckland.ac.nz}
}
\keyword{spatial}
\keyword{math}
