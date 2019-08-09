#!/bin/bash
# 
function describe(){
echo "################################"
echo "author: Julien ESCOFFIER"
echo "contact: julien.escoffier@protonmail.com"
echo "website: https://nvko-it.com"
echo "date of creation: 18/05/2015"
echo "last update: 16/09/2015"
echo "script revision: 0.3"
echo "script function: Automated installation for Apache & MariaDB on CentOS 6/7"
echo -e "################################\n"
}

LOG_REDCT=/usr/local/src/lamp.log
RET_VAL_ECHO=`if [ $? -eq 0 ]; then echo "[OK]"; else echo "[FAILED] && exit 1"; fi`
HTTP_CONF=/etc/httpd/conf/httpd.conf

########### START MSG ################
describe
echo "This is an automated installation script for Apache & MariaDB"
echo -e "You can view logs in the file: $LOG_REDCT\n"
read -p "Press [ENTER] to start installation ..."

########### HTTPD PART ###############
echo -e "\n##### Starting HTTPD Installation #####" >> $LOG_REDCT
echo -en "\nApache pre-requisites Installation ..." 
yum install -y httpd php php-mysql>> $LOG_REDCT 2>&1
echo $RET_VAL_ECHO

#Configure Apache ServerName 

grep ^ServerName $HTTP_CONF 1>/dev/null
if [ $? -eq 0 ]; then
        echo -e "A ServerName already set\nPlease check your configuration => /etc/httpd/conf/httpd.conf"
else
        echo -n "Setting up ServerName = hostname ..."
	sed -i "/m:80/a ServerName $HOSTNAME" $HTTP_CONF
	echo $RET_VAL_ECHO
fi

#starting Apache server
echo -n "Starting Apache ..."
systemctl enable httpd >> $LOG_REDCT 2>&1
systemctl start httpd >> $LOG_REDCT 2>&1
echo $RET_VAL_ECHO

echo -e "\n##### Ending HTTPD Installation #####">> $LOG_REDCT

########### MySQL PART ###############
echo -e "\n##### Starting MariaDB Installation #####">> $LOG_REDCT
echo -n "MySQL pre-requisites Installation ..."
yum install -y mariadb mariadb-server >> $LOG_REDCT 2>&1
echo $RET_VAL_ECHO

#enable & start MariaDB
echo -n "Starting MySQL ..."
systemctl enable mariadb >> $LOG_REDCT 2>&1
systemctl start mariadb >> $LOG_REDCT 2>&1
echo $RET_VAL_ECHO

#Define MySQL Root password
echo -e "\nEnter new MySQL/MariaDB root Password: ";
stty -echo
read MYSQL_PASS;stty echo
mysqladmin -u root password $MYSQL_PASS

#MySQL Cleaning & droping test database
echo -ne "\nCleaning permissions & dropping non-useful database ..."
mysql -u root -p$MYSQL_PASS -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1')"
mysql -u root -p$MYSQL_PASS -e "DROP USER ''@'localhost'"
mysql -u root -p$MYSQL_PASS -e "DROP DATABASE test"
mysql -u root -p$MYSQL_PASS -e "FLUSH PRIVILEGES"
echo $RET_VAL_ECHO
echo -e "Installation Finished\n"
echo -e "\n##### Ending MariaDB Installation #####">> $LOG_REDCT
