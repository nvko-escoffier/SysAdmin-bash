#!/bin/bash
# 
# author: Julien ESCOFFIER
# contact: julien.escoffier@protonmail.com
# website: https://nvko-it.com
# script revision: 0.3
# Function: Add a Windows host to an existing Icinga2 instance 

ICG_CNF_DIR=/etc/icinga2
ICG_ZONES=zones.conf
ICG_HOSTS=zones.d/master/hosts.conf


echo "Enter the name of the host you want to add to the icinga2 configuration [ENTER]:"
read newhost
# echo -e "\n"


if grep $newhost $ICG_CNF_DIR/$ICG_ZONES 1>/dev/null; then 
	echo "$newhost ALREADY in $ICG_CNF_DIR/$ICG_ZONES"
else
	#add it to the zones.conf
	sed -i "s/# MASTER ZONE/object Endpoint \"$newhost\"{\n\thost = \"$newhost\"\n}\n\n# MASTER ZONE/" $ICG_CNF_DIR/$ICG_ZONES
	sed -i "s/# GLOBAL SYNC/object Zone \"$newhost\"{\n\tendpoints = \[ \"$newhost\" \]\n\tparent = \"master\"\n}\n\n# GLOBAL SYNC/" $ICG_CNF_DIR/$ICG_ZONES
	echo -e "zones.conf file populated"
fi


if grep $newhost $ICG_CNF_DIR/$ICG_HOSTS 1>/dev/null; then 
	echo "$newhost ALREADY in $ICG_CNF_DIR/$ICG_HOSTS"
else
	#add it to the $ICG_CNF_DIR/$ICG_HOSTS
	#echo "Host $newhost added to the $ICG_CNF_DIR/$ICG_HOSTS"
	#sed -i "s/# GLOBAL SYNC/object Zone \"$newhost\" {\n\tendpoints = \[ \"$newhost\" \]\n\tparent = \"master\"\n}\n\n# GLOBAL SYNC/" $ICG_CNF_DIR/$ICG_HOSTS
	cat << EOF >> $ICG_CNF_DIR/$ICG_HOSTS
object Host "$newhost" {
  check_command = "hostalive"
  address = "$newhost"
  vars.client_endpoint = name
  vars.os = "Windows"
  vars.disable_wmi = "true"
  vars.notification["mail"] = {
    groups = [ "icingaadmins" ]
  }
}

EOF
	echo -e "hosts.conf file populated\n"
	echo "You can now reload icinga2 process."
fi
