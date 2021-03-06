
extractMarkers <- function(data, markers, verbose=FALSE){
  dataNew <- data
  dfOut <- data.frame(times = as.numeric(unlist(dataNew["Time..sec."]))-min(unlist(dataNew["Time..sec."])))
  for(marker in markers){
    if(verbose){
      print(data[,c("subj","session","trial")])
      print(marker)
    }
    markers <- dataNew[c(paste("X",marker[1],sep=""),paste("Y",marker[1],sep=""),paste("Z",marker[1],sep=""))]
    dfOut <- cbind(dfOut, markers)
  }
  dfOut
}

calculateDistances <- function(data, markers){
  # this could be changed to dplyr?
  dists <- c()
  for(m in 1:length(data$times)) {
    mOne <- c(data[m,paste("X", markers[1] ,sep="")], data[m,paste("Y", markers[1] ,sep="")], data[m,paste("Z", markers[1] ,sep="")])
    mTwo <- c(data[m,paste("X", markers[2] ,sep="")], data[m,paste("Y", markers[2] ,sep="")], data[m,paste("Z", markers[2] ,sep="")])
    dists <- append(dists, as.numeric(dist(rbind(mOne,mTwo))))
  }
  dfOut <- data
  label <- paste(markers, collapse="-")
  dfOut[,label] <- dists
  dfOut
}

meanOnAxis <- function(data, markers, axis){
  # this could be changed to dplyr?
  means <- c()
  for(m in 1:length(data$times)) {
    points <- c()
    for(marker in markers){
      points <- append(points, data[m,paste(axis, marker ,sep="")])
    }
    means <- append(means, as.numeric(mean(points, na.rm=TRUE)))
  }
  dfOut <- data
  label <- paste("mean",axis,paste(markers, collapse="-"), sep="-")
  dfOut[,label] <- means
  dfOut
}

# A gross alignment function that looks for and finds peaks that are over the threshold amplitude
alignGross <- function(distances, times, firstOpen=TRUE, openThreshold = 100){
  if(length(distances)!=length(times)){
    stop("Error, the distances and times are not of the same length.")
  }
  
  # check if there are any infinite states in the clapper state.
  if(any(is.infinite(distances))) {
    numInfss <- sum(is.infinite(distances))
    warning(paste("Warning, there are ",numInfss," infinities in the clapper state. If this number is sufficiently low, this might not be a problem.", sep = ""))
	distances <- ifelse(is.infinite(distances),NA,distances)
  }
    
  # check the number of transitions at the threshold, if over 2, error.
  clapperOpen <- ifelse(distances>openThreshold, 1, 0)
  if(any(is.na(clapperOpen))) {
    numNAs <- sum(is.na(clapperOpen))
    warning(paste("Warning, there are ",numNAs," NAs in the clapper state. If this number is sufficiently low, this might not be a problem.", sep = ""))
  }

  
  clapperOpen
}

# alignGross(filteredMarkers$clapperState , filteredMarkers$times)
# alignGross(filteredMarkers$clapperState , filteredMarkers$times, firstOpen=FALSE)

# a fine threshold finder that finds the frame that is the smallest of all the frames in a window before (direction="backword") or after (direction="forward") it.
minThresh <- function(distances, times, start, direction="backward", windowWidth=10, verbose=FALSE){
  if(length(distances)!=length(times)){
    stop("Error, the distances and times are not of the same length.")
  }
  if(direction=="backward"){
    distances <- rev(distances[times<=start])
    times <- rev(times[times<=start])
  } else if(direction=="forward"){
    distances <- distances[times>=start]
    times <- times[times>=start]
  }
  if(verbose){
    plot(distances, type="l")    
  }
  
  allInc <- FALSE
  n <- 1
  while(!allInc & n < length(distances)){
    dir <- c()
    for(nn in c(1:windowWidth)){
      dir[nn] <- ifelse(distances[n]>distances[n+nn], "lower", "higher")
    }
    if(all(dir=="higher", na.rm=TRUE)){
      allInc <- TRUE
    } else {
      n <- n+1
    }
  }
  if(!allInc){
    stop("Error, no minimum found, try adjusting the size of the window unit.")
  }
  if(verbose){
    points(x=n, distances[n])
  }
  times[n]
}

# minThresh(filteredMarkers$clapperState , filteredMarkers$times, 10.39167, verbose=TRUE)
# minThresh(filteredMarkers$clapperState , filteredMarkers$times, direction="forward", 574.7167, verbose=TRUE)


# minThresh(filteredMarkers$clapperState , filteredMarkers$times, alignGross(filteredMarkers$clapperState , filteredMarkers$times), verbose=TRUE)
# minThresh(filteredMarkers$clapperState , filteredMarkers$times, direction="forward", alignGross(filteredMarkers$clapperState , filteredMarkers$times, firstOpen=FALSE), verbose=TRUE)

# master align funciton that one frame offset: 1001/60000
align <- function(data, windowWidth=10, verbose=TRUE, offset=0){
  times <- data$times
  distances <- data$clapperState
  
  
  clapperStates <- alignGross(distances , times)

  
  clapperOpenTrans <- table(paste0(head(clapperStates,-1),tail(clapperStates,-1)))
  if(clapperOpenTrans["01"]+clapperOpenTrans["10"]<4) {
    warning("Warning, there are less than two open states on the clapper. Using the only state as the beginning of the clip.")
	nClapperStates <- 1
  } else if(clapperOpenTrans["01"]+clapperOpenTrans["10"]>4) {
  	nClapperStates <- (clapperOpenTrans["01"]+clapperOpenTrans["10"])/2
    warning(paste("Warning, there are ",nClapperStates," open states on the clapper. Using the first and the last states for clipping. Try adjusting the threshold up or down.", sep=""))
  } else {
	nClapperStates <- 2
  }
  
  minTime <- minThresh(distances , times, windowWidth=windowWidth, min(times[clapperStates==1 & !is.na(clapperStates)], na.rm = FALSE), verbose=TRUE)
  if(nClapperStates == 1) {
	maxTime <- max(times)
  } else {
	maxTime <- minThresh(distances, times, windowWidth=windowWidth, max(times[clapperStates==1 & !is.na(clapperStates)], na.rm = FALSE), direction="forward", verbose=verbose)
  }
  
  if(verbose){
    plot(data$times, data$clapperState, type="l")
    points(x=minTime, data$clapperState[data$times==minTime])
    points(x=maxTime, data$clapperState[data$times==maxTime])
  }
  out <- subset(data, times >= minTime+offset & times <=maxTime+offset)
  out$times <- out$times-min(out$times)
  out
}


# main clipping function.
clipper <- function(data, verbose=FALSE, parallel=TRUE){
  file <- data[["pathMarkers"]]
  
  filteredMarkerData <- markerRead(file = file, verbose=FALSE)
  
  filteredMarkers <- extractMarkers(filteredMarkerData, c(0,1,2,3,4,5,6,7,8,9,10,11,12)) 
  filteredMarkers <- calculateDistances(filteredMarkers, c(5,7))
  filteredMarkers <- calculateDistances(filteredMarkers, c(6,8))
  filteredMarkers <- calculateDistances(filteredMarkers, c(10,11))
  filteredMarkers <- calculateDistances(filteredMarkers, c(9,12))
  filteredMarkers <- calculateDistances(filteredMarkers, c(0,1))
  filteredMarkers <- meanOnAxis(filteredMarkers, c(0,1,2,3,4), axis="Y")
  
  # average the clapper marker distances
  filteredMarkers$clapperState <- apply(subset(filteredMarkers, select = c(`5-7`,`6-8`,`10-11`,`9-12`)), 1, mean, na.rm=T)
  # ggplot(filteredMarkers) + geom_line(aes(x=times, y=clapperState), alpha = 1)  + xlim(5,15)
  alignedMarkers <- align(filteredMarkers, offset=1001/60000)
  alignedMarkers
}

clipWriter <- function(data, subjDir) {
  exp <- data[["Experiment"]]
  subj <- data[["subj"]]
  session <- data[["session"]]
  trial <- data[["trial"]]
  message(paste("Starting on:",paste(exp,subj,session,trial,sep="-"),sep=" "))

  alignedMarkers <- clipper(data)
  outFilename <- paste(subjDir, "/", paste(subj, session, trial,sep="-"),".csv", sep="")
  write.csv(alignedMarkers, file = outFilename, row.names = FALSE)
  
#   message(paste("Wrote file: ",outFilename,sep=""))
  message(paste("Finished with:",paste(exp,subj,session,trial,sep="-"),sep=" "))
  if(exists("twtrNotify")){twtrNotify(paste(subj, session, trial,sep="-"))}
  
  alignedMarkers
}


mainFunc <- function(files, dirPath = "."){
  # dir.create(paste(dirPath,"savedData",sep="/"), recursive=TRUE, showWarnings=FALSE) # maybe not needed?
  
  lapply(files, main)
}