#!/bin/bash

function installVPN(){
	echo "begin to install VPN services";
	#check wether vps suppot ppp and tun
        tar zxf vpn.tar.gz
        cd vpn
	
	yum remove -y pptpd ppp
	iptables --flush POSTROUTING --table nat
	iptables --flush FORWARD
	rm -rf /etc/pptpd.conf
	rm -rf /etc/ppp
	
	arch=`uname -m`
	
#	wget http://www.hi-vps.com/downloads/dkms-2.0.17.5-1.noarch.rpm
#	wget http://wty.name/linux/sources/kernel_ppp_mppe-1.0.2-3dkms.noarch.rpm
#	wget http://www.hi-vps.com/downloads/kernel_ppp_mppe-1.0.2-3dkms.noarch.rpm
#	wget http://www.hi-vps.com/downloads/pptpd-1.3.4-2.el6.$arch.rpm
#	wget http://www.hi-vps.com/downloads/ppp-2.4.5-17.0.rhel6.$arch.rpm


	yum -y install make libpcap iptables gcc-c++ logrotate tar cpio perl pam tcp_wrappers
	rpm -ivh dkms-2.0.17.5-1.noarch.rpm
	rpm -ivh kernel_ppp_mppe-1.0.2-3dkms.noarch.rpm
	rpm -qa kernel_ppp_mppe
	rpm -Uvh ppp-2.4.5-17.0.rhel6.$arch.rpm	
	rpm -ivh pptpd-1.3.4-2.el6.$arch.rpm
	
	cd ..
	rm -rf vpn

	mknod /dev/ppp c 108 0 
	echo 1 > /proc/sys/net/ipv4/ip_forward 
	echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
	echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
	echo "localip 172.16.36.1" >> /etc/pptpd.conf
	echo "remoteip 172.16.36.2-254" >> /etc/pptpd.conf
	echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
	echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd

	pass=`openssl rand 6 -base64`
	if [ "$1" != "" ]
	then pass=$1
	fi

	echo "vpn pptpd ${pass} *" >> /etc/ppp/chap-secrets

	iptables -t nat -A POSTROUTING -s 172.16.36.0/24 -j SNAT --to-source `ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk 'NR==1 { print $1}'`
	iptables -A FORWARD -p tcp --syn -s 172.16.36.0/24 -j TCPMSS --set-mss 1356
	service iptables save

	chkconfig iptables on
	chkconfig pptpd on

	service iptables start
	service pptpd start

	echo "VPN service is installed, your VPN username is vpn, VPN password is ${pass}"
	
}

function repaireVPN(){
	echo "begin to repaire VPN";
	mknod /dev/ppp c 108 0
        sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1 /g' /etc/sysctl.conf
        sed -i 's/net.ipv4.tcp_syncookies = 1/#net.ipv4.tcp_syncookies = 1 /g' /etc/sysctl.conf
	iptables -t nat -A POSTROUTING -s 172.16.36.0/24 -j SNAT --to-source `ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk 'NR==1 { print $1}'`
#        iptables -t nat -A POSTROUTING -s 172.16.36.0/24 -j SNAT --to-source 122.10.94.227
    	service iptables restart
	/etc/init.d/pptpd stop
        service pptpd start
}

function addVPNuser(){
	echo "input user name:"
	read username
	echo "input password:"
	read userpassword
	echo "${username} pptpd ${userpassword} *" >> /etc/ppp/chap-secrets
	service iptables restart
	service pptpd start
	yum install iptables-services
}
function VPNpass(){
        cat /etc/ppp/chap-secrets
       }
echo "which do you want to?input the number."
echo "1. install VPN service"
echo "2. repaire VPN service"
echo "3. add VPN user"
echo "4.VPN pass"
read num

case "$num" in
[1] ) (installVPN);;
[2] ) (repaireVPN);;
[3] ) (addVPNuser);;
[4] ) (VPNpass);;
*) echo "nothing,exit";;
esac
