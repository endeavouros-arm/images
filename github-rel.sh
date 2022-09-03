#!/bin/bash

_help() {
   # Display Help
   printf "\nHELP\n"
   printf "Release Create Enos image to GitHub\n"
   printf "Using GitHub CLI tool\n\n"
   printf "options:\n"
   printf "Either two options -p -m are required\n"
   printf "Or the single option -h\n\n"
   printf " -p  enter platform, requires rpi or odn or pbp\n"
   printf " -m  enter create release or upload release, requires cre or upl\n"
   printf " -h  Print this Help.\n\n"
   printf "example:  github-rel -p rpi -m cre\n\n"
}

#################################################
##           start of script                   ##
#################################################

PLATFORM=""
PLATI=""
MODE=""

PLAT3=false
MODE3=false

# Available options
opt=":p:m:b:h"

if [[ ! $@ =~ ^\-.+ ]]
then
    echo "The script requires an argument, aborting"
    _help
    exit 1
fi

while getopts "${opt}" arg; do
  case $arg in
    p)
      PLAT="${OPTARG}"
      ;;
    m)
      MODE="${OPTARG}"
      ;;
    \?)
      echo "Option -${OPTARG} is not valid, aborting"
      exit 1
      ;;
    h|?)
      _help
      exit 1
      ;;
    :)
      echo "Option -${OPTARG} requires an argument, aborting"
      exit 1
      ;;
  esac
done

case $PLAT in
    rpi) PLAT1="rpi"
         PLAT2="rpi-aarch64";;
    odn) PLAT1="odroid-n2"
         PLAT2="odroid-n2";;
    pbp) PLAT1="pbp"
         PLAT2="pbp";;
    *)   PLAT3=true;;
esac

case $MODE in
    cre) MODE1="create";;
    upl) MODE1="upload";;
    *)   MODE3=true;;
esac

if $PLAT3 || $MODE3 ; then
    printf "\nOne or more options were invalid\n"
    _help
    exit
fi

printf "\nPLATFORM = $PLAT1"
printf "\nMODE = $MODE1\n"

DATE=$(date '+%Y%m%d')

if [ "$MODE1" == "create" ]; then
    gh release create image-$PLAT1-$DATE enosLinuxARM-$PLAT2-latest.tar.zst* -t image-$PLAT1-$DATE -F release-note-$PLAT1.md -d
    gh release edit image-$PLAT1-$DATE --draft=false
fi

if [ "$MODE" == "upload" ]; then
    gh release upload image-$PLAT1-$DATE enosLinuxARM-$PLAT2-latest.tar.zst* --clobber
fi
