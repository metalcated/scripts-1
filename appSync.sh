#!/bin/bash
# appSync.sh - application sync script
# Created by Michael Wilson, mwilson@omgroupllc.com or mwilson@glassnetworks.net
# Created on 11/10/2014
# Updated on 11/16/2014
# Version 0.3
# ChangeLog 	0.0 - initial script creation
# 		0.1 - adding of initial functions and mail
#		0.2 - full/incremental function added
#		0.3 - test function added as well as check of dirList file

# source root bash profile
. /root/.bash_profile

#EMAIL='mwilson@omgroupllc.com,david_fehn@ClevelandWater.com'

export DS=$(date +%m-%d-%Y_%H%M)
export DSD=$(date +%m-%d-%Y)
export logDir=/root/appSyncLogs
export FILENAME="`hostname`_appSyncLog-$DS.txt"
export destSrv="$destination"
export backupDirList="/root/scripts/dirList"

# Check that backupDirList file actually exists
if [[ ! -f "$backupDirList" ]]
then
echo "The backupDirList file does not exist.....exiting..!!!" | mutt -s "appSync for `hostname -s` for $DSD" $EMAIL
exit 0
fi

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

function fullBackup () {
for appDir in `cat $backupDirList`;
do rsync -ahuv $appDir $destSrv:$appDir;
#do rsync -ahuv -e 'ssh -p 31777' $appDir $destSrv:$appDir;
done
}

function incrBackup () {
for appDir in `cat $backupDirList`;
do rsync -ahuv --delete $appDir $destSrv:$appDir;
#do rsync -ahuv --delete -e 'ssh -p 31777' $appDir $destSrv:$appDir;
done
}

function testFullBackup () {
for appDir in `cat $backupDirList`;
do rsync -ahuvn $appDir $destSrv:$appDir;
#do rsync -ahuvn -e 'ssh -p 31777' $appDir $destSrv:$appDir;
done
}

function doMail () {
if [ "$EMAIL" != '' ]
then
        STATUS=`which mail`
        if [ "$?" != 0 ]
        then
                echo "The program 'mail' is currently not installed."
        else
                echo "Please open attachment to view the log" | mutt -s "appSync for `hostname -s` for $DSD" -a $logDir/$FILENAME -- $EMAIL
                #cat $logDir/$FILENAME | mutt -s "appSync for `hostname -s` for $DSD" $EMAIL
                echo -e "Email has been sent.  For viewing you can also read the file using vi/cat/nano"
                echo -e "File is $logDir/$FILENAME"
        fi
fi
}

function cleanUp () {
cd $logDir
find ./ -type f -iname "`hostname`_appSyncLog*" -mtime +30 -exec rm -f {} \; > /dev/null 2>&1
}

case "$1" in
    full) 
        fullBackup >> $logDir/$FILENAME
	cleanUp >> $logDir/$FILENAME
	#doMail
	exit 0
        ;;
    incr)
        incrBackup >> $logDir/$FILENAME
	cleanUp >> $logDir/$FILENAME
	#doMail
	exit 0
        ;;
    testFull)
        testFullBackup >> $logDir/$FILENAME
        cleanUp >> $logDir/$FILENAME
        #doMail
        exit 0
        ;;
    *)
        echo "Usage: $0 {full|incr}"
        exit 2
        ;;
esac
