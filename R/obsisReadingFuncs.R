#################### functions ####################

pathsToDF <- function(input,pathToRemove) {
  # split the input vector into a data frame on /
  processed <- sub(paste(normalizePath(pathToRemove),"/",sep=""), "", input)
  out <- data.frame( do.call( rbind, strsplit( processed, '/' ) ) ) 
  # name the columns
  names(out) <- c("", "Experiment","subj","session","trial","folder","file")  
  # add the path back
  out$path <- input
  
  subset(out, select = c(Experiment,subj,session,trial,folder,file, path))
}

timecodeBegEnd <- function(trial) {
  start <- sub("LTC: ", "", as.character(head(trial[[2]], n=1)))
  end  <- sub("LTC: ", "", as.character(tail(trial[[2]], n=1)))
  out <- data.frame(timecodeStartObsis=start, timecodeEndObsis=end)
  out$timecodeStartObsis <- as.character(out$timecodeStartObsis)
  out$timecodeEndObsis <- as.character(out$timecodeEndObsis)
  return(out)
}

csvWithNames <- function(file){
  # read a csv and add a column for the filename
  out <- read.csv(file,sep="\t", header=TRUE)
  out$file <- file
  return(out)
}

#converts timecodes into seconds
timeToSecs <- function(time, fps = 30){
  hms<- substr(time,0,8)
  secs <- times(hms)
  out <- hours(secs)*60*60+minutes(secs)*60+seconds(secs) + (as.numeric(substr(time,10,12))+1)*(1/fps)
  return(out)
}


markerRead <- function(file,beginTime=0,endTime=600,verbose=FALSE) {
  if(verbose){
    print(file)
    print(beginTime)
    print(endTime)
  }
  file <- read.csv(file, sep="\t", na.strings = c("NA","NaN"))
  out <- subset(file, Time..sec. >=beginTime & Time..sec. <=endTime )
  return(out)
}

countOccluded <- function(data, verbose=FALSE){
  if(verbose){print(data[,c("subj","session","trial")])}
  data <- data[,"markerData"][[1]]
  dfOut <- data.frame(marker=character(0), numOccluded=integer(0), numTotal=integer(0))
  for(n in 0:23){ # 55 for all markers, 47 for all used markers, 24 for markers used in dynamic trials
    conds <- data[paste("cond",n,sep="")]
    dfOut <- rbind(dfOut, data.frame(marker = n, numOccluded = nrow(subset(conds, conds==-1)), numTotal = nrow(conds)))
  }
  dfOut
}


ffmpegDurParse <- function(ffmpegout){
  # extract the line with duration in it, and then turn extract the time
  durline <- ffmpegout[grepl(".*Duration: (.*), start.*", ffmpegout)]
  if(length(durline)>0){
    dur <- gsub(".*Duration: (.*), start.*","\\1", durline)
    # split on colons, delist
    dur <- as.numeric(strsplit(dur, ":")[[1]])
    # turn hours, min, sec.msec into seconds
    dur <- dur[1]*60*60+dur[2]*60+dur[3]
  } else {
    warning("ffmpeg couldn't find any lines with a duration.")
    dur <- NA
  }
  dur
}

videoLength <- function(file){
  call <- paste("ffprobe", file, "2>&1", sep=" ")
  length <- tryCatch({
    
    ffmpegout <- system(call, intern=TRUE)
    
    return(ffmpegDurParse(ffmpegout))
  }, error=function(cond) {
    message(paste(call, "does not seem to exist."))
    message("Here's the original error message:")
    message(cond)
    # Choose a return value in case of error
    return(NA)
  }, warning=function(cond) {
    message(paste(call, "had a warning."))
    message("Here's the original error message:")
    message(cond)
    return(NA)
#     # ffmpeg throws a warning when there is no output, maybe change the call to something else?
#     suppressWarnings({
#       ffmpegout <- system(call, intern=TRUE)
#     })
#     return(ffmpegDurParse(ffmpegout))
  })
}




