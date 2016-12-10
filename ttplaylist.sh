#!/bin/bash

showHelp() {
  echo "Usage: ttplaylist -n name -m mp3Path -t tttoolsPath -i productId [-h]"
  echo "tttool mp3 playlist creater -v0.1"  
  echo ""
  echo "Available options:"
  echo " -m Get all mp3 files from this path"
  echo " -i Use this product id" 
  echo " -n Name of the created playlist"
  echo " -t Path of tttools"
  echo " -h Show this help text" 
}

error() {
  echo ${1}
  echo ""
  showHelp
  exit
}

while getopts ':m:t:i:n:h' OPTION ; do
  case "$OPTION" in
    m)   mp3Path=$OPTARG;;
    t)   tttoolsPath=$OPTARG;;
    i)   productId=$OPTARG;;
    n)   name=$OPTARG;;
    h)   showHelp;;
    :)   echo "Option -$OPTARG requires an argument." >&2 exit 1;;
    *)   echo "Unknown parameter $OPTARG";;
  esac
done

# check getopts arguments
if [[ -z "$mp3Path" ]] || [[ -z "$productId" ]] || [[ -z "$name" ]] || [[ -z "$tttoolsPath" ]];
  then
    error "Parameter missing"
fi

if ! [[ -d "$mp3Path" ]]; then
  error "Argument mp3Path need to be a valid path"
fi

if ! [[ -d "$tttoolsPath" ]]; then
  error "Argument tttoolsPath need to be a valid path"
fi

if ! [[ -x "$tttoolsPath/tttool" ]]; then
  error "There is no tttool in $tttoolsPath"
fi

if  ! [[ "$productId" =~ $re ]] || [[ "$productId" -lt 1 ]] || [[ "$productId" -gt 1000 ]];
 then
  error "Argument productId need to be a number bettween 1 and 1000"
fi

echo  mp3Path = $mp3Path, productId = $productId, name=$name

locationOfScript=$(dirname "$(readlink -e "$0")")
tempMedia="./Media_$name"

# for debugging only
rebuildTempMedia=true

if [[ $rebuildTempMedia == true ]]; then
	# create directory ogg if not exists
	rm -r -f "${tempMedia}/"
	mkdir -p "${tempMedia}"

	for file in "$mp3Path"/*.mp3; do 
		echo "create ogg from file $file"
		fname=$(basename "$file")
		fdir=$(dirname "$file")
		sox "$file" -r 22050 -c 1 "${tempMedia}/${fname%.mp3}.ogg" gain -1;
	done
fi

# remove spaces and replays invalid chars
curDir=$PWD
# echo "curDir $curDir"
cd "${tempMedia}/"
# echo "tempMedia $PWD"

rename "s/ //g" *.ogg
rename "s/[^\w\.\/]/_/g" *.ogg
rename "s/-/_/g" *.ogg


cd "${curDir}"


# read -p "product-id:" productid
productid=$productId

# create a variable to represent the filename
fileYaml="${name}.yaml"
oIdMin=9001
oIdMax=9065
oIdCode=$oIdMin

echo "create $fileYaml"

# write to the file
echo "product-id: $productid" >> "$fileYaml"
echo "media-path: ${tempMedia}/%s" >> "$fileYaml"
echo "language: de" >> "$fileYaml"
echo "welcome: hello" >> "$fileYaml"
echo "init: \$currentSong:=$oIdCode" >> "$fileYaml"

echo "scripts:" >> "$fileYaml"


echo "  8000:" >> "$fileYaml"
echo "    - \$info:=0 \$autoPlay:=1 J($oIdMin)" >> "$fileYaml"

echo "  8001:" >> "$fileYaml"
echo "    - \$info:=1 \$autoPlay:=0 P(info)" >> "$fileYaml"

echo "  8002:" >> "$fileYaml"
echo "    - \$currentSong>$oIdMin? \$currentSong-=1 J(\$currentSong)" >> "$fileYaml"
echo "    - P(nix)" >> "$fileYaml"

echo "  8003:" >> "$fileYaml"
echo "    - \$currentSong<$oIdMax? \$currentSong+=1 J(\$currentSong)" >> "$fileYaml"
echo "    - P(nix)" >> "$fileYaml"

for file in "${tempMedia}"/*.ogg; do 
  fname=$(basename "$file")
  echo "  $oIdCode:" >> "$fileYaml"
  echo "    - \$info==1? P($oIdCode)" >> "$fileYaml"
  echo "    - \$autoPlay==1? \$currentSong:=$oIdCode P(${fname%.ogg}) J($(($oIdCode+1)))" >> "$fileYaml"
  echo "    - \$currentSong:=$oIdCode P(${fname%.ogg})" >> "$fileYaml"

  ((oIdCode++))
done

for (( missingOIDCode=$oIdCode; missingOIDCode<=$oIdMax; missingOIDCode++)) 
do
  echo "  $missingOIDCode:" >> "$fileYaml"
  echo "    - \$autoPlay:=0 P(nix)"  >> "$fileYaml"
done

oIdCode=$oIdMin
echo "" >> "$fileYaml"
echo "speak:" >> "$fileYaml"
echo "  hello: \"${name}\"" >> "$fileYaml"
echo "  info: \"Info\"" >> "$fileYaml"
echo "  nix: \"Nix\"" >> "$fileYaml"
for file in "$mp3Path"/*.mp3; do 
  fname=$(basename "$file")
  echo "  $oIdCode: \"${fname%.mp3}\"" >> "$fileYaml"
  ((oIdCode++))
done

# copy global media files
# cp "$locationOfScript"/globalMedia/* "${tempMedia}

echo "create $name.gme"
$tttoolsPath/tttool assemble "$fileYaml"

#echo "create $name.pdf"
#$tttoolsPath/tttool oid-table "$fileYaml"

echo "create $productId.png"
$tttoolsPath/tttool oid-code $productId



echo "playlist creation finished"
