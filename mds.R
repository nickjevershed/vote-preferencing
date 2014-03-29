# Run this within R with:
# source("mds.R")

library("maptools")
library("MASS")

# Graph and write to file as svg
graph <- function(fit, d2, label, filename) {
  svg(filename, width=7, height=7)
  x <- fit$points[,1]
  y <- fit$points[,2]
  plot(x, y, col="red", main=label, xlab="", ylab="", xaxt='n', yaxt='n', frame.plot=FALSE)
  pointLabel(x, y, labels = row.names(d2), cex=1, xpd=TRUE)
  dev.off()
}

calculate <- function(d) {
  # Make the matrix symmetric. Simplistic - puts equal weight on preferencing in both directions
  # Also make matrix from list
  return(isoMDS(do.call(rbind, d + t(d)), k=2))
}

process <- function(state, label) {
  d = read.table(sprintf("output/distance_%s.dat", state), header=TRUE)
  fit <- calculate(d)
  graph(fit, d, label, sprintf("output/%s.svg", state))
  write.csv(fit$points, sprintf("output/%s-coords.csv", state))  
}

# process("act", "ACT")
# process("nsw", "NSW")
# process("nt", "NT")
# process("qld", "QLD")
# process("sa", "SA")
# process("tas", "TAS")
# process("vic", "VIC")
process("wa", "WA")

# # Process the example data
# d = read.table("example.dat", header=TRUE)
# fit <- calculate(d)
# graph(fit, d, "", "output/example.svg")
# write.csv(fit$points, "output/example-coords.csv")
# # Recalculate distances
# d2 = dist(fit$points)
