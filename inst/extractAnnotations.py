import sys, os, re, warnings, csv, itertools
import pyelan.pyelan as pyelan

# changes the behavior of warnings so that they alert and do not print the code being warned about.
def custom_formatwarning(msg, *a):
    # ignore everything except the message
    return str(msg) + '\n'
warnings.formatwarning = custom_formatwarning

def actionCheck(trialType, condition):
    if trialType[0] != "ACTION":
        warnings.warn("The first trial type is not ACTION in "+str(condition)+". In the file "+eafFile)    
    actionPeriods = ['EYESCLOSED', 'OBSERVE', 'GRIP', 'MOVEMENT', 'RELEASE']
    actionPeriods = ['OBSERVE', 'GRIP', 'MOVEMENT', 'RELEASE']
    if [period for period in trialType[2]] != actionPeriods: 
        raise Exception("The periods for action do not contain "+str(actionPeriods)+" "+str(condition)+". In the file "+eafFile)
        
def gestureCheck(trialType, condition):
    if condition[2][0] != "GESTURE": 
        raise Exception("The second trial type is not GESTURE in "+str(condition)+". In the file "+eafFile)
    # setup two simple cases
    possGestPeriods = [
        ['EYESCLOSED', 'PLANNING', 'GRIP', 'MOVEMENT', 'RELEASE'],
        ['EYESCLOSED', 'NO GESTURE']
        ]
    if [period for period in condition[2][2]] not in possGestPeriods: 
        # if condition[2][2][0] == 'EYESCLOSED' and condition[2][2][1] == 'PLANNING':
        if condition[2][2][0] == 'PLANNING':
            # look at the post planning periods and see if they are in the right order, and containing the right periods should be changed to 2 when adding eyesclosed
            pers = ' '.join(condition[2][2][1:])
            if not re.match("(GRIP)? ?(MOVEMENT)? ?(RELEASE)?", pers):
                raise Exception("The periods for gesture are not correct "+str(condition)+". In the file "+eafFile)    
           
def estimationCheck(trialType, condition):
    if condition[3][0] != "ESTIMATION":
        raise Exception("The third trial type is not ESTIMATION in "+str(condition)+". In the file "+eafFile)
    possEstPeriods = [
        ['EYESCLOSED', 'OBSERVE', 'PREPARE', 'STEADY', 'TRANSITION', 'GRIP', 'MOVEMENT', 'RELEASE'],
        ['EYESCLOSED', 'OBSERVE', 'PREPARE', 'STEADY', 'TRANSITION-GRIP', 'MOVEMENT', 'RELEASE']
        ]
    possEstPeriods = [
        ['OBSERVE', 'PREPARE', 'STEADY', 'TRANSITION', 'GRIP', 'MOVEMENT', 'RELEASE'],
        ['OBSERVE', 'PREPARE', 'STEADY', 'TRANSITION-GRIP', 'MOVEMENT', 'RELEASE']
        ]
    if [period for period in condition[3][2]] not in possEstPeriods: 
        raise Exception("The periods for estimation are not correct "+str(condition)+". In the file "+eafFile)    

def actionCheck(trialType,condition):
    if trialType[0] != "ACTION":
        warnings.warn("The first trial type is not ACTION in "+str(condition)+". In the file "+eafFile)    
    actionPeriods = ['EYESCLOSED', 'OBSERVE', 'GRIP', 'MOVEMENT', 'RELEASE']
    actionPeriods = ['OBSERVE', 'GRIP', 'MOVEMENT', 'RELEASE']
    if [period for period in trialType[2]] != actionPeriods: 
        raise Exception("The periods for action do not contain "+str(actionPeriods)+" "+str(condition)+". In the file "+eafFile)

def annoChecker(annos, eafFile):
    annoVals = [x[0] for x in annos]
    
    # annotations must match this pattern
    pattern = re.compile('(\d) +(ACTION|GESTURE|ESTIMATION) *([R|L|x|X]?) +(OBSERVE|GRIP|MOVEMENT|RELEASE|PLANNING|PREPARE|STEADY|TRANSITION|UNCODABLE) *(CLOSED|OPEN|OPEN-CLOSED|CLOSED-OPEN)?')
    
    # setup a list of lists that has the structure of the experiment
    # annoStruct = [[condition, [type, side, [periods]]]]
    annoStruct = [[None, [None, None, [None]]]]
    
    # parse the annotations into the list of lists
    for val in annoVals:
        match = pattern.match(val)
        try:
            condition = match.group(1)
            typ = match.group(2)
            side = match.group(3) # does side need to be checked?
            period = match.group(4)
            gripType = match.group(5) # does gripType need to be checked? probably to make sure it coocurs with movement only
        except AttributeError:
            raise Exception("Could not parse the annotation values for the annotation: "+val+" In the file "+eafFile)
        
        if annoStruct[-1][0] == condition:
            if annoStruct[-1][-1][0] == typ and annoStruct[-1][-1][1] == side:
                annoStruct[-1][-1][2].append(period)
            else:
                annoStruct[-1].append([typ, side, [period]])
        else:
            annoStruct.append([condition, [typ, side, [period]]])
            
    # remove the first element
    if annoStruct[0] == [None, [None, None, [None]]]:
        annoStruct.pop(0)

    for condition in annoStruct:
        if  not re.match("[1234567]", condition[0]):
            raise Exception("The condition "+condition[0]+" in "+str(condition)+" does not match the possible condition list. In the file "+eafFile)
            
        # Check that the trial types are right and in the right order:
        trialTypes = ' '.join([tt[0] for tt in condition[1:]])
        matches = re.match("(ACTION)? ?(GESTURE)? ?(ESTIMATION)?", trialTypes)
        if not matches.group(1):
            warnings.warn("There is no ACTION trial type for condition"+str(typ)+" in file "+eafFile+" Condition: "+str(condition[0])+" Trial types found: "+str(trialTypes))
            
        if not matches.group(2):
            warnings.warn("There is no GESTURE trial type for condition"+str(typ)+" in file "+eafFile+" Condition: "+str(condition[0])+" Trial types found: "+str(trialTypes))
        
        if not matches.group(3):
            warnings.warn("There is no ESTIMATION trial type for condition"+str(typ)+" in file "+eafFile+" Condition: "+str(condition[0])+" Trial types found: "+str(trialTypes))
            
        for trialType in condition[1:]:
            if condition[0] == "ACTION":
                actionCheck(trialType = trialType, condition = condition)
            elif condition[0] == "GESTURE":
                gestureCheck(trialType = condition[2], condition = condition)
            elif condition[0] == "ESTIMATION":
                estimationCheck(trialType = condition[3], condition = condition)
            

        
    

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
        
    # check if the annotations are of the correct form 
    annoChecker(annos, eafFile)
            
    if len(annos) < 1:
        raise Exception("No annotations on overlaps tier found.")
        
    # relativize paths from the current to the csv
    currPath = os.path.abspath("./")    
    relPathCSV = os.path.relpath(ts.source, start = currPath)
    csvfile = open(relPathCSV, 'r')
    reader = csv.DictReader(csvfile)
    csvData = []
    if ts.timeOrigin:
        offset = ts.timeOrigin/1000.
    else:
        offset = 0
    for row in reader:
        csvData.append((float(row['times'])-offset, (row['0-1'], row['mean-Y-0-1-2-3-4'])))

        
        
    
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

    
            
