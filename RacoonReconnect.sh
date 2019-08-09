#!/bin/bash
# 
# author: Julien ESCOFFIER
# contact: julien.escoffier@protonmail.com
# website: https://nvko-it.com
# script revision: 0.2
# script function: execute manual restart of select vpn 
# added packages: dialog

# Permit to exit program with Ctrl-C
trap kill_yiiiaaa SIGINT

WORK_DIR=/etc/racoon

#put the name of all vpn into file and count how many there are
ls $WORK_DIR |grep -i .conf |grep -v '.old\|setkey\|racoon'|awk -F. '{print $1}' |uniq >>/tmp/list.$$
total_line=`wc -l /tmp/list.$$|awk '{print $1}'`

#create a file with "off" repeted $total_line time
for ((i=0; i<$total_line; i++)); do
        echo "off" >>/tmp/off.$$
done

#merge the 3 necessary columns for dialog radiolist
cp /tmp/list.$$ /tmp/list2.$$
paste /tmp/list.$$ /tmp/list2.$$ /tmp/off.$$ >>/tmp/final.$$

#replace tabs by space
sed -e 's/[\t]/ /g' /tmp/final.$$

#put whole merged lines into a single one
for line in `cat /tmp/final.$$`; do
        echo -n $line" " >> /tmp/vpn.$$
done

rm -f /tmp/list* /tmp/off.$$ /tmp/final.$$

vpn_list=$(cat /tmp/vpn.$$)

#count number of space in the file
count_space=$(fgrep -o " " /tmp/vpn.$$)

#print the dialogbox with a radiolist choice
echo $vpn_list|xargs dialog --title "VPN restart - Step 1" \
        --radiolist "list: " 0 0 0 2>/tmp/result.$$
sed -i 's/"//g' /tmp/result.$$
rm -f /tmp/vpn.$$

remote_ip=`cat $WORK_DIR/$(cat /tmp/result.$$).conf |grep -i ^remote |awk '{print $2}'`

>~/.screenrc
cat << EOF > ~/.screenrc
startup_message off
screen -t "logs of $remote_ip" sh -c "tail -f /var/log/messages |grep -i $remote_ip"
split
focus down
screen -t "main" sh -c "dialog --title \"VPN restart - Step 2\" --msgbox \"ACCEPT to restart $(cat /tmp/result.$$) VPN\" 10 70;for ((count=1; count<3; count++)); do nohup racoonctl vd $remote_ip >/dev/null 2>1\&amp;amp;;echo \"restart in progress ...\";sleep 2;done;nohup racoonctl vc $remote_ip >/dev/null 2>1\&amp;amp;;echo \"VPN restarted\";sleep 3;screen -X -p 0 stuff $'&amp;#92;&amp;#48;03'"
EOF
screen
clear
>~/.screenrc
