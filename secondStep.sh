#!bin/bash


#getSizeModule() {
#local mName=$MODULENAME
#char="/"
#result=$(awk -F"${char}" '{print NF-1}' <<< "${mName}")
#echo "Result è: " $result
#for (( ind=0; ind<=$result; ind++ ))
#do
#cd ..
#echo "Il link della repo è:" $LINKREPO
#done
#echo $PWD
#}

#getNameRepo () {
#  local link=$LINKREPO
#      IFS='/' # hyphen (-) is set as delimiter
#    read -ra ADDR <<< "$link" # str is read into an array as tokens separated by IFS
#    sizeArray=${#ADDR[@]} 
#    nameRepo=${ADDR[sizeArray-1]}
#    echo "$nameRepo"
#    
#}

checkRepo(){
    local nameRepo=$NAMEREPO
    local linkRepo=$LINKREPO
    local shaCommit=$SHACOMMIT
    local baseDir=$BASEDIR
    local repoFolder=$REPOFOLDER
    cd $baseDir
    cd $repoFolder
    cd $nameRepo

    actualSha=$(git rev-parse HEAD)
      echo "actual sha:" $actualSha
      echo "SHA COMMIT:" $shaCommit
       if echo "$actualSha" | grep -q "$shaCommit"; then # lo sha è lo stesso di quello actual
            echo "project "$nameRepo" already exsist with sha: "$shaCommit
            cd $baseDir
            echo $PWD
            toReturn=0
        else 
            echo "cd "$nameRepo
            echo "nameRepo"$nameRepo
            echo "git checkout " $shaCommit
            git checkout $shaCommit
            toReturn=1
            
        fi
}

mvnStep(){
    local baseDir=$BASEDIR
    TOSEARCH="BUILD FAILURE"
    OUTPUTBUILD=""
    echo "_____________RUN mvn install -DskipTests________________"
    message=$(mvn install -DskipTests -fn -B)
    if echo "$message" | grep -q "$TOSEARCH"; then 
        OUTPUTBUILD="BUILD FAILED"
    else
        OUTPUTBUILD="BUILD PASS"
    fi
    echo "_____________END mvn install -DskipTests________________"
    cd $baseDir
    echo  "$OUTPUTBUILD"
}

searchFlaky(){
echo "--------------------------------------------SEARCH FLAKY----------------------------------"
local concatName=$CLASSNAME"#"$METHODNAME
local nrounds=$NUMBERSROUNDS
local nameRepo=$NAMEREPO
local moduleName=$MODULENAME
local baseDir=$BASEDIR
local RepoFolder=$REPOFOLDER
local csvOutput=$CSVOUTPUT
local resultTest=""
local shaCommit=$SHACOMMIT
local linkRepo=$LINKREPO
local outputLog=$OUTPUTLOG
local stateLog=$STATELOG
PASSTEST=0
FAILTEST=0
TOSEARCH="BUILD SUCCESS"
i=0
for i in $( seq 1 $nrounds )
do
    cd $baseDir
    cd $RepoFolder
    cd $nameRepo
    cd $moduleName
    timestampInitial=$(date +%s)
    timestampInitialDate=$(date -d @$timestampInitial)
    echo "exec command: mvn -Dtest="$concatName" test" $i
    stateMachineInitial=$(vmstat -t)
    dirLog="$baseDir""$outputLog""$CLASSNAME"_"$METHODNAME""_""$SHACOMMIT"".txt"
    message=$(mvn -Dtest=$concatName test | tee $dirLog)
    stateMachineFinal=$(vmstat -t)
    echo "$stateMachineInitial", "$stateMachineFinal" >> "$baseDir""$stateLog""$CLASSNAME""_""$METHODNAME""_""$SHACOMMIT"".txt"
    timestampFinal=$(date +%s)
    timestampFinalDate=$(date -d @$timestampFinal)
    if echo "$message" | grep -q "$TOSEARCH"; then
        echo "test pass";
        resultTest="test pass"
        PASSTEST=$((PASSTEST+1))
    else 
        resultTest="test fail"
        echo "test fail" 
        FAILTEST=$((FAILTEST+1))
    fi
    echo "$nameRepo","$linkRepo", "$shaCommit","$moduleName", "$CLASSNAME","$METHODNAME","$resultTest", $timestampInitialDate,$timestampFinalDate >> "$baseDir""$csvOutput""$CLASSNAME""_""$METHODNAME""_""$SHACOMMIT"".csv"
done
echo "number of pass: "$PASSTEST
echo "number of failure: "$FAILTEST
if [ $PASSTEST -gt 0 -a $FAILTEST -gt 0 ]; then 
    echo "test flaky"
    echo "numbers of runs:"$i
else 
    echo "test isn't flaky"
fi
}


CSVINPUTFIRSTSTEP=$1
CSVOUTPUT=$2
BASEDIR=$3
REPOFOLDER=$4
NITER=$5
NUMBERSROUNDS=$6
CSVOUTPUTFINAL=$7
OUTPUTLOG=$8
STATELOG=$9

 while IFS= read -r line
    do
        IFS=',' read -r -a array <<< "$line"
        NAMEREPO=${array[0]}
        LINKREPO=${array[1]}
        SHACOMMIT=${array[2]}
        MODULENAME=${array[3]}
        CLASSNAME=${array[4]}
        METHODNAME=${array[5]}
        checkRepo "$NAMEREPO" "$LINKREPO" "$SHACOMMIT" "$BASEDIR" "$REPOFOLDER"
        echo $toReturn
        if [ $toReturn -eq 1 ]; then
            mvnStep $BASEDIR
        fi
        searchFlaky $NAMEREPO $CLASSNAME $METHODNAME $NUMBERSROUNDS $BASEDIR $REPOFOLDER $CSVOUTPUT $SHACOMMIT $LINKREPO $OUTPUTLOG $STATELOG
        cd $BASEDIR
        echo $LINKREPO,$SHACOMMIT,$MODULENAME,$CLASSNAME,$METHODNAME,$NUMBERSROUNDS,$PASSTEST,$FAILTEST >> "$CSVOUTPUTFINAL"".csv" 
    done < "$CSVINPUTFIRSTSTEP"
