#!/bin/sh

BASE=/home/INSTALL
cd ${BASE}
HOST=$1

result=`grep $HOST host-list.txt | wc -l`

if [ $result -gt 1 ]; then
	echo "Error: You must be more specific $HOST returned multiple results"
	exit
fi

#result=`grep $HOST host-list.txt`
#echo $result

fqdn=`grep $HOST host-list.txt | awk '{print tolower($1)}'`
echo fqdn:  $fqdn

ip=`grep $HOST host-list.txt | awk '{print $2}'`
echo IP: $ip

mask=`grep $HOST host-list.txt | awk '{print $3}'`
echo Netmask: $mask

gw=`grep $HOST host-list.txt | awk '{print $4}'`
echo GATEWAY: $gw

dns=`grep $HOST host-list.txt | awk '{print $5}'`
echo DNS: $dns

hostname=`grep $HOST host-list.txt | awk '{print tolower($1)}' | awk 'BEGIN { FS = "." } ; { print $1 }'`
echo HOSTNAME: $hostname
echo

read -p "You are about to provision this system as $fqdn, is this correct? [y/N]" answer

case $answer in
	[Yy]* ) echo "Continuing provisioning...";;
	* ) exit;;
esac


sed -e "{
s/#IP#/${ip}/ 
s/#GATEWAY#/${gw}/ 
s/#DNS#/${dns}/ 
s/#MASK#/${mask}/ 
}" /home/INSTALL/ifcfg-eth0.template > ${BASE}/ifcfg-eth0
cp -f ${BASE}/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0

sed -e "{
s/#GATEWAY#/${gw}/
s/#FQDN#/${fqdn}/
}" ${BASE}/network.template > ${BASE}/network
cp -f ${BASE}/network /etc/sysconfig/network

/etc/init.d/network restart 2>&1 | tee -a ${BASE}/provision.log

curl -o ito-stage2.tgz http://bhm-yum-m01.bhdc.att.com/src/ito-stage2.tgz 2>&1 | tee -a ${BASE}/provision.log
tar xzvf ito-stage2.tgz
cd ito-stage2

chmod +x s2-install.sh
./s2-install.sh ${hostname} 

