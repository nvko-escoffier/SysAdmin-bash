#!/bin/bash
# 
# author: Julien ESCOFFIER
# contact: julien.escoffier@protonmail.com
# last update: October, 17 2016
# script revision: 0.3
# script function: Backup a Remote server
# needed packages: ipcalc, openssh-clients, dialog

# steps:
# 1- This script will make a backup of a remote server
# 2- Enter IP address of the remote host (management of duplicated entries)
# 3- Testing IP address
# 4- Choose the method of ssh key adding
# 4- Enter the name of backup user
# 5- Enter password of this user (for the ssh key pasting)
# 6- Validating connectivity
# 7- Choose server functions 
# 8- Verifying ...
# 9- listing of directoies that needs backup
# 10- 1st execution
# 11- cronjob definition and type of backup (incremental/differential)

# for the size the first number is the line high, and the second for characters widght
# --clear for cleaning before print

#tail -f
#dialog --tailbox /var/log/messages 0 0

#refer to the ~/.screenrc configuration script to see the details
#screen -S program
########################################################################################################
############################## FUNCTIONS DEFINITION ####################################################
########################################################################################################
function step2 {
dialog --title "Backup utility - Step 2" \
        --inputbox "Please enter the IP address of the server you want to backup:" 10 70 2>/tmp/inputbox.$$
#transmit input text to variable
ip=`cat /tmp/inputbox.$$`;rm -f /tmp/inputbox.$$
}

function step5 {
dialog --title "Backup utility - Step 5" \
        --inputbox "Please enter the name of the remote user with which we will perform backup" 10 70 2>/tmp/username.$$
user=`cat /tmp/username.$$`;rm -f /tmp/username.$$
}

function step6_a {
dialog --title "Backup utility - Step 6" \
        --msgbox "After you hit <Enter> a prompt will appear below. You must enter the pass of the previous user, to copy RSA public ssh key to the remote host" 10 70
ssh-copy-id $user@$ip
}

function step6_b {
if [ $?! = 0 ]; then
        dialog --title "Backup utility - Step 5(bis)" \
        --msgbox "Bad password - Please retry"
        step5
fi
dialog --title "Backup utility - Step 5(bis)" \
        --pause "SSH Key has been successfuly copied" 10 70 2
}

function step6 {
step6_a
step6_b
}

function kill_yiiiaaa {
echo "killing program ..."
exit
}

########################################################################################################
################################ PROGRAM ###############################################################
########################################################################################################
DEFAULT_LOG=/tmp/rsync-default.log
BCK_DIR=/data/backup

# Permit to exit program with Ctrl-C
trap kill_yiiiaaa SIGINT

### STEP 1 ### // Presentation
dialog --title "Backup utility - Step 1" --clear\
        --msgbox "Hello, this utility will allow you to make a backup of a remote server" 10 70

### STEP 2 ### // Enter and verifying IP address
step2

#verify that the IP address is correct
for count in 1 2 3; do
        ipcalc -c $ip -s
        if [ $? = 1 ]; then
dialog --title "Backup utility - Step 2" \
        --msgbox "Bad IP address, please re-enter it" 10 70
        step2
        fi
        if [ $($count) = 3 ];then dialog --msgbox "Please verify the IP address you entered" 10 50
        exit;fi
done

### STEP 3 ### // Detect if host is reachable
dialog --title "Backup utility - Step 3" \
        --pause "Verifying IP with an ICMP request ..." 10 70 1
ping -q -c1 $ip 2>&amp;amp;1 >/dev/null
if [ $? != 0 ]; then
        echo "host unreachable";exit
fi

### STEP 3bis ### // give a name to the backup folder
dialog --title "Backup utility - Step 4" \
        --inputbox "Give a name to this machine:" 0 0 2>/tmp/name.$$
read name </tmp/name.$$;rm -f /tmp/name.$$
if [ ! -d $BCK_DIR/$name ]; then
        mkdir -p $BCK_DIR/$name
else
        dialog --title "Backup utility - Step 4bis" \
                --msgbox "Directory already exist, continue" 10 70
fi
cd $BCK_DIR

### STEP 4 ### // Choose SSH key sharing method
dialog --title "Backup utility - Step 4" \
        --radiolist "To automate the backup process, we need to share SSH Key between hosts, please choose one:" 20 85 3 \
        "Script"        "Let this installer guide you" off \
        "Manual"        "Show you the actual SSH public key (copy/paste method)" off \
        "Done"  "Installer consider that you already have copied this key" ON 2>/tmp/ssh_method.$$
if [ $? != 0 ];then exit;fi
read ssh_method < /tmp/ssh_method.$$;rm -f /tmp/ssh_method.$$

### STEP 5-6 ### // Execute SSH choosen method
case "$ssh_method" in
        "Script")
                step5;step6;;
        "Manual")
                dialog --msgbox "Please put the statement below into the ~/.ssh/authorized_keys of the remote host\n\n
                $(cat ~/.ssh/id_rsa.pub)" 14 90;;
        "Done")
                ;;
esac

### STEP 7 ### // Presentation of default template
dialog --title "Backup utility - Step 7" \
        --msgbox "The default template will backup the following directories: \n
        /etc/\n /var/log/\n /root/.*\n \n\n Extra functionalities will be listed on the next screen" 14 70

### STEP 8 ### // Extra functionalities
dialog --title "Backup utility - Step 8" \
        --checklist "Select the functions that the server provides. Installer will detect configuration directories and databases backup paths" 20 85 7 \
        "Web"   "Web and Reverse Proxy servers (detect Apache only)" off \
        "Squid" "Proxy server" off \
        "SGBD"  "Database server (detect Oracle,MySQL,PostgreSQL and DB2)" off \
        "Mail"  "Zimbra server" off \
        "DNS"   "DNS server" off \
        "Application"   "Tomcat and JBoss detected" off \
        "Install"       "Fulfilment and PXE detected" off \
        "Sas"   "Sas server" off \
        "Switch"        "Switchs configuration" off 2>/tmp/extra.$$
#re-Format file
sed -e 's/"//g' -e 's/\ /\n/g' /tmp/extra.$$ >/tmp/extra_final.$$

### STEP 9 ### // Processing to backup
#based on ~/.screenrc configuration to split horizontaly the terminal
#screen -S program
#screen -S program -p 1 -X eval 'stuff "tail -f /tmp/rsync-default.log ^M^M^M"'
#screen -S program -p 0 -X eval 'stuff "dialog --title "Backup utility - Step 9"\
#                                               --msgbox "Processing to default backup ..." 10 40"'

DEFAULT_DIRS=(/etc /root /var/log)
#[ ! -d $DEST ] &amp;amp;&amp;amp; mkdir -p $DEST

# Redirect dialog commands input with substitution
dialog --title "Copy file" --gauge "Copying file..." 10 75 0 < <(
ndir=${#DEFAULT_DIRS[*]};
count=0
for file in "${DEFAULT_DIRS[@]}"; do
PERCENT=$(( 100*(++count)/ndir ))
cat <<EOF
XXX
$PERCENT
Copying files in "$file"...
XXX
EOF
        echo $file >>/var/log/messages
        rsync -avrultp root@$ip:$file ${BCK_DIR}/$name 2>&amp;amp;1 >/var/log/messages
done
)
