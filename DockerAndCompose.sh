#!/bin/bash
# 
# author: Julien ESCOFFIER
# contact: julien.escoffier@protonmail.com
# website: https://nvko-it.com
# script revision: 0.1
# script function: install docker & compose on Debian systems 
# LICENSE: GNU General Public License

# This script must run as root
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "This script must be run as ROOT user"
    exit
fi


# Supported OS is debian
if [ ! -f /etc/debian_version ]; then
	echo "This OS is not supported."
fi

# Logs are dropped to /tmp folder
WRK_DIR=/usr/local/src
LOGFILE=$WRK_DIR/docker-and-compose.log


# Functions definition
dependencies() {
	add-apt-repository \
		   "deb [arch=amd64] https://download.docker.com/linux/debian \
		    $(lsb_release -cs) \
		    stable"
	apt update
	apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
}

docker_ins() {
	curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
	apt-key fingerprint 0EBFCD88
	add-apt-repository \ "deb [arch=amd64] https://download.docker.com/linux/debian \ $(lsb_release -cs) \ stable"
	apt update
	apt install -y docker-ce docker-ce-cli containerd.io
}

compose_ins() {
	curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
	ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
}

full_ins() {
	docker_ins
	compose_ins
}


echo -e "\nDOCKER and COMPOSE installation choice\n"
PS3='Which component do you want to install ? '
options=("install docker" 
		 "install compose" 
		 "install both" 
		 "Quit")
select opt in "${options[@]}"
do 
	case $opt in
		"install docker")
			dependencies
			docker_ins
			;;
		"install compose")
			dependencies
			compose_ins
			;;
		"install both")
			dependencies
			full_ins
			;;
		"Quit")
			break
			;;
		*) echo "invalid option $REPLY";;
	esac
	break
done

# Print only tasks in progress
