cmdArgs <- commandArgs(trailingOnly = TRUE)

library(devtools)

load_all("./mocapProcessor")

mainFunc(cmdArgs)
