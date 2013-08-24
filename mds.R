# Run this within R with:
# source("mds.R")

graph <- function(fit) {
  x <- fit$points[,1]
  y <- fit$points[,2]
  plot(x, y, type="n")
  text(x, y, labels = row.names(d2), cex=.5)
}

d = read.table("distance_nsw.dat", header=TRUE)
# Make the matrix symmetric. Simplistic - puts equal weight on preferencing in both directions
d2 = d + t(d)
fit <- cmdscale(d2, eig=TRUE, k=2)
graph(fit)
svg("nsw.svg", width=7, height=7)
graph(fit)
dev.off()
write.csv(fit$points, 'nsw-coords.csv')
