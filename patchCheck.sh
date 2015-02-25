#/bin/bash
# patchCheck.sh - Check for latest packages that need updating
# Created by Michael Wilson, mwilson@omgroupllc.com or mwilson@glassnetworks.net
# Created on 2/24/2015
# Modified on 2/25/2015
# ChangeLog     0.0 - initial script creation
#               0.1 - adding of initial functions and mail
#               0.2 - added version check and patch log output correction

export vers="patchCheck Version 0.2"

# source root bash profile
. /root/.bash_profile

EMAIL='mwilson@omgroupllc.com'

export DS=$(date +%m-%d-%Y_%H%M)
export DSD=$(date +%m-%d-%Y)
export logDir=/root/patchLogs
export FILENAME="`hostname`_patchLog-$DS.txt"

# Create folders
if [ ! -d "${logDir}" ]
then
   echo "\nWarning: `echo $logDir` did not exist, creating..."
   mkdir -p ${logDir}
fi

function dLine () {
echo -e "-------------------------------------------------------------------------------------------"
}

function dLineNew () {
echo -e "-------------------------------------------------------------------------------------------"\\n
}

function updateCheck () {
yum check-update > /tmp/patchLog
export chkKern=`cat /tmp/patchLog |grep -i kern > /dev/null; echo $?`

if [ $chkKern != '1' ]
then
echo -e "**** NOTE --> there are kernel level updates that are being reported.  Please mark as ignored" >> $logDir/$FILENAME
echo -e "during any patching event until an approved maintenance window can be scheduled."\\n >> $logDir/$FILENAME
fi

cat /tmp/patchLog >> $logDir/$FILENAME
}

function buildReport () {
dLine >> $logDir/$FILENAME
echo -e "patchCheck report for `hostname -s`"\\n >> $logDir/$FILENAME
echo -e "The following list of packages require update"\\n >> $logDir/$FILENAME
updateCheck
}

function version () {
echo -e $vers >> $logDir/$FILENAME
echo -e $vers
}

function doMail () {
if [ "$EMAIL" != '' ]
then
        STATUS=`which mail`
        if [ "$?" != 0 ]
        then
                echo "The program 'mail' is currently not installed."
        else
                echo "Please open attachment to view the log" | mutt -s "patchLog for `hostname -s` for $DSD" -a $logDir/$FILENAME -- $EMAIL
                echo -e "Email has been sent.  For viewing you can also read the file using vi/cat/nano"
                echo -e "File is $logDir/$FILENAME"
        fi
fi
}

function cleanUp () {
cd $logDir
find ./ -type f -iname "`hostname`_patchLog*" -mtime +30 -exec rm -f {} \; > /dev/null 2>&1
rm -rf /tmp/patchLog
}

case "$1" in
    check)
        buildReport
        cleanUp >> $logDir/$FILENAME
        doMail
        exit 0
        ;;
    version)
        version
        exit 0
        ;;
    *)
        echo "Usage: $0 (check}"
        exit 2
        ;;
esac
