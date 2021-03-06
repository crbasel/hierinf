% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/print.R
\name{print.hierT}
\alias{print.hierT}
\title{Print Object of Class \code{hierT}}
\usage{
\method{print}{hierT}(x, n.terms = 5L, digits = max(3,
  getOption("digits") - 3), right = FALSE, ...)
}
\arguments{
\item{x}{an object of class \code{hierT}}

\item{n.terms}{maximum number of column names or variables names to be
printed per cluster or group of variables.}

\item{digits}{number of significant digits to be used.}

\item{right}{logical value indicating whether the values should or should
not be right-aligned.}

\item{...}{additional arguments to \code{\link{print.data.frame}}}
}
\value{
The returned values is a invisible copy of the object \code{x}.
}
\description{
Print significant clusters or groups of variables of an object of class
\code{hierT}.
}
\details{
The function prints the significant clusters or groups of variables
of an object of class \code{hierT}. By default, it prints at most the first
\code{n.terms} column or variable names per significant cluster and the
number of omitted column names are printed in square brackets (if any).
}
\examples{
n <- 200
p <- 500
library(MASS)
set.seed(3)
x <- mvrnorm(n, mu = rep(0, p), Sigma = diag(p))
colnames(x) <- paste0("Var", 1:p)
beta <- rep(0, p)
beta[c(5, 20, 46)] <- 1
y <- x \%*\% beta + rnorm(n)

dendr <- cluster_var(x = x)
sign.clusters <- test_hierarchy(x = x, y = y, dendr = dendr,
                                family = "gaussian")

# The argument n.terms is useful if there is one or multiple
# significant groups containing many variables.
# print(sign.clusters, n.terms = 4)

print(sign.clusters, right = TRUE)

print(sign.clusters, digits = 4)

}
\references{
Renaux, C. et al. (2018), Hierarchical inference for genome-wide
association studies: a view on methodology with software. (arXiv:1805.02988)
}
\seealso{
\code{\link{invisible}}.
}
