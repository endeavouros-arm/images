#!/bin/bash

_help() {
   # Display Help
   printf "\nHELP\n"
   printf "Release Create Enos image to GitHub\n"
   printf "Using GitHub CLI tool\n\n"
   printf "options:\n"
   printf "Either two options -p -m are required\n"
   printf "Or the single option -h\n\n"
   printf " -p  enter platform, requires rpi or odn\n"
   printf " -m  enter create release or upload release, requires cre or upl\n"
   printf " -h  Print this Help.\n\n"
   printf "example:  github-rel -p rpi -m cre\n\n"
}

#################################################
##           start of script                   ##
#################################################

PLATFORM=""
MODE=""

PLAT="false"
MOD="false"

if [ "$#" == "0" ] || [ "$1" == "-h" ]; then
    _help
    exit
fi

case $1 in
   -p)  if [ "$2" == "rpi" ] || [ "$2" == "odn" ]; then
           case $2 in
              rpi) PLATFORM="rpi" ;;
              odn) PLATFORM="odroid-n2" ;;
           esac
           PLAT="true"
         fi  ;;
   -m)  if [ "$2" == "cre" ] || [ "$2" == "upl" ]; then
           case $2 in
              cre) MODE="create" ;;
              upl) MODE="upload" ;;
           esac
           MOD="true"
        fi ;;
esac

case $3 in
   -p)  if [ "$4" == "rpi" ] || [ "$4" == "odn" ]; then
           case $4 in
              rpi) PLATFORM="rpi" ;;
              odn) PLATFORM="odroid-n2" ;;
           esac
           PLAT="true"
         fi ;;
   -m)  if [ "$4" == "cre" ] || [ "$4" == "upl" ]; then
           case $4 in
              cre) MODE="create" ;;
              upl) MODE="upload" ;;
           esac
           MOD="true"
        fi ;;
esac


if [ "$PLAT" == "false" ] || [ "$MOD" == "false" ] ; then
    printf "\nOne or more options were invalid\n"
    _help
    exit
fi

printf "\nPLATFORM = $PLATFORM"
printf "\nMODE = $MODE\n"

DATE=$(date '+%Y%m%d')

if [ "$MODE" == "create" ]; then
    gh release create image-$PLATFORM-$DATE enosLinuxARM-$PLATFORM-latest.tar.zst* -t image-$PLATFORM-$DATE -F release-note-$PLATFORM.md
    # echo $VAR
fi

if [ "$MODE" == "upload" ]; then
    gh release upload image-$PLATFORM-$DATE enosLinuxARM-$PLATFORM-latest.tar.zst* --clobber
    # echo $VAR
fi
