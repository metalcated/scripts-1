#/bin/bash
# getStatus.sh - capture server status
# Created by Michael Wilson, mwilson@omgroupllc.com or mwilson@glassnetworks.net
# Created on 11/10/2014
# Updated on 11/16/2014
# Version 0.3
# ChangeLog     0.0 - initial script creation
# 		0.1 - Cleaned up script a little and modifed functions
# 		0.2 - Added mysql db functions for daemon status and db
# 		0.3 - Added function to check logs for errors

# Variables statement
export TOTALMEM=`free -m | head -2 | tail -1| awk '{print $2}'`
export TOTALBC=`echo "scale=2;if($TOTALMEM<1024 && $TOTALMEM > 0) print 0;$TOTALMEM/1024"| bc -l`
export USEDMEM=`free -m | head -2 | tail -1| awk '{print $3}'`
export USEDBC=`echo "scale=2;if($USEDMEM<1024 && $USEDMEM > 0) print 0;$USEDMEM/1024"|bc -l`
export FREEMEM=`free -m | head -2 | tail -1| awk '{print $4}'`
export FREEBC=`echo "scale=2;if($FREEMEM<1024 && $FREEMEM > 0) print 0;$FREEMEM/1024"|bc -l`
export TOTALSWAP=`free -m | tail -1| awk '{print $2}'`
export TOTALSBC=`echo "scale=2;if($TOTALSWAP<1024 && $TOTALSWAP > 0) print 0;$TOTALSWAP/1024"| bc -l`
export USEDSWAP=`free -m | tail -1| awk '{print $3}'`
export USEDSBC=`echo "scale=2;if($USEDSWAP<1024 && $USEDSWAP > 0) print 0;$USEDSWAP/1024"|bc -l`
export FREESWAP=`free -m | tail -1| awk '{print $4}'`
export FREESBC=`echo "scale=2;if($FREESWAP<1024 && $FREESWAP > 0) print 0;$FREESWAP/1024"|bc -l`

# Other settings configurable by client
export Today=$(date +%m-%d-%Y)
export SRVHB="/root/srv_health_logs"
export HealthReport="`hostname -s`_health-`date +%y%m%d`-`date +%H%M`.txt"
 
# Email Settings
export Subject="Server Health Report for `hostname` on $Today"
export emlToCC='mwilson@omgroupllc.com,david.fehn@clevelandwater.com'
export emlFrom='CWDWEB02 <administrator@clevelandwater.com>'
export emlBody="${SRVHB}/health_report_body.eml"
export emlAttach=${SRVHB}/${HealthReport}
echo "Please open the attachment to view the log files." > $emlBody
 
# Create server health backup directory
if [ ! -d "${SRVHB}" ]
then
echo "\nWarning: `echo $SRVHB` did not exist, creating..."
mkdir -p ${SRVHB}
fi
 
function dLine()
{
echo -e "-------------------------------------------------------------------------------------------"
}
 
function dLineNew()
{
echo -e "-------------------------------------------------------------------------------------------\n"
}
 
function hostDetails()
{
dLine
echo -e "`hostname` Server Health Report (PROC/CPU/MEM/DISK)"
dLineNew
echo -e "Hostname  : `hostname`"
echo -e "Kernel Version  : `uname -r`"
echo -e "Uptime  : `uptime | sed 's/.*up \([^,]*\), .*/\1/'`"
#echo -e "Last Reboot Time : `who -b | awk '{print $3,$4}'`"\\n
}
 
function cpuInfo()
{
dLine
echo -e "CPU LOAD --> Threshold < 1 Normal | >= 1 Caution | >= 2 Unhealthy "
dLineNew
echo -e "Load Average  : `uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d,`"
echo -e "Heath Status : `uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d, | awk '{if ($1 > 2) print "Unhealthy"; else if ($1 > 1) print "Caution"; else print "Normal"}'`"\\n
 
dLine
echo -e "TOP MEM and CPU using processes/applications"
dLineNew
 
echo -e "--> TOP MEMORY Proc/App"
echo -e "PID %MEM RSS COMMAND"
ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10
echo ""
 
echo -e "--> TOP CPU Proc/App"
top b -n1 |head -26 |tail -12
echo ""
}
 
function memInfo()
{
dLine
echo -e "MEM Usage --> Threshold < 90 Normal | >= 90 Caution | >= 95 Unhealthy "
dLineNew
 
echo "$(($FREEMEM * 100 / $TOTALMEM ))" > fmd
echo "$(($FREESWAP * 100 / $TOTALSWAP ))" > fsd
 
echo -e "--> Physical Memory : `cat fmd | awk '{print $1}'| cut -f1 -d%| awk '{if ($1 < 5) print "Unhealthy"; else if ($1 < 95) print "Caution"; else print "Normal"}'`"
echo -e "Total\tUsed\tFree\t%Free"
echo -e "${TOTALBC}GB\t${USEDBC}GB \t${FREEBC}GB\t$(($FREEMEM * 100 / $TOTALMEM ))%"\\n
echo -e "--> Swap Memory : `cat fsd | awk '{print $1}'| cut -f1 -d%| awk '{if ($1 < 5) print "Unhealthy"; else if ($1 < 95) print "Caution"; else print "Normal"}'`"
echo "Total\tUsed\tFree\t%Free"
echo "${TOTALSBC}GB\t${USEDSBC}GB\t${FREESBC}GB\t$(($FREESWAP * 100 / $TOTALSWAP ))%"
echo ""
}
 
function diskInfo()
{
dLine
echo -e "DISK Usage --> Threshold < 90 Normal | >= 90 Caution | >= 95 Unhealthy "
dLineNew
 
df -Pkh | grep -v 'Filesystem' > /tmp/disk.status
while read DISK
do
LINE=`echo $DISK | awk '{print $1,"\t",$6,"\t",$5," used","\t",$4," free space"}'`
echo -e $LINE
done < /tmp/disk.status
echo -e "Heath Status"
echo
while read DISK
do
USAGE=`echo $DISK | awk '{print $5}' | cut -f1 -d%`
if [ $USAGE -ge 95 ]
then
STATUS='Unhealty'
elif [ $USAGE -ge 90 ]
then
STATUS='Caution'
else
STATUS='Normal'
fi
 
LINE=`echo $DISK | awk '{print $1,"\t",$6}'`
echo -ne $LINE "\t\t" $STATUS
echo
done < /tmp/disk.status
echo ""
}
 
function oraInfo()
{
dLine
echo -e "ORACLE Process Information "
dLineNew
echo -e "--> PMON process(es)"
ps -ef |grep -i pmon |grep -v grep
echo ""
echo -e "--> LISTNER process(es)"
ps -ef |grep -i list |grep -v grep
echo ""
echo -e "--> ORA_process(es)"
ps -ef |grep -i 'ora_' |grep -v grep
echo ""
}
 
function mysqlDBInfo()
{
dLine
echo -e "List of MySQL Database "
dLineNew
#show databases
mysql -u dbstatus -e "show databases"| awk '{if(NR>1)print}'
echo
dLine
echo -e "MySQL Process Status "
dLine
pidid=`ps -ef | grep -v grep|grep -v libexec| grep mysqld|cut -f7 -d" "`
procd=`ps -ef | grep -v grep|grep -v libexec| grep mysqld|cut -f25-100 -d" "`
echo -e "\nProcess ID: $pidid"
echo -e "Service Info: $procd"
mysqladmin status -u dbstatus
echo
dLine
echo -e "MySQL Log Errors "
dLine
if [[ -n $(grep -i error /var/log/mysqld/error.log) ]]; then
echo
grep -i error /var/log/mysqld/error.log
echo
else
echo
echo -e "/var/log/mysqld/error.log contains no errors"
echo
fi
dLine
}
 
function sysLogErrors()
{
dLine
echo -e "System/Messages Errors "
dLine
if [[ -n $(grep -i error /var/log/messages) ]]; then
echo
grep -i error /var/log/messages
else
echo
echo -e "/var/log/messages contains no errors"
fi
echo
}
 
function sudoLogErrors()
{
dLine
echo -e "SUDO Log Errors "
dLine
if [[ -n $(grep -i error /var/log/secure) ]]; then
echo
grep -i error /var/log/secure
else
echo
echo -e "/var/log/secure contains no errors"
fi
echo
}	
 
function EmlChkFrom()
{
if [[ ! -f $HOME/.muttrc ]]; then
echo -e "\e[32mEMail From\e[0m: added to $HOME/.muttrc\e[0m"
echo "set from=\"$emlFrom\"" > $HOME/.muttrc
fi
if [[ ! -s $HOME/.muttrc ]]; then
echo -e "\e[32mEMail From\e[0m: added to $HOME/.muttrc\e[0m"
echo "set from=\"$emlFrom\"" > $HOME/.muttrc
fi
}
 
function doMail()
{
if [[ "$emlToCC" != '' ]]; then
EmlChkFrom
STATUS=`which mutt`
if [[ "$?" != 0 ]]; then
echo -e "\nThe program 'mutt' is currently not installed.\n"
exit 0
else
echo -e "\nEmail From: $emlFrom"
echo "Email Subject: $Subject"
echo "Email Body: $emlBody"
echo -e "Email Log: $emlAttach\n"
cat $emlBody | mutt -s "$Subject" -a $emlAttach -- $emlToCC
echo -e "Email Sent. Exiting script.\n"
fi
fi
}
 
function cleanUp ()
{
rm -f fmd
rm -f fsd
rm -f /tmp/disk.status

cd $SRVHB
find ./ -type f -iname "`hostname -s`_health*" -mtime +30 -exec rm -f {} \; > /dev/null 2>&1
}
 
hostDetails >> $SRVHB/$HealthReport
cpuInfo >> $SRVHB/$HealthReport
memInfo >> $SRVHB/$HealthReport
diskInfo >> $SRVHB/$HealthReport
sysLogErrors >> $SRVHB/$HealthReport
sudoLogErrors >> $SRVHB/$HealthReport
mysqlDBInfo >> $SRVHB/$HealthReport
oraInfo >> $SRVHB/$HealthReport
doMail
cleanUp
