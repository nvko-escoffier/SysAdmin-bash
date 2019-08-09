Set of bash scripts for daily SysAdmin tasks

* [DockerAndCompose.sh](https://github.com/nvko-escoffier/SysAdmin-bash/blob/master/DockerAndCompose.sh): Installation with menu for docker and/or compose (curr. Debian only)
* [BckRemoteServer.sh](https://github.com/nvko-escoffier/SysAdmin-bash/blob/master/BckRemoteServer.sh): Backup a remote server without using third party software (using ssh-keys)
* [LampCentos.sh](https://github.com/nvko-escoffier/SysAdmin-bash/blob/master/LampCentos.sh): Automated installation of LAMP (Apache / MySQL / php) on Centos 6 or 7
* [RacoonReconnect.sh](https://github.com/nvko-escoffier/SysAdmin-bash/blob/master/RacoonReconnect.sh): Dialog interface in order to restart selected Racoon VPN phase
* [AdminShareListing.sh](https://github.com/nvko-escoffier/SysAdmin-bash/blob/master/AdminShareListing.sh): List the administratives shares over a network, then output to a file
* [Icinga2AddWindowsHost.sh](https://github.com/nvko-escoffier/SysAdmin-bash/blob/master/Icinga2AddWindowsHost.sh): Add a Windows host to an existing Icinga2 instance. 
* [Icinga2AddLinuxHost.sh](https://github.com/nvko-escoffier/SysAdmin-bash/blob/master/Icinga2AddLinuxHost.sh): Automatically add a new Linux host to the icinga server configuration. Additional tasks needs to be done on the client side, please CHECK instruction bellow


***

# Icinga2AddLinuxHost

Automatically add a new Linux host to the icinga server configuration.<br>
Additional tasks needs to be done on the client side.<br>

# 1. Server side
```bash
root@localhost:# icinga2 pki ticket --cn 'NODENAME.FQDN'
root@localhost:# chmod +x ~/.Icinga2AddLinuxHost.sh
root@localhost:# bash ~/.Icinga2AddLinuxHost.sh
<FOLLOW INSTRUCTIONS>
```

# 2. Client side
## 2.1 Pre-requisites
### Linux - Debian 9
```bash
wget -O - https://packages.icinga.com/icinga.key | apt-key add -
echo "deb http://packages.icinga.com/debian icinga-$(lsb_release -sc) main" | tee /etc/apt/sources.list.d/icinga2.list
echo "deb-src http://packages.icinga.com/debian icinga-$(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/icinga2.list
apt-get update
apt-get install -y icinga2 vim-icinga2 vim-addon-manager
vim-addon-manager -w install icinga2
apt-get install -y monitoring-plugins
```

### Linux - Centos 5
```bash
yum install -y epel-release
rpm --import http://packages.icinga.com/icinga.key
curl -o /etc/yum.repos.d/ICINGA-release.repo http://packages.icinga.com/epel/ICINGA-release.repo
yum makecache
yum install -y icinga2 nagios-plugins-all
chkconfig icinga2 on
/etc/init.d/icinga2 start 
```

### Linux - Centos 6
```bash
yum install -y epel-release
yum install -y https://packages.icinga.com/epel/icinga-rpm-release-6-latest.noarch.rpm
yum install -y icinga2
chkconfig icinga2 on
service icinga2 start
yum install -y nagios-plugins-all
```

### Linux - Centos 7
```bash
yum install -y epel-release
rpm --import https://packages.icinga.com/icinga.key
yum -y install https://packages.icinga.com/epel/icinga-rpm-release-7-latest.noarch.rpm
yum install icinga2 -y
systemctl enable icinga2
systemctl start icinga2
yum install -y nagios-plugins-all
```

## 2.2 Node wizard
This step will be automated through ansible.
```bash
root@localhost:# icinga2 node wizard
```

# 3. Last task
client side: restart icinga2
server side: reload icinga2
