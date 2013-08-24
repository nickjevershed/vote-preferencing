# Run this within R with:
# source("mds.R")

library("maptools")

graph <- function(fit, d2, state) {
  x <- fit$points[,1]
  y <- fit$points[,2]
  plot(x, y, col="red", main=state, xlab="", ylab="", xaxt='n', yaxt='n', frame.plot=FALSE)
  pointLabel(x, y, labels = row.names(d2), cex=1, xpd=TRUE)
}

process <- function(state, label) {
  d = read.table(sprintf("output/distance_%s.dat", state), header=TRUE)
  # Make the matrix symmetric. Simplistic - puts equal weight on preferencing in both directions
  d2 = d + t(d)
  fit <- cmdscale(d2, eig=TRUE, k=2)
  svg(sprintf("output/%s.svg", state), width=7, height=7)
  graph(fit, d2, label)
  dev.off()
  write.csv(fit$points, sprintf("output/%s-coords.csv", state))  
}

process("act", "ACT")
process("nsw", "NSW")
process("nt", "NT")
process("qld", "QLD")
process("sa", "SA")
process("tas", "TAS")
process("vic", "VIC")
process("wa", "WA")

# Process the example data
d = read.table("example.dat", header=TRUE)
# Make the matrix symmetric. Simplistic - puts equal weight on preferencing in both directions
d2 = d + t(d)
svg("output/example.svg", width=7, height=7)
graph(cmdscale(d2, eig=TRUE, k=2), d2, "")
dev.off()
