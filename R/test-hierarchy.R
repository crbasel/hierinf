#' Hierarchical Testing
#'
#' Hierarchical testing based on multi-sample splitting.
#'
#' @param x a matrix or list of matrices for multiple data sets. The matrix or
#' matrices have to be of type numeric and are required to have column names
#' / variable names. The rows and the columns represent the observations and
#' the variables, respectively.
#' @param y a vector, a matrix with one column, or list of the aforementioned
#' objects for multiple data sets. The vector, vectors, matrix, or matrices
#' have to be of type numeric. For \code{family = "binomial"}, the response
#' is required to be a binary vector taking values 0 and 1.
#' @param dendr the output of one of the functions
#' \code{\link{cluster_var}} or \code{\link{cluster_position}}.
#' @param clvar a matrix or list of matrices of control variables.
#' @param family a character string naming a family of the error distribution;
#' either \code{"gaussian"} or \code{"binomial"}.
#' @param B number of sample splits.
#' @param proportion.select proportion of variables to be selected by Lasso in
#' the multi-sample splitting step.
#' @param standardize a logical value indicating whether the variables should be
#' standardized.
#' @param alpha the significant level at which the FWER is controlled.
#' @param global.test a logical value indicating whether the global test should
#' be performed.
#' @param agg.method a character string naming an aggregation method which
#' aggregates the p-values over the different data sets for a given cluster;
#' either \code{"Tippett"} (Tippett's rule) or \code{"Stouffer"}
#' (Stouffer's rule). This argument is only relevant if multiple data sets
#' are specified in the function call.
#' @param verbose logical value indicating whether the progress of the computation
#' should be printed in the console.
#' @param sort.parallel a logical indicating whether the values are sorted with respect to
#' the size of the block. This can reduce the run time for parallel computation.
#' @param parallel type of parallel computation to be used. See the 'Details' section.
#' @param ncpus number of processes to be run in parallel.
#' @param cl an optional \strong{parallel} or \strong{snow} cluster used if
#' \code{parallel = "snow"}. If not supplied, a cluster on the local machine is created.
#'
#' @details The hierarchial testing requires the output of one of the functions
#' \code{\link{cluster_var}} or \code{\link{cluster_position}}
#' as an input (argument \code{dendr}).
#'
#' The function first performs multi-sample splitting step.
#' A given data with \code{nobs} is randomly split in two halves w.r.t.
#' the observations and \code{nobs * proportion.select} variables are selected
#' using Lasso (implemented in \code{\link{glmnet}}) on one half.
#' Control variables are not penalized if supplied
#' using the argument \code{clvar}. This is repeated \code{B} times for each
#' data set if multiple data sets are supplied.
#'
#' Those splits (i.e. second halves of observations) and corresponding selected
#' variables are used to perform hierarchical testing by going top down
#' through the hierarchical tree. Testing only continues if at least one
#' child of a given cluster is significant.
#'
#' The multi-sample splitting step can be run in parallel across the
#' different sample splits where the argument \code{B} corresponds to number
#' of sample splits. If the argument \code{block} was supplied for the building
#' of the hierarchical tree (i.e. in the function call of either
#' \code{\link{cluster_var}} or \code{\link{cluster_position}}),
#' i.e. the second level of the hierarchical tree was given, the hierarchical
#' testing step can be run in parallel across the different blocks by
#' specifying the arguments \code{parallel} and \code{ncpus}.
#' There is an optional argument \code{cl} if
#' \code{parallel = "snow"}. There are three possibilities to set the
#' argument \code{parallel}: \code{parallel = "no"} for serial evaluation
#' (default), \code{parallel = "multicore"} for parallel evaluation
#' using forking, and \code{parallel = "snow"} for parallel evaluation
#' using a parallel socket cluster. It is recommended to select
#' \code{\link{RNGkind}("L'Ecuyer-CMRG")} and set a seed to ensure that
#' the parallel computing of the package \code{hierinf} is reproducible.
#' This way each processor gets a different substream of the pseudo random
#' number generator stream which makes the results reproducible if the arguments
#' (as \code{sort.parallel} and \code{ncpus}) remain unchanged. See the vignette
#' or the reference for more details.
#'
#' Note that if Tippett's aggregation method is applied for multiple data
#' sets, then very small p-values are set to machine precision. This is
#' due to rounding in floating point arithmetic.
#'
#' @return The returned value is an object of class \code{"hierT"},
#' consisting of two elements, the result of the multi-sample splitting step
#' \code{"res.multisplit"} and the result of the hierarchical testing
#' \code{"res.hierarchy"}.
#'
#' The result of the multi-sample splitting step is a list with number of
#' elements corresponding to the number of data sets. Each element
#' (corresponding to a data set) contains a list with two matrices. The first
#' matrix contains the indices of the second half of variables (which were
#' not used to select the variables). The second matrix contains the column
#' names / variable names of the selected variables.
#'
#' The result of the hierarchical testing is a data frame of significant
#' clusters with the following columns:
#' \item{block}{\code{NA} or the name of the block if the significant cluster
#' is a subcluster of the block or is the block itself.}
#' \item{p.value}{The p-value of the significant cluster.}
#' \item{significant.cluster}{The column names of the members of the significant
#' cluster.}
#'
#' There is a \code{print} method for this class; see
#' \code{\link{print.hierT}}.
#'
#' @seealso \code{\link{cluster_var}},
#' \code{\link{cluster_position}}, and
#' \code{\link{compute_r2}}.
#'
#' @examples
#' n <- 200
#' p <- 500
#' library(MASS)
#' set.seed(3)
#' x <- mvrnorm(n, mu = rep(0, p), Sigma = diag(p))
#' colnames(x) <- paste0("Var", 1:p)
#' beta <- rep(0, p)
#' beta[c(5, 20, 46)] <- 1
#' y <- x %*% beta + rnorm(n)
#'
#' dendr1 <- cluster_var(x = x)
#' set.seed(68)
#' sign.clusters1 <- test_hierarchy(x = x, y = y, dendr = dendr1,
#'                                 family = "gaussian")
#'
#' ## With block
#' # The column names of the data frame block are optional.
#' block <- data.frame("var.name" = paste0("Var", 1:p),
#'                     "block" = rep(c(1, 2), each = p/2),
#'                     stringsAsFactors = FALSE)
#' dendr2 <- cluster_var(x = x, block = block)
#' set.seed(23)
#' sign.clusters2 <- test_hierarchy(x = x, y = y, dendr = dendr2,
#'                                 family = "gaussian")
#'
#' # Access part of the object
#' sign.clusters2$res.hierarchy[, "block"]
#' sign.clusters2$res.hierarchy[, "p.value"]
#' # Column names or variable names of the significant cluster in the first row.
#' sign.clusters2$res.hierarchy[[1, "significant.cluster"]]
#'
#' @references Renaux, C. et al. (2018), Hierarchical inference for genome-wide
#' association studies: a view on methodology with software. (arXiv:1805.02988)
#'
#' @name test_hierarchy
#' @export

test_hierarchy <- function(x, y, dendr, clvar = NULL,
                           family = c("gaussian", "binomial"),
                           B = 50, proportion.select = 1/6, standardize = FALSE,
                           alpha = 0.05, global.test = TRUE,
                           agg.method = c("Tippett", "Stouffer"),
                           verbose = FALSE, sort.parallel =  TRUE,
                           parallel = c("no", "multicore", "snow"),
                           ncpus = 1L, cl = NULL) {

  family <- match.arg(family)
  agg.method <- match.arg(agg.method)
  parallel <- match.arg(parallel)

  ## Check input
  res <- check_input_testing(x = x, y = y, clvar = clvar, family = family,
                             # check result of the function multisplit
                             check_res_multisplit = FALSE,
                             res.multisplit = NULL,
                             # arguments for the function multisplit
                             check_multisplit_arguments = TRUE,
                             B = B, proportion.select = proportion.select,
                             standardize = standardize,
                             # arguments for the function
                             # test_hierarchy_given_multisplit
                             check_testing_arguments = TRUE,
                             dendr = dendr$res.tree, block = dendr$block,
                             alpha = alpha, global.test = global.test,
                             agg.method = agg.method, verbose = verbose)
  rm(list = c("x", "y", "clvar"))

  ## call multisplit
  if (verbose) {
    message("Multi-sample splitting step.") # TODO change message
  }

  res.multisplit <- multisplit(x = res$x, y = res$y, clvar = res$clvar, B = B,
                               proportion.select = proportion.select,
                               standardize = standardize, family = family,
                               parallel = parallel, ncpus = ncpus,
                               cl = cl, check.input = FALSE)

  # Stop testing if some error occurred during the function call of multisplit
  if (!is.null(attr(res.multisplit, "errorMsgs"))) {
    warning("There occurred some errors while multi-sample splitting. Testing does not proceed! Only the output of the multi splitting is returned.  See attribute 'errorMsgs' of the return object for more details.")
    return(res.multisplit)
  }

  ## call test_only_hierarchy
  if (verbose) {
    message("Testing the hierarchy.")
  }

  res.testing <- test_only_hierarchy(x = res$x, y = res$y, dendr = dendr,
                                     res.multisplit = res.multisplit,
                                     clvar = res$clvar, family = family,
                                     alpha = alpha, global.test = global.test,
                                     agg.method = agg.method,
                                     verbose = verbose,
                                     sort.parallel =  sort.parallel,
                                     parallel = parallel, ncpus = ncpus,
                                     cl = cl, check.input = FALSE,
                                     unique.colnames.x = res$unique_colnames_x)

  # # Check if there occurred warnings or erros
  # if (!is.null(attr(res.testing$res.hierarchy, "errorMsgs"))) {
  #   warning("There occurred some errors while testing the hierarchy. See attribute 'errorMsgs' of the corresponding list element of the return object for more details.")
  # }
  # if (!is.null(attr(res.testing$res.hierarchy, "warningMsgs")) | !is.null(attr(res.testing$res.multisplit, "warningMsgs"))) {
  #   warning("There occurred some warnings while multi splitting and / or testing the hierarchy. See attribute 'warningMsgs' of the corresponding list element of the return object for more details.")
  # }

  return(res.testing)
}
