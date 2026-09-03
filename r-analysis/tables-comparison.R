################################################################################
## Utility for creating tables in which 2 or more tools are compared.
##
## Input data frames (dt) MUST have the columns SUT and TOOL, which are accessed
## here directly, eg, dt$SUT and dt$TOOL.
## Any other column must be accessed via input provided lambdas, ie, must NOT
## be accessed directly by using for example dt$foo.
## The reason is that data frames might have different structures (eg WB vs BB),
## while still trying to re-use as much of the same R code as possible.
################################################################################

TEX <- "tex"
MD  <- "md"

verifyDataFrame <- function(dt){

  if(! ("SUT" %in% names(dt))){
    stop("Data frame has no column called SUT")
  }
  if(! ("TOOL" %in% names(dt))){
    stop("Data frame has no column called TOOL")
  }
}

verifyFormat <- function(format){
  if( format != TEX && format != MD){
    stop(paste0("Invalid format '", format, "'"))
  }
}


printAverage <- function(x) {
    cat(formatC(mean(x), digits = 1, format = "f"))
}


printDiff <- function(
    x, # an array of data
    y, # another array of data, possibly of different length
    lambda # function from vector x to a single value, eg, mean or median
){
    diff <- lambda(x) - lambda(y)
    if(diff > 0){
      cat("+")
    }
    cat(formatC(diff, digits = 1, format = "f"), sep = "")
}


################################################################################
tableBBSingleConfigVsBase <- function(
  dt, # the data frame, containing all experiment data
  resultsLambda, # a lambda(dt,mask) returning an array/list of result values.
           # could be a column of dt, eg, dt$someResults[mask], or a transformation
           # involving more than 1 column, eg, cov/tot.
  projects, #  list of SUT names, to include in the table (in case we want to skip some)
  bMask,  # boolean array representing a mask over 'dt' representing the "base" configuration
  xMask,  # boolean array representing a mask over 'dt', to identify all data of configuration X, compared to 'base'
  tableFileName  # output file name, typically ending with ".tex"
) {

  TABLE <- paste0(GENERATED_FILES, "/", tableFileName)
  unlink(TABLE)
  sink(TABLE, append = TRUE, split = TRUE)

  averages <- matrix(nrow = length(projects), ncol = 2) # B, X

  tryCatch({
    cat("\\begin{tabular}{ l r|  rrr| r }\\\\ \n")
    cat("\\toprule \n")
    cat(" SUT   & $B$ & $min(X) $ & $X$ & $max(X)$  & $X-B$  \\\\ \n", sep = "")
    cat("\\midrule \n")

    for (i in 1:length(projects)) {
      proj <- projects[[i]]
      cat("\\emph{", proj, "}", sep = "")
      sMask <- dt$SUT == proj

      cat(" & ")
      B <- resultsLambda(dt, sMask & bMask)
      printAverage(B)
      averages[i, 1] <- mean(B)

      X <- resultsLambda(dt, sMask & xMask)

      cat(" & ")
      cat(formatC(min(X), digits = 1, format = "f"))
      cat(" & ")
      printAverage(X)
      cat(" & ")
      cat(formatC(max(X), digits = 1, format = "f"))

      cat(" & ")
      printDiff(X,B,mean)
      averages[i, 2] <- mean(X)

      cat(" \\\\ \n")
    }

    printSummaryComparison <- function(data, lambda) {
        B <- data[, 1]
        X <- data[, 2]

        cat(" & ")
        cat(formatC(lambda(B), digits = 1, format = "f"), sep = "")
        cat(" & ")
        # min
        cat(" & ")
        cat(formatC(lambda(X), digits = 1, format = "f"), sep = "")
        cat(" & ")
        # max
        cat(" & ")
        printDiff(X,B,lambda)
    }

    cat("\\midrule \n")
    cat("Mean ")
    printSummaryComparison(averages, mean)
    cat(" \\\\ \n")

    cat("Median ")
    printSummaryComparison(averages, median)
    cat(" \\\\ \n")

    cat("\\bottomrule \n")
    cat("\\end{tabular} \n")

  }, finally = {
    sink()
  })
}




################################################################
tableBBTwoConfigs <- function(
  dt, # the data frame, containing all experiment data. besides X and Y, it requires data for "base" tool
  resultsLambda, # a lambda(dt,mask) returning an array/list of result values.
           # could be a column of dt, eg, dt$someResults[mask], or a transformation
           # involving more than 1 column, eg, cov/tot.
  projects, #  list of SUT names, to include in the table (in case we want to skip some)
  bMask,  # boolean array representing a mask over 'dt' representing the "base" configuration
  xMask,  # boolean array representing a mask over 'dt', to identify all data of configuration X, used as reference
  yMask,  # same as yMask, but for new configuration Y compared to existing reference X
  tableFileName  # output file name, typically ending with ".tex"
) {

  TABLE <- paste0(GENERATED_FILES, "/", tableFileName)
  unlink(TABLE)
  sink(TABLE, append = TRUE, split = TRUE)

  printComparisonAndGetA12 <- function(other,base) {

    cat(" & ")
    printDiff(other,base,mean)

    A <- measureA(other, base)

    if (length(other) == 0 | length(base) == 0)
      p <- 1
    else {
      w <- wilcox.test(other, base)
      p <- w$p.value
    }
    significant <- FALSE

    if (is.nan(p)) {
      p <- "1.000"
    } else if (p < 0.001) {
      significant <- TRUE
      p <- "$< 0.001$"
    } else {
      if (p <= 0.05) {
        significant <- TRUE
      }
      p <- formatC(p, digits = 3, format = "f")
    }

    cat(" & ")
    if (significant)
      cat("{\\bf ", sep = "")
    cat(formatC(A, digits = 2, format = "f"), sep = "")
    if (significant)
      cat("}", sep = "")

    cat(" & ")
    cat(p)
    return(A)
  }

  printSummaryComparison <- function(data, lambda) {
    B <- data[, 1]
    X <- data[, 2]
    Y <- data[, 3]
    A <- data[, 4]

    cat(" & ")
    cat(formatC(lambda(B), digits = 1, format = "f"), sep = "")
    cat(" & ")
    cat(formatC(lambda(X), digits = 1, format = "f"), sep = "")
    cat(" & ")
    printDiff(X,B,lambda)
    cat(" & ")
    cat(formatC(lambda(Y), digits = 1, format = "f"), sep = "")
    cat(" & ")
    printDiff(Y,B,lambda)
    cat(" & ")
    printDiff(X,Y,lambda)
    cat(" & ")
    cat(formatC(lambda(A), digits = 2, format = "f"), sep = "")
    cat(" & ") # no pvalue
  }


  averages <- matrix(nrow = length(projects), ncol = 4) # B, X, Y, A

  tryCatch({
    cat("\\begin{tabular}{ l r|  rr|  rr| rrr}\\\\ \n")
    cat("\\toprule \n")
    cat(" SUT   & $B$ & $X$ & $X-B$ & $Y$  & $Y-B$ &  $X-Y$  & $\\hat{A}_{XY}$ & p-value  \\\\ \n", sep = "")
    cat("\\midrule \n")


    for (i in 1:length(projects)) {
      proj <- projects[[i]]
      cat("\\emph{", proj, "}", sep = "")
      sMask <- dt$SUT == proj

      cat(" & ")
      B <- resultsLambda(dt, sMask & bMask)
      printAverage(B)
      averages[i, 1] <- mean(B)

      X <- resultsLambda(dt, sMask & xMask)
      cat(" & ")
      printAverage(X)
      cat(" & ")
      printDiff(X,B,mean)
      averages[i, 2] <- mean(X)

      Y <- resultsLambda(dt, sMask & yMask)
      cat(" & ")
      printAverage(Y)
      cat(" & ")
      printDiff(Y,B,mean)
      averages[i, 3] <- mean(Y)

      A <- printComparisonAndGetA12(X, Y)
      averages[i, 4] <- A

      cat(" \\\\ \n")
    }

    cat("\\midrule \n")
    cat("Mean ")
    printSummaryComparison(averages, mean)
    cat(" \\\\ \n")

    cat("Median ")
    printSummaryComparison(averages, median)
    cat(" \\\\ \n")

    cat("\\bottomrule \n")
    cat("\\end{tabular} \n")

  }, finally = {
    sink()
  })
}



################################################################
toolLabel <- function(id, format){
    verifyFormat(format)
    if(format == TEX){
      return(paste0("\\",id))
    }
    if(format == MD){
      return(paste0("__",id,"__"))
    }
}

toolsSortedWithFixedFirst <- function(dt, first){
  unsortedTools <- unique(dt$TOOL)
  if ( !(first %in% unsortedTools)){
    stop(paste0("Not recognized tool: ",first))
  }
  tools <- c(first, sort(setdiff(unsortedTools, first)))
  return(tools)
}

################################################################
tableManyConfigs <- function(
  dt, # the data frame, containing all experiment data.
  resultsLambda, # a lambda(dt,mask) returning an array/list of result values.
           # could be a column of dt, eg, dt$someResults[mask], or a transformation
           # involving more than 1 column, eg, cov/tot.
  tableFileName,  # output file name, WITHOUT file ending format
  format = TEX, # output format. must be either "tex" (Latex) or "md" (Markdown).
  suts = NULL, #  list of SUT names, to include in the table (in case we want to skip some). if NULL, take all
  tools = NULL # list of tool names to include. if NULL, take all
) {

  verifyDataFrame(dt)

  verifyFormat(format)

  allSuts <-  sort(unique(dt$SUT))
  if(is.null(suts)){
    suts <- allSuts
  } else {
    errors <- setdiff(suts, allSuts)
    if(length(errors) > 0){
      stop("Unrecognized SUT names: ", toString(errors))
    }
  }

  allTools <- sort(unique(dt$TOOL))
  if(is.null(tools)){
    tools <- allTools
  } else {
    errors <- setdiff(tools, allTools)
    if(length(errors) > 0){
      stop("Unrecognized TOOL names: ", toString(errors))
    }
  }

  TABLE <- paste0(GENERATED_FILES, "/", tableFileName, ".", format)
  unlink(TABLE)
  sink(TABLE, append = TRUE, split = TRUE)

  tryCatch({

    if(format == TEX){
      cat("\\begin{tabular}{ l ",paste(rep("r ", length(tools)),collapse = '' ), "  }\\\\ \n")
      cat("\\toprule \n")
      z <- function(x){return(paste(" & ", toolLabel(tools[x],format)))}
      cat("SUT ", paste(lapply(1:length(tools), z), collapse = '')," \\\\ \n", sep = "")
      cat("\\midrule \n")

    } else if(format == MD){
      z <- function(x){return(paste(" | ", toolLabel(tools[x],format)))}
      cat("| __SUT__ ", paste0(lapply(1:length(tools), z), collapse = '')," | \n")
      cat("| :--- ", paste(rep("|---:", length(tools)), collapse = ""), " | \n")
    }

    avgs <- matrix(nrow = length(suts), ncol = length(tools))
    ranks <- matrix(nrow = length(suts), ncol = length(tools))


    for (j in 1:length(suts)) {
        sut <- suts[[j]]

        if(format == TEX) cat("\\emph{", sut, "}", sep = "")
        if(format == MD)  cat("|_", sut, "_", sep = "")

        data <- vector(mode="list", length=length(tools))

        for (i in 1:length(tools)){
            t <- tools[i]
            cov <- resultsLambda(dt, dt$SUT==sut & dt$TOOL==t)
            data[[i]] <- cov
            avgs[j,i] <- mean(cov)
        }

        ranks[j,] <- rank(-avgs[j,])

        for (i in 1:length(tools)){
            cov <- data[[i]]
            a <- mean(cov)

            if(format == TEX) cat(" & ")
            if(format == MD)  cat(" | ")

            if (a == max(avgs[j,])){
              if(format == TEX) cat("{\\bf ")
              if(format == MD)  cat("__")
            }

            cat(formatC(a, digits = 1, format = "f"))
            ### [min,max] might be too much
            #       cat(" [",formatC(min(cov), digits = 1, format = "f"), sep = "")
            #       cat(",", formatC(max(cov), digits = 1, format = "f"), sep = "")
            #       cat("]")
            r <- ranks[j,i]
            cat(" (",formatC(r, digits = 1, format = "f"),")",sep="")

            if (a == max(avgs[j,])){
              if(format == TEX) cat("}")
              if(format == MD)  cat("__")
            }
        }
        if(format == TEX) cat(" \\\\ \n ")
        if(format == MD)  cat(" | \n")
    }

    if(format == TEX) cat("\\midrule \n")

    printSummaryComparison <- function(lambda, tools, avgs, ranks, format){
      for (i in 1:length(tools)){
        if(format == TEX) cat(" & ")
        if(format == MD)  cat(" | ")

        cat(formatC(lambda(avgs[,i]), digits = 1, format = "f"))
        cat(" (",formatC(lambda(ranks[,i]), digits = 1, format = "f"),")",sep="")
      }
    }

    if(format == TEX) cat("Average ")
    if(format == MD)  cat("|__AVERAGE__ ")
    printSummaryComparison(mean,tools,avgs,ranks,format)
    if(format == TEX) cat(" \\\\ \n ")
    if(format == MD)  cat(" | \n")

    if(format == TEX) cat("Median ")
    if(format == MD)  cat("|__MEDIAN__ ")
    printSummaryComparison(median,tools,avgs,ranks,format)
    if(format == TEX) cat(" \\\\ \n ")
    if(format == MD)  cat(" | \n")

    if(format == TEX){
      fr <- friedman.test(ranks)
      csr <- formatC(fr$statistic, digits = 3, format = 'f')
      p <- fr$p.value
      if (is.nan(p)) {
            p <- "1.000"
      } else if (p < 0.001) {
            p <- "$< 0.001$"
      } else {
            p <- formatC(p, digits = 3, format = "f")
      }

      fresult <- paste0("$\\chi^2$ = ", csr, ", $p$-value = ", p)
      cat("\\midrule \n")
      cat("Friedman Test & \\multicolumn{",length(tools),"}{r}{",fresult," }", sep = "")
      cat(" \\\\ \n")
      cat("\\bottomrule \n")
      cat("\\end{tabular} \n")
    }
  }, finally = {
      sink()
  })
}


#############################################################################
# This table is needed when we have many compared TOOLs, and showing results
# SUT by SUT would take too much space.
# Instead, each row is per TOOL, with average results over all SUTs.
# But, as now we have more space for columns, we can consider more than 1 metric.
# We use 3: X, Y and Z. These are specified via lambdas.
# A fourth column is then used to show average ranks over these 3 metrics.
# Best results (ie lowest ranks) are highlighted.
tableToolSummary <- function(
  toolLabel, # the label used for the TOOL column
  xDt, # the data frame for X, containing all experiment data.
  xName, # the label used for the X data column
  xLambda, # a lambda(dt,mask) returning an array/list of result values for X.
  yDt, # the data frame for Y, containing all experiment data.
  yName, # the label used for the Y data column
  yLambda, # a lambda(dt,mask) returning an array/list of result values for Y.
  zDt, # the data frame for Z, containing all experiment data.
  zName, # the label used for the Z data column
  zLambda, # a lambda(dt,mask) returning an array/list of result values for Z.
  tableFileName,  # output file name, without file ending type
  format # either "tex" or "md"
) {

  verifyDataFrame(xDt)
  verifyDataFrame(yDt)
  verifyDataFrame(zDt)

  suts <-  sort(unique(xDt$SUT))
  tools <- sort(unique(xDt$TOOL))

  TABLE <- paste0(GENERATED_FILES, "/", tableFileName, ".", format)
  unlink(TABLE)
  sink(TABLE, append = TRUE, split = TRUE)



  tryCatch({
    if(format == TEX){
      cat("\\begin{tabular}{ l rrrrr", "  }\\\\ \n")
      cat("\\toprule \n")
      cat(toolLabel," & ", xName," & ", yName," & ", zName," & Best-On & Overall \\\\ \n", sep = "")
    }
    if(format == MD){
      cat("|", toolLabel," | ", xName," | ", yName," | ", zName," | Best-On | Overall | \n", sep = "")
      cat("|:---|---:|---:|---:|---:|---:| \n")
    }

    avgsX <- matrix(nrow = length(suts), ncol = length(tools))
    ranksX <- matrix(nrow = length(suts), ncol = length(tools))
    avgsY <- matrix(nrow = length(suts), ncol = length(tools))
    ranksY <- matrix(nrow = length(suts), ncol = length(tools))
    avgsZ <- matrix(nrow = length(suts), ncol = length(tools))
    ranksZ <- matrix(nrow = length(suts), ncol = length(tools))

    toolBest <- rep(0, length(tools))

    if(format == TEX){
      cat("\\midrule \n")
    }

    for (j in 1:length(suts)) {
      sut <- suts[[j]]

      for (i in 1:length(tools)){
        t <- tools[i]
        mask <- xDt$SUT==sut & xDt$TOOL==t
        avgsX[j,i] <- mean(xLambda(xDt, mask))

        mask <- yDt$SUT==sut & yDt$TOOL==t
        avgsY[j,i] <- mean(yLambda(yDt, mask))

        mask <- zDt$SUT==sut & zDt$TOOL==t
        avgsZ[j,i] <- mean(zLambda(zDt, mask))
      }

      ranksX[j,] <- rank(-avgsX[j,])
      ranksY[j,] <- rank(-avgsY[j,])
      ranksZ[j,] <- rank(-avgsZ[j,])

      bestX <- max(avgsX[j,])
      bestY <- max(avgsY[j,])
      bestZ <- max(avgsZ[j,])

      if(sum(avgsX[j,] == bestX) == 1)  toolBest[which(avgsX[j,] == bestX)] <- toolBest[which(avgsX[j,] == bestX)] + 1
      if(sum(avgsY[j,] == bestY) == 1)  toolBest[which(avgsY[j,] == bestY)] <- toolBest[which(avgsY[j,] == bestY)] + 1
      if(sum(avgsZ[j,] == bestZ) == 1)  toolBest[which(avgsZ[j,] == bestZ)] <- toolBest[which(avgsZ[j,] == bestZ)] + 1
    }

    ranksK <- rank(-toolBest)

    bestRX <- min(colMeans(ranksX))
    bestRY <- min(colMeans(ranksY))
    bestRZ <- min(colMeans(ranksZ))
    bestRK <- min(ranksK)

    overall <- (colMeans(ranksX) + colMeans(ranksY) + colMeans(ranksZ) + ranksK) / 4
    bestOverall <- min(overall)

    for (i in 1:length(tools)){
      if(format == TEX) cat("\\emph{", tools[i], "}", sep = "")
      if(format == MD)  cat("|_", tools[i], "_", sep = "")

      x <- mean(avgsX[,i])
      y <- mean(avgsY[,i])
      z <- mean(avgsZ[,i])
      k <- toolBest[i]
      rX <- mean(ranksX[,i])
      rY <- mean(ranksY[,i])
      rZ <- mean(ranksZ[,i])
      rK <- ranksK[i]

      if(format == TEX) mark <- "\\cellcolor{gray!30} "
      if(format == MD)  mark <- "__"

      if(format == TEX) cat(" & ")
      if(format == MD) cat(" | ")
      if(rX == bestRX){
        cat(mark)
      }
      cat(formatC(x, digits = 1, format = "f"))
      cat(" (",formatC(rX, digits = 1, format = "f"),")",sep="")
      if(rX == bestRX){
        if(format == MD) cat(mark)
      }


      if(format == TEX) cat(" & ")
      if(format == MD) cat(" | ")
      if(rY == bestRY){
        cat(mark)
      }
      cat(formatC(y, digits = 1, format = "f"))
      cat(" (",formatC(rY, digits = 1, format = "f"),")",sep="")
      if(rY == bestRY){
        if(format == MD) cat(mark)
      }

      if(format == TEX) cat(" & ")
      if(format == MD) cat(" | ")
      if(rZ == bestRZ){
        cat(mark)
      }
      cat(formatC(z, digits = 1, format = "f"))
      cat(" (",formatC(rZ, digits = 1, format = "f"),")",sep="")
      if(rZ == bestRZ){
        if(format == MD) cat(mark)
      }

      if(format == TEX) cat(" & ")
      if(format == MD) cat(" | ")
      if(rK == bestRK){
        cat(mark)
      }
      cat(formatC(k, digits = 0, format = "f"))
      cat(" (",formatC(rK, digits = 0, format = "f"),")",sep="")
      if(rK == bestRK){
        if(format == MD) cat(mark)
      }

      best <- overall[i]

      if(format == TEX) cat(" & ")
      if(format == MD) cat(" | ")
      if(best == bestOverall){
        cat(mark)
      }
      cat(formatC(best, digits = 1, format = "f"))
      if(best == bestOverall){
        if(format == MD) cat(mark)
      }

      if(format == TEX) cat(" \\\\ \n")
      if(format == MD)  cat(" | \n")
    }

    if(format == TEX){
      cat("\\bottomrule \n")
      cat("\\end{tabular} \n")
    }

  }, finally = {
    sink()
  })

}