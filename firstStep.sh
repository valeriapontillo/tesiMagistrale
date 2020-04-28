#!bin/bash

checkout(){
    #entra nella repo
    local sha=$SHACOMMIT
    echo "lo sha è: $sha"
    git checkout $sha
}

cloneRepo(){
echo "clone  repo " $LINKREPO
local nameRepo=$NAMEREPO
local linkRepo=$LINKREPO
local shaCommit=$SHACOMMIT
local baseDir=$BASEDIR
local repoFolder=$REPOFOLDER
cd $baseDir
cd $repoFolder
message=$(git clone $linkRepo 2>&1)
TOSEARCH="fatal: destination path"
echo "message:" $message
echo "nameRepo: " $nameRepo
toReturn=0
cd $nameRepo
if echo "$message" | grep -q "$TOSEARCH"; then #la repo già esiste
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


CSVINPUTFIRSTSTEP=$1
REPOFOLDER=$2
BASEDIR=$3
CSVOUTPUTFIRSTSTEP=$4
 while IFS= read -r line
    do
        IFS=',' read -r -a array <<< "$line"
        NAMEREPO=${array[0]}
        LINKREPO=${array[1]}
        SHACOMMIT=${array[2]}
        MODULENAME=${array[3]}
        cloneRepo  "$NAMEREPO" "$LINKREPO" "$SHACOMMIT" "$BASEDIR" "$REPOFOLDER"
        echo $toReturn
        if [ $toReturn -eq 1 ]; then
            mvnStep $BASEDIR
            echo "$NAMEREPO","$LINKREPO","$SHACOMMIT","$OUTPUTBUILD" >> "$CSVOUTPUTFIRSTSTEP"
        fi

        
    done < "$CSVINPUTFIRSTSTEP"

