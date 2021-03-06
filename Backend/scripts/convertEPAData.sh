#!/bin/bash
debug="true"
silent="false"

THISPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
SETTINGS="${THISPATH}/settings.txt"

if [[ $# -gt 2 ]] ; then
   if [ -n $3 ] ; then
      if [ "$3" == "-ns" ] || [ "$3" == "-n" ] || [ "$3" == "-t" ] ; then
         silent="true"
         if [ "$3" != "-t" ] ; then
            #SETTINGS="${THISPATH}/settings_npm.txt"
            SETTINGS="Backend/scripts/settings_npm.txt"
         fi
      fi
   fi
fi

SCRIPTSDIR=$(grep -oP '(?<=^SCRIPTSDIR:).*' $SETTINGS)
DATADIR=$(grep -oP '(?<=^DATADIR:).*' $SETTINGS)
EPADIR=$(grep -oP '(?<=^EPADIR:).*' $SETTINGS)
OUTFILE_END=$(grep -oP '(?<=^OUTFILE_END:).*' $SETTINGS)
NEWDATADIR="$1"
EPADATASOURCE="$2"
EPA_PATTERNFILE=$(grep -oP '(?<=^EPA_PATTERNFILE:).*' $SETTINGS)
EPA_PATTERN_PATH="${SCRIPTSDIR}${EPA_PATTERNFILE}"
NEWDATAPATH="${NEWDATADIR}${EPADATASOURCE}"
AWKDIR=$(grep -oP '(?<=^AWKDIR:).*' $SETTINGS)
AWKDIR="${SCRIPTSDIR}${AWKDIR}"
TMPDIR=$(grep -oP '(?<=^TMPDIR:).*' $SETTINGS)
TMPFILE_END=$(grep -oP '(?<=^TMPFILE_END:).*' $SETTINGS)
SAFER_PREFIX=$(echo $EPADATASOURCE | grep -oP ".*(?=.xls)")
SAFERCSVROUGH_TMP="${TMPDIR}${SAFER_PREFIX}_roughcsv${TMPFILE_END}"
SAFERCSVPREPPED_TMP="${TMPDIR}${SAFER_PREFIX}_preppedcsv${TMPFILE_END}"
SAFERSPLIT_PREFIX="${TMPDIR}${SAFER_PREFIX}"
SAFEROLD="${TMPDIR}${SAFER_PREFIX}00"
SAFERNEW="${TMPDIR}${SAFER_PREFIX}01"
SAFEROLD_TMP="${SAFEROLD}${TMPFILE_END}"
SAFERNEW_TMP="${SAFERNEW}${TMPFILE_END}"
SAFEROLDTRIM_TMP="${TMPDIR}${SAFER_PREFIX}_oldtrim${TMPFILE_END}"
SAFERNEWTRIM_TMP="${TMPDIR}${SAFER_PREFIX}_newtrim${TMPFILE_END}"
SAFERJOINED_TMP="${TMPDIR}${SAFER_PREFIX}_joined${TMPFILE_END}"
SAFERB4_TMP="${TMPDIR}${SAFER_PREFIX}_b4${TMPFILE_END}"
SAFERCLEAN_TMP="${TMPDIR}${SAFER_PREFIX}_clean${TMPFILE_END}"
SAFERSORTED_TMP="${TMPDIR}${SAFER_PREFIX}_sorted${TMPFILE_END}"
SAFERUNIQUE_TMP="${TMPDIR}${SAFER_PREFIX}_unique${TMPFILE_END}"
SAFER_JSON="${DATADIR}${EPADIR}${SAFER_PREFIX}${OUTFILE_END}"
AWK_OLDEPA_TRIM="${AWKDIR}epaoldtrim.awk"
AWK_NEWEPA_TRIM="${AWKDIR}epanewtrim.awk"
AWK_EPA_JSON="${AWKDIR}epatojson.awk"
USAGE="\t\tUsage: ./convertEPAData.sh [OPTION] (use option -h for help)\n"
HELP="${USAGE}\t\t**If no OPTION supplied, debug mode on (temp files remain)\n"
HELP="${HELP}\t\t\t-b: bypass debug mode\n"
HELP="${HELP}\t\t\t-n: test with settings relative to repo root\n"
HELP="${HELP}\t\t\t-ns: output settings relative to repo root\n"
HELP="${HELP}\t\t\t-s: output settings only\n"
HELP="${HELP}\t\t\t-t: test mode (silent)\n"
HELP="${HELP}\t\t\t-h: print help\n"

function checkSettings(){
   echo "settings check:"
   printf "\tSETTINGS: %s\n" $SETTINGS
   printf "\tSCRIPTSDIR: %s\n" $SCRIPTSDIR
   printf "\tDATADIR: %s\n" "$DATADIR"
   printf "\tEPADIR: %s\n" "$EPADIR"
   printf "\tOUTFILE_END: %s\n" "$OUTFILE_END"
   printf "\tNEWDATADIR: %s\n" "$NEWDATADIR"
   printf "\tEPADATASOURCE: %s\n" "$EPADATASOURCE"
   printf "\tEPA_PATTERNFILE: %s\n" "$EPA_PATTERNFILE"
   printf "\tEPA_PATTERN_PATH: %s\n" "$EPA_PATTERN_PATH"
   printf "\tNEWDATAPATH: %s\n" "$NEWDATAPATH"
   printf "\tAWKDIR: %s\n" "$AWKDIR"
   printf "\tTMPDIR: %s\n" "$TMPDIR"
   printf "\tTMPFILE_END: %s\n" "$TMPFILE_END"
   printf "\tSAFER_PREFIX: %s\n" "$SAFER_PREFIX"
   printf "\tSAFERCSVROUGH_TMP: %s\n" "$SAFERCSVROUGH_TMP"
   printf "\tSAFERCSVPREPPED_TMP: %s\n" "$SAFERCSVPREPPED_TMP"
   printf "\tSAFERSPLIT_PREFIX: %s\n" "$SAFERSPLIT_PREFIX"
   printf "\tSAFEROLD: %s\n" "$SAFEROLD"
   printf "\tSAFERNEW: %s\n" "$SAFERNEW"
   printf "\tSAFEROLD_TMP: %s\n" "$SAFEROLD_TMP"
   printf "\tSAFERNEW_TMP: %s\n" "$SAFERNEW_TMP"
   printf "\tSAFEROLDTRIM_TMP: %s\n" "$SAFEROLDTRIM_TMP"
   printf "\tSAFERNEWTRIM_TMP: %s\n" "$SAFERNEWTRIM_TMP"
   printf "\tSAFERJOINED_TMP: %s\n" "$SAFERJOINED_TMP"
   printf "\tSAFERB4_TMP: %s\n" "$SAFERB4_TMP"
   printf "\tSAFERCLEAN_TMP: %s\n" "$SAFERCLEAN_TMP"
   printf "\tSAFERSORTED_TMP: %s\n" "$SAFERSORTED_TMP"
   printf "\tSAFERUNIQUE_TMP: %s\n" "$SAFERUNIQUE_TMP"
   printf "\tSAFER_JSON: %s\n" "$SAFER_JSON"
   printf "\tAWK_OLDEPA_TRIM: %s\n" "$AWK_OLDEPA_TRIM"
   printf "\tAWK_NEWEPA_TRIM: %s\n" "$AWK_NEWEPA_TRIM"
   printf "\tAWK_EPA_JSON: %s\n" "$AWK_EPA_JSON"
   printf "\tUSAGE:\n"
   printf "$USAGE"
   printf "\tHELP:\n"
   printf "$HELP"
}

if [[ $# -gt 2 ]] ; then
   if [ -n $3 ] ; then
      if [ "$3" == "-ns" ] || [ "$3" == "-s" ] ; then
         checkSettings
         exit 0
      fi
   fi
fi

#https://stackoverflow.com/questions/17066250/create-timestamp-variable-in-bash-script
function timestamp(){
   date +%s
}

function convertToCsv(){
   #https://www.unix.com/shell-programming-and-scripting/156328-how-convert-xls-file-csv.html
   if [[ "$silent" == "false" ]] ; then
      printf "converting to csv...\n"
   fi
   xls2csv "$1" > "$2"

}

function prepForSplit(){
   if [[ "$silent" == "false" ]] ; then
      printf "clearing control characters...\n"
   fi
   sed -i 's/[[:cntrl:]]//g' "$1"

   if [[ "$silent" == "false" ]] ; then
      printf "converting to lower case...\n"
   fi
   cat "$1" | tr A-Z a-z > "$2"

   if [[ "$silent" == "false" ]] ; then
      printf "removing header lines...\n"
   fi
   sed -i '/^"list call".*/d' "$2"

   if [ $debug == "false" ] ; then
      rm $1
   fi
}

function splitOldAndNew(){
   if [[ "$silent" == "false" ]] ; then
      printf "splitting old and new items...\n"
   fi
   csplit -s -f "$SAFERSPLIT_PREFIX" "$1" '/^"cas.*/'
   # this ensures that no files without .tmp are in temp
   mv "$SAFEROLD" "$SAFEROLD_TMP"
   mv "$SAFERNEW" "$SAFERNEW_TMP"
   # this ensures that no files without .tmp are in temp
}

function processNewData(){
   if [[ "$silent" == "false" ]] ; then
      printf "processing new data...\n"
   fi

   #this removes the header line from the new split file
   echo "$(tail -n +2 "$1")" > "$1"

   if [[ "$silent" == "false" ]] ; then
      printf "removing redundant data...\n"
   fi
   #this file is mainly a log of items that have been added
   #this removes those entries and leaves the ones that have/will be deleted
   sed -i '/"gr[ea]y \[square\]"/!d' "$1"

   #there is a column in the update portion that sometimes goes unused; in order
   #for awk to process the file correctly, "" needs to be added between ,,
   sed -i 's/,,/,"",/g' "$1"
}


function extractRelevantOldData(){
   if [[ "$silent" == "false" ]] ; then
      printf "extracting relevant old data...\n"
   fi
   > $3

   #created a reduced file consisting only of the parts we need
   awk -f $1 $2 >> $3

   #an artifact is left by awk, as our delimiter is "," but we're getting our
   #score from the frist column.  This removes it.
   sed -i 's/|"/|/g' "$3"

   if [ $debug == "false" ] ; then
      rm $2
   fi
}

function extractRelevantNewData(){
   if [[ "$silent" == "false" ]] ; then
      printf "extracting relevant new data...\n"
   fi
   > $3
   #created a reduced file consisting only of the parts we need
   awk -f $1 $2 >> $3

   if [ $debug == "false" ] ; then
      rm $2
   fi
}

function joinOldAndNew(){
   if [[ "$silent" == "false" ]] ; then
      printf "rejoining old and new items...\n"
   fi
   cat $1 $2 > $3

   if [ $debug == "false" ] ; then
      rm "$1"
      rm "$2"
   fi
   #this gives us a "before" file to look at
   cat $3 > "$SAFERB4_TMP"
}

function cleanChemicals(){
   if [[ "$silent" == "false" ]] ; then
      printf "transforming chemicals...\n"
   fi
   if [[ $debug == "true" ]] ; then
      #resets the ingredients file before starting
      #this is necessary because sed is converting the file in place
      #if debug mode is off, the copy likely isn't in the directory 
      cat "$SAFERB4_TMP" > "$2"
      # write the timestamp in the log
      starttime=$(timestamp)
      #logfile="${LOGDIR}cleans/cleaned${starttime}.log"
      # apply removal patterns to ingredients
      after=$(wc -c < $2)
      while read -r pattern;
      do
         # this allows us to comment out patterns in removalpatterns.txt
         if [[ ${pattern:0:1} != "#" ]] ; then
            before=$after
            sed -i "$pattern" "$2" 
            after=$(wc -c < $2)
            removed=$((before - after))
            if [[ "$silent" == "false" ]] ; then
               printf "\tpattern %s removed %s characters\n" "$pattern" "$removed"
            fi
         elif [[ "$silent" == "false" ]] ; then
            printf "\tskipping %s\n" "${pattern:1}"
         fi
      done < $1
      endtime=$(timestamp)
      elapsed=$((endtime - starttime))
      if [[ "$silent" == "false" ]] ; then
         printf "elapsed: %d seconds\n" $elapsed 
      fi
   else
      # apply removal patterns to ingredients
      while read -r pattern;
      do
         if [[ ${pattern:0:1} != "#" ]] ; then
            sed -i "$pattern" $2
         elif [[ "$silent" == "false" ]] ; then
            printf "skipping %s\n" "${pattern:1}"
         fi
      done < $1
   fi
}

function sortOnChem(){
   if [[ "$silent" == "false" ]] ; then
      printf "sorting...\n"
   fi
   LC_ALL=C sort "$1" > "$2"

   if [ $debug == "false" ] ; then
      rm $1
   fi
}

function decideScores(){
   if [[ "$silent" == "false" ]] ; then
      printf "deciding scores...\n"
   fi
   while read line
   do
      IFS='|'; linearr=($line); unset IFS
      chem="${linearr[0]}"
      count_n3=$(grep "$chem|-3" $1 | wc -l)
      count_1=$(grep  "$chem|1" $1 | wc -l)
      count_2=$(grep  "$chem|2" $1 | wc -l)
      count_3=$(grep  "$chem|3" $1 | wc -l)

      if [[ $count_n3 -gt 0 ]] ; then
         sed -i "/$chem|1/d" $1
         sed -i "/$chem|2/d" $1
         sed -i "/$chem|3/d" $1
      elif [[ $count_1 -gt $count_2 ]] ; then
         if [[ $count_1 -gt $count_3 ]] ; then
            sed -i "/$chem|2/d" $1
            sed -i "/$chem|3/d" $1
         else
            sed -i "/$chem|1/d" $1
            sed -i "/$chem|2/d" $1
         fi
      elif [[ $count_2 -gt $count_3 ]] ; then
         sed -i "/$chem|1/d" $1
         sed -i "/$chem|3/d" $1
      else
         sed -i "/$chem|1/d" $1
         sed -i "/$chem|2/d" $1
      fi
   done < $1
}

function removeDuplicates(){
   if [[ "$silent" == "false" ]] ; then
      printf "removing duplicates...\n"
   fi
   uniq $1 $2

   if [ $debug == "false" ] ; then
      rm $1
   fi
}

function createJson(){
   if [[ "$silent" == "false" ]] ; then
      printf "creating json...\n"
   fi

   echo "{" > $3
   awk -f $1 $2 >> $3
   sed -i '$s/,$//' $3
   echo "}" >> $3

   if [ $debug == "false" ] ; then
      rm $2
   fi
}


if [[ $# -gt 2 ]] ; then
   if [ -n $3 ] ; then
      if [ "$3" == "-b" ] ; then
         debug=false
      elif [ "$3" == "-h" ] ; then
         printf "$HELP"
         exit 0
      elif [ "$3" != "-n" ] && [ "$3" != "-t" ] ; then
         printf "$USAGE"
         exit 1
      fi
   fi
elif [[ $# -lt 2 ]] ; then
   printf "$USAGE"
   exit 1
fi

if [[ "$debug" == "true" ]] ; then
   if [[ "$silent" == "false" ]] ; then
      checkSettings
   fi
fi

convertToCsv "$NEWDATAPATH" "$SAFERCSVROUGH_TMP"
prepForSplit "$SAFERCSVROUGH_TMP" "$SAFERCSVPREPPED_TMP"
splitOldAndNew "$SAFERCSVPREPPED_TMP"
processNewData "$SAFERNEW_TMP"
extractRelevantOldData "$AWK_OLDEPA_TRIM" "$SAFEROLD_TMP" "$SAFEROLDTRIM_TMP"
extractRelevantNewData "$AWK_NEWEPA_TRIM" "$SAFERNEW_TMP" "$SAFERNEWTRIM_TMP"
joinOldAndNew "$SAFEROLDTRIM_TMP" "$SAFERNEWTRIM_TMP" "$SAFERJOINED_TMP"
cleanChemicals "$EPA_PATTERN_PATH" "$SAFERCLEAN_TMP"
sortOnChem "$SAFERCLEAN_TMP" "$SAFERSORTED_TMP"
decideScores "$SAFERSORTED_TMP" 
removeDuplicates "$SAFERSORTED_TMP" "$SAFERUNIQUE_TMP"
createJson "$AWK_EPA_JSON" "$SAFERUNIQUE_TMP" "$SAFER_JSON"

