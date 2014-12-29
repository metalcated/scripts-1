#!/bin/bash
# get_server_details.sh - capture myriad of server details
# Created by Michael Wilson, mwilson@omgroupllc.com or mwilson@glassnetworks.net
# Created on 7/23/2014
# Updated on 7/29/2014
# Version 0.4
# ChangeLog     0.0 - initial script creation
#               0.1 - added postfix details
#               0.2 - added directory checks
#               0.3 - included SRVDTLS directory for all log files to be created
#		0.4 - updated comments within script for ease of use 

DS=$(date +%m%d%Y_%H%M)
HN=$(hostname -s)
SRVDTLS='/tmp/server_details'

if [[ ! -e '$SRVDTLS' ]]; then
            mkdir $SRVDTLS
fi

YUMDTLS=$SRVDTLS/yum
SSHDTLS=$SRVDTLS/sshd
NETDTLS=$SRVDTLS/network
SECDTLS=$SRVDTLS/security
PSFDTLS=$SRVDTLS/postfix
NAGDTLS=$SRVDTLS/nagios


if [[ ! -e '$YUMDTLS' ]]; then
            mkdir $YUMDTLS
fi

if [[ ! -e '$SSHDTLS' ]]; then
            mkdir $SSHDTLS
fi

if [[ ! -e '$NETDTLS' ]]; then
            mkdir $NETDTLS
fi

if [[ ! -e '$SECDTLS' ]]; then
            mkdir $SECDTLS
fi

if [[ ! -e '$PSFDTLS' ]]; then
            mkdir $PSFDTLS
fi

if [[ ! -e '$NAGDTLS' ]]; then
            mkdir $NAGDTLS
fi

#Get OS version information
uname -a >> $SRVDTLS/"$HN"_uname-$DS.txt
cat /etc/redhat-release >> $SRVDTLS/"$HN"_redhat-release-$DS.txt

#Get RPM package details
yum list installed >> $YUMDTLS/"$HN"_packages-$DS.txt

#Get YUM details
cp /etc/yum.conf $YUMDTLS/"$HN"_yum_conf-$DS.txt
cp /etc/yum.repos.d/* $YUMDTLS/

#Get NETWORKING details
cp /etc/resolv.conf $NETDTLS/
cp /etc/sysconfig/network-scripts/* $NETDTLS/
cp /etc/sysconfig/network $NETDTLS/

#Get SSH details
cp /etc/ssh/sshd_config $SSHDTLS/"$HN"_sshd_config-$DS.txt

#Get Security details
getsebool -a >> $SECDTLS/"$HN"_getsebool_list-$DS.txt
sestatus >> $SECDTLS/"$HN"_sestatus-$DS.txt
cp /etc/selinux/config $SECDTLS/"$HN"_selinux_config-$DS.txt
service iptables status >> $SECDTLS/"$HN"_iptables-$DS.txt
#semanage port -l >> $SECDTLS/"$HN"_semanage_ports-$DS.txt

#Get POSTFIX details
cp /etc/postfix/main.cf $PSFDTLS/"$HN"_main-$DS.cf
cp /etc/postfix/master.cf $PSFDTLS/"$HN"_master-$DS.cf

#Get NAGIOS details
cp /etc/nagios/nrpe.cfg $NAGDTLS/"$HN"_nrpe-$DS.cfg

