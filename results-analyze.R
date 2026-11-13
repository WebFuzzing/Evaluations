cwd <- getwd()

dir.create("generated_files", showWarnings = FALSE)

setwd("r-analysis")

source("analyze-http.R")
all()

source("analyze-jacoco.R")
all()

source("analyze-all.R")
all()

source("analyze-wfc.R")
all()

setwd(cwd)