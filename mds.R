# Run this within R with:
# source("mds.R")

library("maptools")

graph <- function(fit, d2, state) {
  x <- fit$points[,1]
  y <- fit$points[,2]
  plot(x, y, col="red", main=state, xlab="", ylab="", xaxt='n', yaxt='n', frame.plot=FALSE)
  pointLabel(x, y, labels = row.names(d2), cex=.75, xpd=FALSE)
}

process <- function(state) {
  d = read.table(sprintf("output/distance_%s.dat", state), header=TRUE)
  # Make the matrix symmetric. Simplistic - puts equal weight on preferencing in both directions
  d2 = d + t(d)
  fit <- cmdscale(d2, eig=TRUE, k=2)
  #graph(fit, d2, state)
  svg(sprintf("output/%s.svg", state), width=7, height=7)
  graph(fit, d2, state)
  dev.off()
  write.csv(fit$points, sprintf("output/%s-coords.csv", state))  
}

process("act")
process("nsw")
process("nt")
process("qld")
process("sa")
process("tas")
process("vic")
process("wa")
