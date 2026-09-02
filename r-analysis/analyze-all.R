source("commons.R")
source("tables-comparison.R")
source("analyze-http.R")
source("analyze-jacoco.R")

all <- function(){

  http <-  read.csv(DATA_HTTP_BB_CSV_FILE, header = T)
  jacoco <- read.csv(DATA_JACOCO_BB_CSV_FILE, header = T)

  tableToolSummary(
    "Tools", # the label used for the TOOL column
    http, # the data frame for X, containing all experiment data.
    "\\%2xx", # the label used for the X data column
    http_covered2xx, # a lambda(dt,mask) returning an array/list of result values for X.
    http, # the data frame for Y, containing all experiment data.
    "\\#500", # the label used for the Y data column
    http_covered500, # a lambda(dt,mask) returning an array/list of result values for Y.
    jacoco, # the data frame for Z, containing all experiment data.
    "\\%Lines", # the label used for the Z data column
    jacoco_computeCoverage, # a lambda(dt,mask) returning an array/list of result values for Z.
    "overall",  # output file name, without file ending type
    TEX # either "tex" or "md"
  )

  tableToolSummary(
    "Tools", # the label used for the TOOL column
    http, # the data frame for X, containing all experiment data.
    "%2xx", # the label used for the X data column
    http_covered2xx, # a lambda(dt,mask) returning an array/list of result values for X.
    http, # the data frame for Y, containing all experiment data.
    "#500", # the label used for the Y data column
    http_covered500, # a lambda(dt,mask) returning an array/list of result values for Y.
    jacoco, # the data frame for Z, containing all experiment data.
    "%Lines", # the label used for the Z data column
    jacoco_computeCoverage, # a lambda(dt,mask) returning an array/list of result values for Z.
    "overall",  # output file name, without file ending type
    MD # either "tex" or "md"
  )
}
