cwd <- getwd()

setwd("r-analysis")

source("analyze-http.R")
init()

source("analyze-jacoco.R")
init()

source("analyze-wfc.R")
init()

setwd(cwd)
