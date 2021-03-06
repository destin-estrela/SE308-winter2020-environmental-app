#!/bin/bash

debug=true
silent=false

THISPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
SETTINGS="${THISPATH}/settings.txt"

if [[ $# -gt 1 ]] ; then
   if [ "$2" == "-t" ] || [ "$2" == "-n" ] || [ "$2" == "-ns" ] ; then
      silent=true
      if [ "$2" == "-n" ] || [ "$2" == "-ns" ] ; then
         #SETTINGS="${THISPATH}/settings_npm.txt"
         SETTINGS="Backend/scripts/settings_npm.txt"
      fi
   fi
fi

ZIPFILE="$1"
DATADIR=$(grep -oP '(?<=^DATADIR:).*' $SETTINGS)
RAWDATADIR=$(grep -oP '(?<=^RAWDATADIR:).*' $SETTINGS)
FDADIR=$(grep -oP '(?<=^FDADIR:).*' $SETTINGS)
FDADATASOURCE=$(grep -oP '(?<=^FDADATASOURCE:).*' $SETTINGS)
FDAUPDATESOURCE=$(grep -oP '(?<=^FDAUPDATESOURCE:).*' $SETTINGS)
SERVER_POPULATED=$(grep -oP '(?<=^SERVER_POPULATED:).*' $SETTINGS)
DONE_UPLOADING=$(grep -oP '(?<=^SERVER_POPULATED:).*' $SETTINGS)
LASTLATEST=$(grep -oP '(?<=^LASTLATEST:).*' $SETTINGS)
RAWDATADEST="${RAWDATADIR}${FDADIR}"
DATADEST="${DATADIR}${FDADIR}"
IFS=',' read -r -a lastarray <<< "$LASTLATEST"
RAWDATAUPDATEDEST="${RAWDATADEST}${lastarray[1]}/"
DATAUPDATEDEST="${DATADEST}${lastarray[1]}/"
HELP="\tThis script distributes the contents of the provided FDA zipfile to\n"
HELP="${HELP}\tthe proper directories.  If there are no uploads left, it\n"
HELP="${HELP}\tputs them in the upload directory.  Otherwise, it creates\n"
HELP="${HELP}\ta new directory in both data/ and dataraw/ for the update\n"
USAGE="\t\tUsage: ./distributeFiles.sh <zipfile> [OPTION] (use option -h for help)\n"
HELP="${HELP}${USAGE}"
HELP="${HELP}\t\t\t-b: bypass debug mode (don't keep temp files)\n"
HELP="${HELP}\t\t\t-ns: output settings relative to repo root only\n"
HELP="${HELP}\t\t\t-s: output settings only\n"
HELP="${HELP}\t\t\t-t: test mode (silent)\n"
HELP="${HELP}\t\t\t-h: print help\n"

function checkSettings(){
   echo "settings check:"
   printf "\tSETTINGS: %s\n" "$SETTINGS"
   printf "\tZIPFILE: %s\n" "$ZIPFILE"
   printf "\tDATADIR: %s\n" "$DATADIR"
   printf "\tRAWDATADIR: %s\n" "$RAWDATADIR"
   printf "\tFDADIR: %s\n" "$FDADIR"
   printf "\tFDADATASOURCE: %s\n" "$FDADATASOURCE"
   printf "\tFDAUPDATESOURCE: %s\n" "$FDAUPDATESOURCE"
   printf "\tLASTLATEST: %s\n" "$LASTLATEST"
   printf "\tRAWDATADEST: %s\n" "$RAWDATADEST"
   printf "\tDATADEST: %s\n" "$DATADEST"
   printf "\tRAWDATAUPDATEDEST: %s\n" "$RAWDATAUPDATEDEST"
   printf "\tDATAUPDATEDEST: %s\n" "$DATAUPDATEDEST"
   printf "\tUSAGE:\n"
   printf "$USAGE"
   printf "\tHELP:\n"
   printf "$HELP"
}

if [[ $# -gt 1 ]] ; then
   if [ "$2" == "-s" ] || [ "$2" == "-ns" ] ; then
      checkSettings
      exit 0
   fi
fi

function expandArchive(){
   if [[ "$silent" == "false" ]] ; then
      printf "unzipping %s...\n" "$1"
   fi

   unzip "$1"
}

function deleteUnneededFiles(){
   if [[ "$silent" == "false" ]] ; then
      printf "removing unneeded files...\n"
   fi

   rm food.csv
   rm food_attribute.csv
   rm food_nutrient.csv
   rm all_downloaded_table_record_counts.csv
   rm Download*.pdf
   rm "$1"
}

function moveToRawFDADir(){
   if [[ "$silent" == "false" ]] ; then
      printf "moving files to $3...\n"
   fi

   mv "$1" "$3"
   mv "$2" "$3"
}


if [[ $# -gt 1 ]] ; then
   if [ "$2" == "-b" ] ; then
      debug=false
      if [[ "$silent" == "false" ]] ; then
         echo "debugging off"
      fi
   elif [ "$2" == "-h" ] ; then
      printf "$HELP"
      exit 0
   else
      printf "$USAGE"
      exit 1
   fi
elif [[ $# -lt 1 ]] ; then
   printf "$USAGE"
   exit 1
elif [ "$1" == "-h" ] ; then
   printf "$HELP"
   exit 0
fi


if [ "$debug" == "true" ] ; then
   checkSettings
fi

expandArchive $ZIPFILE

if [ "$debug" == "false" ] ; then
   deleteUnneededFiles $ZIPFILE
fi

if [ $SERVER_POPULATED == "true" ] ; then
   moveToRawFDADir $FDADATASOURCE $FDAUPDATESOURCE $RAWDATADEST
elif [ "$DONE_UPLOADING" == "true" ] ; then
   moveToRawFDADir $FDADATASOURCE $FDAUPDATESOURCE $RAWDATADEST
else
   mkdir $RAWDATAUPDATEDEST
   mkdir $DATAUPDATEDEST
   moveToRawFDADir $FDADATASOURCE $FDAUPDATESOURCE $RAWDATAUPDATEDEST
fi

