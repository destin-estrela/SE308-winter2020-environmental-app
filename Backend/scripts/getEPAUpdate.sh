#!/bin/bash
debug=true
silent=false
fin=false

THISPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
SETTINGS="${THISPATH}/settings.txt"

if [[ -n $1 ]] ; then
   if [ "$1" == "-t" ] || [ "$1" == "-n" ] || [ "$1" == "-ns" ] ; then
      silent=true
      if [ "$1" == "-n" ] || [ "$1" == "-ns" ] ; then
         #SETTINGS="${THISPATH}/settings_npm.txt"
         SETTINGS="Backend/scripts/settings_npm.txt"
      fi
   fi
fi

EPA_DIR_ADDRESS=$(grep -oP '(?<=^EPA_DIR_ADDRESS:).*' $SETTINGS)
EPADATASOURCE=$(grep -oP '(?<=^EPADATASOURCE:).*' $SETTINGS)
EPA_DATA_URL="${EPA_DIR_ADDRESS}${EPADATASOURCE}"
RAWDATADIR=$(grep -oP '(?<=^RAWDATADIR:).*' $SETTINGS)
EPADIR=$(grep -oP '(?<=^EPADIR:).*' $SETTINGS)
RAWDATADEST="${RAWDATADIR}${EPADIR}"
LASTDATAPATH="${RAWDATADEST}${EPADATASOURCE}"
LOGDIR=$(grep -oP '(?<=^LOGDIR:).*' $SETTINGS)
DOWNLOADLOGDIR="${LOGDIR}downloads/"
USAGE="\t\tUsage: ./getEPAUpdate.sh [OPTION] (use option -h for help)\n"
HELP="${USAGE}\t\t**If no OPTION supplied, debug mode on (temp files remain)\n"
HELP="${HELP}\t\t\t-b: bypass debug mode\n"
HELP="${HELP}\t\t\t-n: test with settings relative to repo root\n"
HELP="${HELP}\t\t\t-ns: output settings relative to repo root only\n"
HELP="${HELP}\t\t\t-s: output settings only\n"
HELP="${HELP}\t\t\t-t: test mode (silent)\n"
HELP="${HELP}\t\t\t-h: print help\n"

function checkSettings(){
   echo "settings check:"
   printf "\tSETTINGS: %s\n" $SETTINGS
   printf "\tEPA_DIR_ADDRESS: %s\n" "$EPA_DIR_ADDRESS"
   printf "\tEPADATASOURCE: %s\n" "$EPADATASOURCE"
   printf "\tEPA_DATA_URL: %s\n" "$EPA_DATA_URL"
   printf "\tRAWDATADIR: %s\n" "$RAWDATADIR"
   printf "\tEPADIR: %s\n" "$EPADIR"
   printf "\tRAWDATADEST: %s\n" "$RAWDATADEST"
   printf "\tLASTDATAPATH: %s\n" "$LASTDATAPATH"
   printf "\tLOGDIR: %s\n" "$LOGDIR"
   printf "\tDOWNLOADLOGIR: %s\n" "$DOWNLOADLOGDIR"
   printf "\tUSAGE:\n"
   printf "$USAGE"
   printf "\tHELP:\n"
   printf "$HELP"
}

if [[ -n $1 ]] ; then
   if [ "$1" == "-ns" ] || [ "$1" == "-s" ] ; then
      checkSettings
      exit 0
   fi
fi

function getData(){
   printf "dowloading from %s\n" "$EPA_DATA_ADDRESS"
   timestamp=$(date +%s)
   logfile="${DOWNLOADLOGDIR}${timestamp}_epa.log"
   curl -vs -O --stderr $logfile "$EPA_DATA_URL"
   if [ $? -eq 0 ] ; then
      echo "download successful"
      checkIfUpdated
   else
      echo "download failed"
      fin=true
   fi
}

function checkIfUpdated(){
   echo "checking for newer version"
   if [ -e $LASTDATAPATH ] ; then
      echo "diffing against current file"
      diff "$LASTDATAPATH" "$EPADATASOURCE"
      exitcode=$?
      if [[ $exitcode == 0 ]] ; then
         echo "no update available"
         fin=true
      else
         echo "update found, replacing old"
         mv $EPADATASOURCE "$RAWDATADEST"
      fi
   else
      echo "new EPA source moved to raw data directory"
      mv $EPADATASOURCE "$RAWDATADEST"
   fi
}


if [[ -n $1 ]] ; then
   if [ "$1" == "-h" ] ; then
      printf "$HELP"
      exit 0
   elif [ "$1" == "-b" ] ; then
      debug=false
      if [[ "$silent" == "false" ]] ; then
         echo "debugging off"
      fi
   else
      printf "$USAGE"
      exit 1
   fi
fi

if [ "$silent" == "false" ] ; then
   checkSettings
fi

getData

if [ "$fin" == "false" ] ; then
   ./convertEPAData.sh "$RAWDATADEST" "$EPADATASOURCE"
fi

