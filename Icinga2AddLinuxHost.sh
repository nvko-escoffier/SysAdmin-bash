#!/bin/bash
#
# AUTHOR: Julien ESCOFFIER 
# CONTACT: julien.escoffier@protonmail.com
# WEBSITE: https://nvko-it.com
# DESCRIPTION:	Automatically add a new Linux host to the icinga server configuration
# 		Additional tasks needs to be done on the client side.
#		This is fully documented on the Git Repository page
# URLs:
#		- GitHub: https://github.com/escoffier-saint-cyr/
# 		- Personal: https://nvko.net
# VERSION: 0.3
# LICENSE: GNU General Public License
# PREREQUISITES: 
# TODO:

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
  vars.os = "Linux"
  vars.notification["mail"] = {
    groups = [ "icingaadmins" ]
  }
}

EOF
	echo -e "hosts.conf file populated\n"
	echo "You can now reload icinga2 process."
fi
