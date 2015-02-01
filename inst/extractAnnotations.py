import sys, os, re, warnings, csv, itertools
import pyelan.pyelan as pyelan

destDir = sys.argv[1]
# destDir = "../../extractedData"

eafFiles = sys.argv[2:]
# eafFiles = ['../../elanFiles/GRI_016/GRI_016-SESSION_001-TRIAL_006.eaf']
for eafFile in eafFiles:
    eafPath = os.path.dirname(eafFile)
    basename = os.path.splitext(os.path.basename(eafFile))[0]
    fl = pyelan.tierSet(file = eafFile)
    fl.fixLinks(searchDir = os.path.sep.join([destDir,".."]))

    # find time series files that are linked to the eaf.
    tsconfs = filter(lambda s: re.match(".*tsconf.xml", s), fl.linkedFiles)
    if len(tsconfs) > 1:
        warnings.warn("There's more than one tsconf file")
            
    for tsconf in tsconfs:
        # this should only be one file for this data
        ts = pyelan.timeSeries(file = tsconf)
        ts.fixLinks(searchDir = os.path.sep.join([destDir,".."]))
        
    # extract the annotations from the overlaps tear
    annos = []
    tier = [tier for tier in fl.tiers if tier.tierName == "OVERLAPS"]
    if len(tier) < 1:
        raise Exception("No overlaps tier found.")
    elif len(tier) > 1:
        raise Exception("More than one overlaps tier found.")
    tier = tier[0]
    
    for annotation in tier.annotations:
        annos.append((annotation.value, annotation.begin, annotation.end))
    
    if len(annos) < 1:
        raise Exception("No annotations on overlaps tier found.")
        
    # relativize paths from the current to the csv
    currPath = os.path.abspath("./")    
    relPathCSV = os.path.relpath(ts.source, start = currPath)
    csvfile = open(relPathCSV, 'r')
    reader = csv.DictReader(csvfile)
    csvData = []
    for row in reader:
        csvData.append((float(row['times']), (row['0-1'], row['mean-Y-0-1-2-3-4'])))
        
    
    colNames = [anno[0] for anno in annos]
    grip = []
    for name, minn, maxx, in annos:
        grip.append([x[1][0] for x in csvData if x[0] >= minn/1000. and x[0] <= maxx/1000.])
    
    # turn the list into rows, but add padding for mismatched lengths.
    gripRows = list(itertools.izip_longest(*grip))
        
    # create a subject directory if needed
    subj = basename.split("-")[0]
    if os.path.isdir(os.path.sep.join([destDir, subj])) == False :
        os.makedirs(os.path.sep.join([destDir, subj]))

    # write files
    csvfile = open(os.path.sep.join([destDir, subj,'.'.join([basename,"csv"])]), 'w')
    writer = csv.writer(csvfile)
    writer.writerow(colNames)
    for row in gripRows:
        writer.writerow(row)

    
            
