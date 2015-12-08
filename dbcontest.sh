#!/bin/sh
##########################################################################################
# Author        : Michael Wilson	(contact@michaelwilsondba.info)
# Script Name   : dbcontest.sh
# Created Date  : 11/04/2015
# Modified Date : 12/07/2015
# Purpose       : Perform simple database login validation for a user or service
#                 account using multiple ips with different variables, stops logging
#                 to the .bash_history file to protect password
# Version       : 0.2
#
# ChangeLog     0.0 - initial script creation
#               0.1 - adding of initial functions and mail
#				0.2 - added error information if no sqlplus or too many/little arguments
#
# Syntax        : sh dbcontest.sh [timeout value] [dbips|hosts] [dbname] [dbport] [user]
##########################################################################################

# Export all Variables
export SP=`which sqlplus > /dev/null 2>&1;echo $?`
export PROGNAME=$0
export TO=$1
export DBIPin=$2
export DBIPout=$(echo $DBIPin | tr "," "\n")
export DBNAME=$3
export DBPORT=$4
export UN=$5
unset HISTFILE

if [ $# -lt 5 ]
    then
    echo -e "\n!!!! Not enough variables.  Please review syntax and example below !!!!\n"
    echo -e "Syntax: sh $0 [timeout value] [dbips|hosts] [dbname] [dbport] [user]"
    echo -e "Example: sh $0 5 10.10.10.1,10.10.10.2 mwdbtest 1521 scott\n"
    exit 1
    else
    if [ $# -gt 5 ]
        then
            echo -e "\n!!!! Too many variables.  Please review syntax and example below !!!!\n"
            echo -e "Syntax: sh $0 [timeout value] [dbips|hosts] [dbname] [dbport] [user]"
            echo -e "Example: sh $0 5 10.10.10.1,10.10.10.2 mwdbtest 1521 scott\n"
            exit 1
    fi
fi

preTest () {
if [ $SP -eq 0 ]
    then
    echo -e "######################################################################"
    echo -e "Script: $PROGNAME"
    echo -e "Date: `date` "
    echo -e "Database Name: $DBNAME"
    echo -e "Database Port: $DBPORT"
    echo -e "Database IPs: $DBIPin"
    echo -e "Username: $UN"
    echo -e "######################################################################\n"
    doTest
    else
    echo -e "!!!! SQLPLUS is not in path.  Please set appropriate variables to continue...see example below !!!!\n"
    echo -e "export ORACLE_SID={DATABASE}"
    echo -e "export ORACLE_HOME=your_install_location"
    echo -e "export PATH=$PATH:$ORACLE_HOME/bin"
    fi
}

doTest () {
read -s -p "Enter your password: " passwd
export PW=passwd
echo ""

for i in `echo $DBIPout`;do
CONNECT_STRING="$UN/$PW@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$i)(PORT=$DBPORT))(CONNECT_DATA=(SERVICE_NAME=$DBNAME)))"
timeout $TO sqlplus -s -L /NOLOG <<EOF
whenever sqlerror exit 1
whenever oserror exit 1
CONNECT $CONNECT_STRING
exit
EOF


SQLPLUS_RC=$?
#echo "RC=$SQLPLUS_RC"
[ $SQLPLUS_RC -eq 0 ] && echo "Connected successfully --> using $i"
[ $SQLPLUS_RC -ne 0 ] && echo "Failed to connect --> using $i"
done
}

preTest
