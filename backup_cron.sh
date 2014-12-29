#!/bin/ksh
# backup_cron.sh - crontab backup script
# Created by Michael Wilson, mwilson@omgroupllc.com or mwilson@glassnetworks.net
# Created on 6/11/2013
# Updated on 11/17/2014
# Version 0.2
# ChangeLog     0.0 - initial script creation
#               0.1 - added cleanup logic
#               0.2 - configured for backup_cron.sh to run for the root user at CWD

#---------------------------- cleanup_old_files () -----------------------------
cleanup_old_files()
{

  cd ${BACKUP_PATH}
  RETURN_CODE=$?
  if [ "${RETURN_CODE}" -ne 0 ]
  then
     echo "Error: Could not change directory to \$BACKUP_PATH, exiting..."
     return 1
  fi
  echo "Removing the following files ..... ( $(date) )"
  find ${BACKUP_PATH} -name "${BACKUP_NAME}*.txt" -mtime +30 -exec ls -ltr {} \;
  find ${BACKUP_PATH} -name "${BACKUP_NAME}*.txt" -mtime +30 -exec rm {} \;

  find ${BACKUP_PATH} -name "${BACKUP_NAME}*.log" -mtime +30 -exec ls -ltr {} \;
  find ${BACKUP_PATH} -name "${BACKUP_NAME}*.log" -mtime +30 -exec rm {} \;
}

#----------- M A I N   L O G I C ------------------------------------------------

DATESTAMP=$(date +%Y%m%d%H%M)
BACKUP_PATH=/root/cronBackupLogs
#BACKUP_PATH=/backup/home/$USER
BACKUP_NAME=root_crontab

if [ ! -d "${BACKUP_PATH}" ]
then
   echo "\nWarning: `echo $PATHNAME` did not exist, creating..."
   mkdir -p ${BACKUP_PATH}
fi

exec >> ${BACKUP_PATH}/${BACKUP_NAME}_${DATESTAMP}.log 2>&1

cd ${BACKUP_PATH}

crontab -l > ${BACKUP_NAME}_${DATESTAMP}.txt

echo "Created backup copy of crontab contents in ${BACKUP_PATH}/${BACKUP_NAME}_${DATESTAMP}.txt ...( $(date) )"
cleanup_old_files


