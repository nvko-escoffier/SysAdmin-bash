#!/bin/bash
#
# AUTHOR: Julien ESCOFFIER 
# CONTACT: julien.escoffier@protonmail.com
# DESCRIPTION:	This script will list the administratives shares over a network
# 				output file is located under $LOGFILE var
# URLs:
#		- GitHub: https://github.com/nvko-escoffier
# 		- Personal Blog: https://nvko-it.com
# VERSION: 0.2
# LICENSE: GNU General Public License
# PREREQUISITES: 
# 		- DomainName/User/Pass of a privilegied user
# 		- Python3
# TODO:
# 		- Export result to a html file
#		- Possibility to provides IP addresses (command arguments implementation)
# 		- Encapsulation into screen to have output logs & main screen (cf https://github.com/escoffier-saint-cyr/RacoonReconnect)

WRK_DIR=/usr/local/src
LOGFILE=$WRK_DIR/admin_shares_listing.log
IP_TMP=$WRK_DIR/ip_tmp
IP_LST=$WRK_DIR/ip_listing
IP_LST_FIN=$WRK_DIR/ip_listing_final

#Create & empty previous used files
>$LOGFILE;>$IP_LST;>$IP_LST_FIN


# Check if a binary is installed
binary_check() {
	if command -v $1 &>/dev/null; then 
		echo -en "Checking dependencies $1 ..." 
		sleep 0.4
		echo "[OK]"
	else 
		echo "$1 is NOT installed. Exiting ..."
		exit 0
	fi
}

get_url() {
	cd $WRK_DIR
	echo -n "Downloading "
	echo -n ${1##*/}" ... "
	curl -O $1 >/dev/null 2>&1
	sleep 0.4
	echo -e "[OK]\n" 
}

sft_clean() {
	rm -f $*
}

#Enable Ctrl+C during the scan process
trap "exit" SIGINT

#Welcome message
echo -e "DESCRIPTION:	This script will list the administratives shares over a network"
echo -e "\t\toutput file is located under $LOGFILE var"
echo -e "USAGE:		./admin_shares_listing.sh\n"


# Dependencies check
binary_check python

#Get the smbmap sources
get_url https://raw.githubusercontent.com/ShawnDEvans/smbmap/master/smbmap.py


# User entry (IP/MASK), & format processing 
>$IP_LST
read -p "Please enter the network you want to scan (w.x.y.z/xx): " IP_DEF
echo -n "Generating list of IPs ... "
nmap -sL $IP_DEF -PN -n|grep report|cut -d' ' -f5|sed -e '1,1d'|sed -e '$d' >$IP_LST
#tr '\n' ' '<$IP_TMP >$IP_LST
echo "[OK]"

#Keep only IP addresses that can be contacted
echo -n "Keep only IP with TCP port 445(Microsoft Naked CIFS) opened ... "
for sort_ip in $(cat $IP_LST); do
# Uncomment the next line if you want to track progressing on $LOGFILE
#	echo "Testing $sort_ip address" >>$LOGFILE
	nmap -sT $sort_ip -p445 -n|grep open >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "$sort_ip" >> $IP_LST_FIN
	fi
done
echo -e "[OK]\n"


# Store Domain/Username/Password informations
read -p "     Domain name: " get_inf_dom
read -p "     Username: " get_inf_usr 
read -p "     Password: " -s get_inf_pas
echo -e "\n" >>$LOGFILE


#Proceed to the scan with all parameters previously gathered
echo -en "\n\nStarting the scan ... \n"
while read IP; do
#	echo "blah$IP" >> $LOGFILE 
	echo "processing IP: $IP"
	python $WRK_DIR/smbmap.py -u $get_inf_usr -d get_inf_dom -p get_inf_pas -H $IP |grep -v "Finding open SMB\|Guest SMB session\|Authentication error\|SMB SessionError\|SecurityMode" >> $LOGFILE
done <$IP_LST_FIN

#for END_IP in $(cat $IP_LST); do
#	python $WRK_DIR/smbmap.py -u $get_inf_usr -d get_inf_dom -p get_inf_pas -H $END_IP -q |\
#		grep -v "Finding open SMB\|Guest SMB session\|Authentication error\|SMB SessionError\|SecurityMode" |\
#		tee -a $LOGFILE
#done

echo "[FINISHED]"
echo -e "\nYou can check results on the $LOGFILE\n\n"

#remove working files
sft_clean $IP_LST $IP_LST_FIN $WRK_DIR/smbmap.py

