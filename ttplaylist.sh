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

# echo  mp3Path = $mp3Path, productId = $productId, name=$name

locationOfScript=$(dirname "$(readlink -e "$0")")

# create directory ogg if not exists
rm -r -f "./tempMedia/"
mkdir -p "./tempMedia"

for file in "$mp3Path"/*.mp3; do 
	echo "create ogg from file $file"
	fname=$(basename "$file")
	fdir=$(dirname "$file")
	sox "$file" -r 22050 -c 1 "./tempMedia/${fname%.mp3}.ogg" gain -1;
done


# remove invalid chars like space
rename "s/ //g" ./tempMedia/*.ogg
rename "s/-/_/g" ./tempMedia/*.ogg
rename "s/[^\w\.\/]/_/g" ./tempMedia/*.ogg


# read -p "product-id:" productid
productid=$productId

# create a variable to represent the filename
fileYaml="$name.yaml"

echo "create $fileYaml"

# write to the file
echo "product-id: $productid" > $fileYaml
echo "media-path: tempMedia/%s" >> $fileYaml
echo "welcome: hello" >> $fileYaml
echo "scripts:" >> $fileYaml

oIdCode=9000
counter=0

echo "  8000:" >> $fileYaml
echo "    - \$nextSong==0? \$nextSong:=1 J(9000)" >> $fileYaml

echo "  8001:" >> $fileYaml
echo "    - \$nextSong:=0" >> $fileYaml

echo "  8002:" >> $fileYaml
echo "    - \$nextSong:=0" >> $fileYaml

echo "  8003:" >> $fileYaml
echo "    - \$nextSong:=0" >> $fileYaml


for file in ./tempMedia/*.ogg; do 
  fname=$(basename "$file")
  echo "  $oIdCode:" >> $fileYaml
  echo "    - \$nextSong==1? P(${fname%.ogg}) J($(($oIdCode+1)))" >> $fileYaml
  echo "    - P(${fname%.ogg})" >> $fileYaml

  ((oIdCode++))
done

for (( missingOIDCode=$oIdCode; missingOIDCode<=9066; missingOIDCode++)) 
do
  echo "  $missingOIDCode:" >> $fileYaml
  echo "    - \$nextSong:=0" >> $fileYaml
done


# copy global media files
cp "$locationOfScript"/globalMedia/* ./tempMedia

echo "create $name.gme"
$tttoolsPath/tttool assemble $name.yaml 

echo "create $name.pdf"
$tttoolsPath/tttool oid-table $name.yaml

echo "create $productId.png"
$tttoolsPath/tttool oid-code $productId



echo "playlist creation finished"
