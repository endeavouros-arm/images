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

PLAT="false"
MOD="false"

if [ "$#" == "0" ] || [ "$1" == "-h" ]; then
    _help
    exit
fi

case $1 in
   -p)  if [ "$2" == "rpi" ] || [ "$2" == "odn" ] || [ "$2" == "pbp" ]; then
           case $2 in
              rpi) PLATFORM="rpi"
                   PLATI="rpi-aarch64" ;;
              odn) PLATFORM="odroid-n2"
                   PLATI="odroid-n2" ;;
              pbp) PLATFORM="pbp"
                   PLATI="pbp" ;;
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
   -p)  if [ "$2" == "rpi" ] || [ "$2" == "odn" ] || [ "$2" == "pbp" ]; then
           case $2 in
              rpi) PLATFORM="rpi"
                   PLATI="rpi-aarch64" ;;
              odn) PLATFORM="odroid-n2"
                   PLATI="odroid-n2" ;;
              pbp) PLATFORM="pbp"
                   PLATI="pbp" ;;
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
    gh release create image-$PLATFORM-$DATE enosLinuxARM-$PLATI-latest.tar.zst* -t image-$PLATFORM-$DATE -F release-note-$PLATFORM.md -d
    gh release edit image-$PLATFORM-$DATE --draft=false
    # echo $VAR
fi

if [ "$MODE" == "upload" ]; then
    gh release upload image-$PLATFORM-$DATE enosLinuxARM-$PLATI-latest.tar.zst* --clobber
    # echo $VAR
fi
