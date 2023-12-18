#!/bin/sh
#
# This install script will work only on Astra Linux 1.6 Special Edition (Smolensk)
# Version 2021-23.1
# 
if [ -z "$1" ]; then
	echo "Usage: 
	- install.sh <token>
		<token> - license token
	- install.sh remove
		Remove DCImanager"
	exit
fi

set -e

REPO='http://download.ispsystem.com/6/astra_se'
tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)

print(){
	echo -e "=====> \e[32m $1 \e[0m"
}

if [ "$1" = "remove" ]; then
	dci stop
	docker rm $(docker ps -a -q) > /dev/null
	docker rmi $(docker images -q) > /dev/null
	systemctl disable dci
	rm /lib/systemd/system/dci.service /usr/local/bin/dci /usr/local/bin/docker-compose
	apt autoremove --purge -y containerd runc docker.io 
	rm -rf /etc/docker/ /var/lib/docker/ /var/lib/containerd  /opt/ispsystem /opt/containerd /var/lib/mysql
else
	print "Installing wget & ca-certificates"
	apt install -y wget ca-certificates

	cd $tmp_dir
	print "Installing Exo-soft public key"
	wget $REPO/exo-soft_pub.key
	cat exo-soft_pub.key >> /sys/digsig/keys
	cp exo-soft_pub.key /etc/digsig/keys/
	update-initramfs -uk all

	print "Downloading docker packages"
	wget $REPO/docker-packages.tar.gz
	print "Unpacking docker packages"
	tar xzf docker-packages.tar.gz
	print "Installing docker packages"
	dpkg -i pkgs/*.deb

	print "Installing docker-compose"
	mkdir -p /opt/ispsystem
	wget $REPO/docker-compose.tar.gz
	tar xzf docker-compose.tar.gz -C /opt/ispsystem
	ln -sf /opt/ispsystem/docker-compose/bin/docker-compose /usr/local/bin/docker-compose

	print "Running DCImanager installation script"
	wget $REPO/dci/installer -O dci 
	chmod +x ./dci
	REPOSITORY_URL=$REPO/ ./dci install -l="$1"
fi
rm -rf $tmp_dir
