# to install ElementTree:
# pip install --user ElementTree
# or #
# download elementtree and then:
# python setup.py install --user

mainFunc <- function(files, dirPath = "."){
  # dir.create(paste(dirPath,"savedData",sep="/"), recursive=TRUE, showWarnings=FALSE) # maybe not needed?
  
  lapply(files, main)
}




# python elanGen.py "./clippedData/GRI_006-SESSION_001-TRIAL_002.mov" "elanFiles" '[{"file" : "./savedData/GRI_006/GRI_006-SESSION_001-TRIAL_002.csv", "tracks" : [{"name": "clapper", "column": 36, "min":0, "max":200}, {"name": "grip", "column": 35, "min":0, "max":200}]}]'