# Folder where files like tables and graphs should be saved to
GENERATED_FILES <- "../generated_files"

# when generating zip files for the data, specify which folder they will be saved
RESULT_DIR_OUT <- "../results"

# specify in which folder to search for experiment result files
RESULT_DIR_IN <- RESULT_DIR_OUT

# List of SUTs expected to be used in WFD.
# This is needed to check if for any reasons some data is missing.
SUTS <- sort(c(
  "bibliothek",
  "blogapi",
  "catwatch",
  "cwa-verification",
  "erc20-rest-service",
  "familie-ba-sak",
  "features-service",
  "genome-nexus",
  "gestaohospital",
  "http-patch-spring",
  "languagetool",
  "market",
  "microcks",
  "ocvn",
  "ohsome-api",
  "pay-publicapi",
  "person-controller",
  "proxyprint",
  "quartz-manager",
  "reservations-api",
  "rest-ncs",
  "rest-news",
  "rest-scs",
  "restcountries",
  "scout-api",
  "session-service",
  "spring-actuator-demo",
  "spring-batch-rest",
  "spring-ecommerce",
  "spring-rest-example",
  "swagger-petstore",
  "tiltaksgjennomforing",
  "tracking-system",
  "user-management",
  "webgoat",
  "youtube-mock"
))


### Compute Vargha-Delaney A12 statistics
measureA <- function(a, b) {

  if (length(a) == 0 & length(b) == 0) {
    return(0.5)
  } else if (length(a) == 0) {
    ## motivation is that we have no data for "a" but we do for "b".
    ## maybe the process generating "a" always fail (eg out of memory)
    return(0)
  } else if (length(b) == 0) {
    return(1)
  }

  r <- rank(c(a, b))
  r1 <- sum(r[seq_along(a)])

  m <- length(a)
  n <- length(b)
  A <- (r1 / m - (m + 1) / 2) / n

  return(A)
}

### return a boolean vector, where each position in respect to x is true if that element appear in y
areInTheSubset <- function(x,y){

  ### first consider vector with all FALSE
  result <- x!=x
  for(k in y){
    result <- result | x==k
  }
  return(result)
}