################################################################################################
## Analyze JaCoCo coverage results for Black-Box experiments
################################################################################################


source("commons.R")
source("tables-comparison.R")

DATA_FILE <- paste(RESULT_DIR_OUT, "/data_jacoco_bb.csv", sep = "")

## init raw  coverage file to DATA_FILE based on results produced by jacoco
init <- function() {

  ## jvm jacoco
  TABLE <- DATA_FILE
  unlink(TABLE)

  tryCatch({
    sink(TABLE, append = TRUE, split = TRUE)

    cat("SUT,TOOL,LINES,COVERED,FILENAME\n")

    for (table in sort(list.files(RESULT_DIR_IN, recursive = TRUE, full.names = TRUE, pattern = "^.*jacoco.csv$"))) {

      dt <- read.csv(table, header = T)
      fileName <- basename(table)
      tokens <- strsplit(fileName, "__")
      sut <- tokens[[1]][1]
      tool <- tokens[[1]][2]
      cat(sut, ",", tool, ",", sep = "")

      missed <- sum(dt$LINE_MISSED)
      covered <- sum(dt$LINE_COVERED)
      total <- missed + covered
      cat(total, ",", covered, ",", fileName, "\n", sep = "")
    }
  }, finally = {
    sink()
  })
}

checkData <- function() {

  dt <- read.csv(DATA_FILE, header = T)

  tools <- sort(unique(dt$TOOL))
  suts <- sort(unique(dt$SUT))



  for (s in suts) {
    cat("\n")

    sMask <- dt$SUT == s

    total <- unique(dt$LINES[sMask])[1]

    for (t in tools) {
      mask <- sMask & dt$TOOL == t

      cov <- dt$COVERED[mask]
      if (length(cov) == 0) {
        cat("WARNING: no data for ", t, " on ", s, "\n")
        cov <- c(0)
      } else {
        covAvg <- mean((cov / total) * 100)
        cat("Average coverage ", t, " (", length(cov), ") on ", s, ":", covAvg, "\n", sep = "")
      }
    }
  }

  cat("\n")
  cat("Tools: ", tools, "\n")
  cat("#SUTS:",length(suts),"\n")

  missing <- setdiff(SUTS, suts)
  if (length(missing) > 0) {
      cat("\nWARNING. Missing SUTs: ", missing, "\n")
  }

  extra <- setdiff(suts,SUTS)
  if (length(extra) > 0) {
      cat("\nWARNING. Extra SUTs: ", extra, "\n")
  }
}



computeCoverage <- function(dt, mask) {
    cov <- dt$COVERED[mask]
    if (length(cov) == 0) {
      return(c(0))
    }

    total <- unique(dt$LINES[mask])[1]

    cov <- (cov / total) * 100
    return(cov)
}




################################################################
all <- function() {

  dt <- read.csv(DATA_FILE, header = T)

  resultsLambda <- computeCoverage

  suts <- sort(unique(dt$SUT))

  tableManyConfigs(dt,resultsLambda,"comparisonAllJaCoCo.tex", suts)


  # bMask <- dt$TOOL == "base"
  # evoMask <- dt$TOOL == EVOMASTER_BB
  # testMask <- dt$TOOL == testEvoLabel
  # stMask <- dt$TOOL == SCHEMATHESIS
  #
  # tableBBTwoConfigs(dt, resultsLambda, suts,
  #   bMask,  # boolean array representing a mask over 'dt' representing the "base" configuration
  #   evoMask,  # boolean array representing a mask over 'dt', to identify all data of configuration X, used as reference
  #   testMask,  # same as yMask, but for new configuration Y compared to existing reference X
  #   "pairComparisonTests.tex"  # output file name, typically ending with ".tex"
  # )
  #
  # tableBBTwoConfigs(dt, resultsLambda, suts,
  #                   bMask,  # boolean array representing a mask over 'dt' representing the "base" configuration
  #                   evoMask,  # boolean array representing a mask over 'dt', to identify all data of configuration X, used as reference
  #                   stMask,  # same as yMask, but for new configuration Y compared to existing reference X
  #                   "pairComparisonSchemathesis.tex"  # output file name, typically ending with ".tex"
  # )
}