############### from dataProcessor.R


main <- function(videoFile){
  # runs through the video files, find csvs in the GRIP folder, generate csvs, generate elan files
  # Change the warn option so that warnings are displayd along with progress. There should be a better way to do this...
  oldWarn <- getOption("warn")
  options(warn = 1)
  
  base <- strsplit(tail(strsplit(videoFile, "/", fixed=TRUE)[[1]], 1), ".", fixed=TRUE)[[1]][1]
  df <- data.frame(Experiment="GRIP", 
  subj = strsplit(base, "-", fixed=TRUE)[[1]][1],
  session = strsplit(base, "-", fixed=TRUE)[[1]][2],
  trial = strsplit(base, "-", fixed=TRUE)[[1]][3])
  df$pathMarkers <- paste("./mocapData/",df$Experiment, df$subj, df$session, df$trial,"Filtered Markers","Filtered Markers.txt",sep="/")

#   csvDir <- paste(dirPath,"mocapCSVs",unique(df$subj),sep="/")
  csvDir <- paste("mocapCSVs",unique(df$subj),sep="/")
  
  dir.create(csvDir, recursive=TRUE, showWarnings=FALSE)

#   elanDir <- paste(dirPath,"elanFilesOut",unique(df$subj),sep="/")
  elanDir <- paste("elanFilesOut",unique(df$subj),sep="/")
  dir.create(elanDir, recursive=TRUE, showWarnings=FALSE)
  
  markerData <- clipWriter(data=df, subjDir=csvDir)
  # "tracks" : [{"name": "clapper", "column": 36, "min":0, "max":200}]
   grip <- paste('{"name": "grip", "column": ',which( colnames(markerData)=="0-1" )-1,', "min":',min(markerData$`0-1`, na.rm=TRUE),', "max":',max(markerData$`0-1`, na.rm=TRUE),'}', sep='')
  clapper <- paste('{"name": "clapper", "column": ',which( colnames(markerData)=="clapperState" )-1,', "min":',min(markerData$clapperState, na.rm=TRUE),', "max":',max(markerData$clapperState, na.rm=TRUE),'}', sep='')  
  tracks <- paste('"tracks" : [',grip,',',clapper,']')
  
  pathToElanGen <- system.file("exec/pyelan/elanGen.py", package = "mocapProcessor", mustWork=TRUE)

  call <- paste("python ",pathToElanGen," \"",videoFile,"\" \"",elanDir,"\" \'[{\"file\" : \"",paste(csvDir, "/", paste(df$subj, df$session, df$trial,sep="-"),".csv", sep=""),"\", ",tracks,"}]\'", sep="")
  
  options(warn = oldWarn)
  system(call)
  call
}

