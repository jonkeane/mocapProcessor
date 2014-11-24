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
  meanY <- paste('{"name": "meanY", "column": ',which( colnames(markerData)=="mean-Y-0-1-2-3-4" )-1,', "min":',min(markerData$`mean-Y-0-1-2-3-4`, na.rm=TRUE),', "max":',max(markerData$`mean-Y-0-1-2-3-4`, na.rm=TRUE),'}', sep='')
  tracks <- paste('"tracks" : [',grip,',',clapper,',',meanY,']')

  # check the times of the mocap data and the video data
  mocapDur <- max(markerData$times)
  videoDur <- videoLength(shQuote(videoFile))
  if(!is.na(videoDur)){
    fuzz <- 0.5
    if(mocapDur > videoDur+fuzz){
      warning(paste("The motion capture data (",as.character(mocapDur)," seconds) is longer than the video data (",as.character(videoDur)," seconds). This is a sign that there is a problem with alignment.", sep = ""))
    } 
    if(mocapDur+fuzz < videoDur){
      warning(paste("The video data (",as.character(videoDur)," seconds) is longer than the motion capture data (",as.character(mocapDur)," seconds). This is a sign that there is a problem with alignment.", sep = ""))
    }
  } else {
    warning("The video data duration could not be found. The motion capture and video durations were not checked against each other.")
  }


  pathToElanGen <- system.file("pyelan/elanGen.py", package = "mocapProcessor", mustWork=TRUE)

  call <- paste("python ",pathToElanGen," \"",videoFile,"\" \"",elanDir,"\" \'[{\"file\" : \"",paste(csvDir, "/", paste(df$subj, df$session, df$trial,sep="-"),".csv", sep=""),"\", ",tracks,"}]\'", sep="")
  
  options(warn = oldWarn)
  system(call)
  call
}

