cwd <- getwd()

setwd("r-analysis")

source("analyze-http.R")
init()

source("analyze-jacoco.R")
init()

source("analyze-wfc.R")
init()

setwd(cwd)


verifyCSV <- function(path){

  dt <- read.csv(path, header = T)

  tools <- sort(unique(dt$TOOL))
  suts <- sort(unique(dt$SUT))

  cat(path,"\n")
  cat("#Tools ", length(tools), ":", tools, "\n")
  cat("#SUTs: ", length(suts), "\n")

  missing <- setdiff(SUTS, suts)
  if (length(missing) > 0) {
    cat("WARNING. Missing SUTs: ", missing, "\n")
  }
}

verify <- function(){
  verifyCSV("./results/data_http_bb.csv")
  verifyCSV("./results/data_jacoco_bb.csv")
  verifyCSV("./results/data_wfc_report.csv")
}