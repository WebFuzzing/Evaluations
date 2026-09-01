################################################################################################
## Analyze HTTP coverage results based on proxy for Black-Box experiments
################################################################################################

source("commons.R")
source("tables-comparison.R")

library("jsonlite")
library(yaml)

DATA_FILE <- paste0(RESULT_DIR_OUT, "/data_http_bb.csv")

WFD_DIR <- Sys.glob(file.path(RESULT_DIR_IN, "*", "wfd"))[1]

## init raw  coverage file to DATA_FILE based on results produced by HTTP Proxy
init <- function() {

  TABLE <- DATA_FILE
  unlink(TABLE)

  tryCatch({
    sink(TABLE, append = TRUE, split = TRUE)

    cat("SUT,TOOL,CALLS,ENDPOINTS,COVERED2xx,COVERED500\n")

    # map from SUT name to endpoints verb:path
    endpoints <- list()

    for (table in sort(list.files(RESULT_DIR_IN, recursive = TRUE, full.names = TRUE, pattern = "^.*minlog.csv$"))) {

      #status_code,path,request.method
      dt <- read.csv(table, header = T)
      fileName <- basename(table)
      tokens <- strsplit(fileName, "__")
      sut <- tokens[[1]][1]
      tool <- tokens[[1]][2]

      if(tool=="base"){
        next
      }

      cat(sut, ",", tool, sep = "")

      calls <- nrow(dt)
      cat(",",calls, sep="")

      if(! hasName(endpoints,sut)){
         # we need to analyze an OpenAPI schema only once
         endpoints[[sut]] <- collectEndpointInfo(sut)
      }
      ep <- endpoints[[sut]]
      cat(",",length(ep),sep="")

      ok2xx   <- purrr::map_lgl(ep, ~ hasAnyMatch(.x, dt, 200, 299))
      fail500 <- purrr::map_lgl(ep, ~ hasAnyMatch(.x, dt, 500, 500))

      cat(",", sum(ok2xx),sep="")
      cat(",", sum(fail500),sep="")
      cat("\n")
    }
  }, finally = {
    sink()
  })
}

checkData <- function() {

  dt <- read.csv(DATA_FILE, header = T)

  tools <- sort(unique(dt$TOOL))
  suts <- sort(unique(dt$SUT))

  missing <- setdiff(SUTS, suts)
  if (length(missing) > 0) {
    cat("WARNING. Missing SUTs: ", missing, "\n")
  }

  for (s in suts) {
    cat("\n")

    sMask <- dt$SUT == s

    total <- unique(dt$ENDPOINTS[sMask])[1]

    for (t in tools) {
      mask <- sMask & dt$TOOL == t

      cov <- dt$COVERED2xx[mask]

      if (length(cov) == 0) {
        cat("WARNING: no data for ", t, " on ", s, "\n")
        cov <- c(0)
      } else {
        covAvg <- mean((cov / total) * 100)
        calls <- mean(dt$CALLS[mask])
        faults <- mean(dt$COVERED500[mask])
        cat("2xx coverage ", t, " (", length(cov), ") on ", s, ":", covAvg," done in ",calls," HTTP calls, finding faults: ",faults, "\n", sep = "")
      }
    }
  }
}


splitEndpoint <- function(endpoint) {
  m <- regexpr(":", endpoint)
  if (m == -1){
     stop("Invalid endpoint ", endpoint)
  }
  return(c(toupper(substr(endpoint, 1, m-1)), substr(endpoint, m+1, nchar(endpoint))))
}


hasAnyMatch <- function(endpoint,dt,codeMin,codeMax){

    verbPath <- splitEndpoint(endpoint)
    regex <- pathToRegex(verbPath[[2]])

    # for (i in seq_len(nrow(dt))) {
    #   e <- dt[i, ]
    #
    #   if(e$status_code >= codeMin && e$status_code <= codeMax && e$method==verbPath[[1]] && grepl(regex,e$path)){
    #     return(TRUE)
    #   }
    # }
    # return(FALSE)

    filtered <- dt[dt$method == verbPath[[1]] &
                   dt$status_code >= codeMin &
                   dt$status_code <= codeMax, ]
    return(any(grepl(regex, filtered$path)))
}


collectEndpointInfo <- function(sut){

    schema <- readSchema(sut)

    # OpenAPI v2
    basePath <- schema$basePath
    if (is.null(basePath)) {

        basePath <- "/"

        # OpenAPI v3
        if(!is.null(schema$servers)){

          if(is.data.frame(schema$servers)){
            if(nrow(schema$servers)>0 ){
              url <- schema$servers$url[[1]]
            }

          } else if(is.list(schema$servers)){
             if(length(schema$servers)>0){
               url <- schema$servers[[1]]$url
             }
          } else {
            stop("Can't handle schema$servers of type ", class(schema$servers))
          }

          if(!is.null(url)){
            path <- httr::parse_url(url)$path
            if(!is.null(path) && path != ""){
              basePath <- combinePaths("/",path)
            }
          }
        }
    }

    paths <- schema$paths
    if (is.null(paths)) {
        stop("No paths found in the OpenAPI schema")
    }

    endpoints <- character()

    for (path_name in names(paths)) {

        full_path <- combinePaths(basePath, path_name)

        path_item <- paths[[path_name]]
        for (method in names(path_item)) {
          if (method %in% c("get", "post", "put", "delete", "patch", "head", "options", "trace")) {
            endpoints <- c(endpoints, paste0(toupper(method),":",full_path))
          } else {
            stop("Unrecognized method ", method)
          }
        }
    }
    return(endpoints)
}

combinePaths <- function(basePath, path){
    if (is.null(basePath) || basePath=="" || basePath == "/") {
      if(startsWith(path, "/")){
        return(path)
      }
      return(paste0("/",path))
    }
    if(! startsWith(basePath,"/")){
      basePath <- "/" + basePath
    }
    if(endsWith(basePath,"/") && startsWith(path,"/")){
      basePath <- substr(basePath, 1, nchar(basePath) - 1)
    }
    return(paste0(basePath,path))
}

pathToRegex <- function(path) {
  # Escape special regex characters first, but not {}
  path <- stringr::str_replace_all(path, "([.+*?^$()\\[\\]|])", "\\\\\\1")
  # Replace {param} with [^/]+ (matches any character except /)
  path <- stringr::str_replace_all(path, "\\{[^}]+\\}", "[^/]+")
  # Ensure exact match from start to end. ignore ? query params and # anchors
  paste0("^", path, "(?:[?#].*)?$")
}

readSchema <- function(base_name) {

  schema_folder <- paste0(WFD_DIR,"/openapi/")
  json_file <- paste0(schema_folder,base_name, ".json")
  yaml_file <- paste0(schema_folder,base_name, ".yaml")

  if (file.exists(json_file)) {
    tryCatch({
      return(jsonlite::fromJSON(json_file))
    }, error = function(e) {
      stop("Failed to parse JSON file ", json_file, " : ", e$message)
    })
  } else if (file.exists(yaml_file)) {
    tryCatch({
      return(yaml::read_yaml(yaml_file))
    }, error = function(e) {
      stop("Failed to parse YAML file ", yaml_file," : ", e$message)
    })
  } else {
    stop("Neither ", json_file, " nor ", yaml_file, " exists")
  }
}



################################################################
all <- function() {

  dt <- read.csv(DATA_FILE, header = T)

  covered2xx <- function(dt,mask){
    cov <- dt$COVERED2xx[mask]
    if (length(cov) == 0) {
      return(c(0))
    }
    total <- unique(dt$ENDPOINTS[mask])[1]
    cov <- (cov / total) * 100
    return(cov)
  }
  covered500 <- function(dt,mask){
    cov <- dt$COVERED500[mask]
    if(length(cov) == 0){
      return(c(0))
    }
    return(cov)
  }

  suts <- sort(unique(dt$SUT))

  tableManyConfigs(dt,covered2xx, "comparisonAll2xx", "tex", suts)
  tableManyConfigs(dt,covered500, "comparisonAll500", "tex",suts)
  tableManyConfigs(dt,covered2xx, "comparisonAll2xx", "md", suts)
  tableManyConfigs(dt,covered500, "comparisonAll500", "md",suts)
}
