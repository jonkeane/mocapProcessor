# to install ElementTree:
# pip install --user ElementTree
# or #
# download elementtree and then:
# python setup.py install --user

cmdArgs <- commandArgs(trailingOnly = TRUE)

library(devtools)

load_all("./mocapProcessor")

mainFunc(cmdArgs) -> output

