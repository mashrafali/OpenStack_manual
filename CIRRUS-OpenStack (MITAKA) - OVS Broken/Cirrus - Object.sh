#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

##################### SCRIPT CONFIGURATION
#CONFIGURE Below:
###
port0=eth0                      #Mangment Network
MYGW=10.0.0.1                   #MANGMENT GW
MNGsubnetMASK="255.255.255.0"   #Subnet Netmask
mystackname="Cirrus-Object1"    #Hostname
cloudaka="Cirrus"               #Cloud Code Name
mydomain="equinoxme.com"        #Cloud Domain Name
controllerip=10.0.0.11          #Controller Node IP
####################################################
echo "##### ADJUST HOSTS FILE WITHIN THE SCRIPT AS DESIRED BEFORE BOOTSTRAP <<"
echo "-> Hit enter to begin"
read
MYIP=$(ifconfig $port0 | grep -i "inet addr:" | awk -F '[/:]' '{print $2}' | awk -F '[/ ]' '{print $1}')
clear
echo
echo -en "                                         " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack Object Auto Deployment   "
echo "                                                  Script by Mohamed Ashraf "
echo
echo
echo " -> Please run this script as root! "
echo " -> INSTALLS MITAKA ON Ubuntu 14.04 LTS"
echo
echo " Parameters INFO:"
echo "-----------------"
echo " - Mangment Network IP will be used from $port0 : $MYIP"
echo " - Object Backends will be used on /dev/sdb & /dev/sdc"
echo " - Linking Object Node to Controller Node of IP : $controllerip"
echo
echo " >>>>> Hit Enter when you are Ready <<<<<"
read
sleep 2
echo " #################################### PREPARING SYSTEM ############################"
sleep 1
echo
sleep 1
apt-get update
apt-get dist-upgrade -y
apt-get upgrade -y
apt-get --purge autoremove -y
apt-get autoclean
apt-get install ssh htop pydf unzip iftop snmpd snmp make nano tcpdump gcc sudo dnsutils ntp ethtool nload fping nmap git -y
apt-get dist-upgrade -y
apt-get upgrade -y
apt-get --purge autoremove -y
apt-get autoclean
echo
echo
echo " #################################### Optimizing Swap ####################################"
sleep 1
echo
echo " Configuring System Not to Swap unless to avoid System out of memory....."
sleep 2
echo
echo -en " "
echo "vm.swappiness = 0
vm.vfs_cache_pressure = 50
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
echo
sleep 2
echo " Configuration OK!"
echo
echo "
#Special Config Parameters For Fast SSH
UseDNS no
" >> /etc/ssh/sshd_config
echo
#echo " #################################### Configuring Interfaces  ############################"
#echo
#echo -en "Configuring Interfaces..."
#echo "# The loopback network interface
#auto lo
#iface lo inet loopback
#
## MANGMENT NETWORK
#auto $port0
#iface $port0 inet static
#        address $MYIP
#        netmask $MNGsubnetMASK
#        gateway $MYGW
#        dns-nameservers 8.8.8.8 8.8.4.4
#        dns-search $mydomain
#
#echo "[OK]"
#echo
#/etc/init.d/networking restart
#ifdown $port0 && ifup $port0
#sleep 1
#ping -c1 $MYGW
#sleep 1
#echo
echo " #################################### Configuring Hosts Identification ############################"
echo
echo -en "Configuring Hosts File..."
echo "127.0.0.1       localhost.localdomain    localhost
$MYIP       object1.$mydomain object1


##### $cloudaka-OpenStack Nodes
# MANG
$controllerip       $cloudaka-Controller.$mydomain   $cloudaka-Controller  controller
10.0.0.31       $cloudaka-Compute1.$mydomain     $cloudaka-Compute1    compute1
10.0.0.41       $cloudaka-Block1.$mydomain       $cloudaka-Block1      block1
$MYIP       $cloudaka-Object1.$mydomain      $cloudaka-Object1     object1
10.0.0.10       $cloudaka-ODL.$mydomain          $cloudaka-ODL         odl" > /etc/hosts
sleep 1
echo "[OK]"
echo
echo -en " Adjusting Hostname..."
sleep 1
hostname $mystackname
echo $mystackname > /etc/hostname
echo "[OK]"
echo
echo " #################################### Configuring NTP SYNC ############################"
echo
apt-get install chrony -y
echo
echo -en "Configuring NTP Server..."

echo "server controller iburst

keyfile /etc/chrony/chrony.keys
commandkey 1
driftfile /var/lib/chrony/chrony.drift
log tracking measurements statistics
logdir /var/log/chrony
maxupdateskew 100.0
dumponexit
dumpdir /var/lib/chrony
local stratum 10
allow 10/8
allow 192.168/16
allow 172.16/12
logchange 0.5
rtconutc" > /etc/chrony/chrony.conf
sleep 1
echo "[OK]"
echo
/etc/init.d/chrony restart
sleep 1
chronyc sources
sleep 1
echo
echo " #################################### Linking OpenStack Packages ############################"
echo
apt-get install software-properties-common -y
add-apt-repository cloud-archive:mitaka -y
apt-get update && apt-get dist-upgrade -y && apt-get upgrade -y && apt-get --purge autoremove -y && apt-get autoclean
echo "## Building Required Packages..."
echo
sleep 2
apt-get install python-openstackclient -y
echo
clear
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mSwift\033[0m" ;echo " ############################"
echo
sleep 1
echo "--->> Installing Disk Packages..."
echo
sleep 1
apt-get install xfsprogs rsync -y
echo
echo "--->> Preparing XFS Disks..."
echo
sleep 1
mkfs.xfs /dev/sdb
mkfs.xfs /dev/sdc
mkdir -p /srv/node/sdb
mkdir -p /srv/node/sdc
echo
echo " Creating Mount Points ..."
sleep 1
echo "
# SWIFT XFS DISKS
/dev/sdb /srv/node/sdb xfs noatime,nodiratime,nobarrier,logbufs=8 0 2
/dev/sdc /srv/node/sdc xfs noatime,nodiratime,nobarrier,logbufs=8 0 2
" >> /etc/fstab
echo "[OK]"
echo
mount /srv/node/sdb
mount /srv/node/sdc
echo -en " Configuring Rsync ..."
sleep 1
echo "uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = $MYIP

[account]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/account.lock

[container]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/container.lock

[object]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/object.lock" > /etc/rsyncd.conf
echo "[OK]"
echo
#cp /etc/default/rsync /etc/default/rsync.DEFAULT
echo "RSYNC_ENABLE=true
RSYNC_OPTS=''
RSYNC_NICE=''" > /etc/default/rsync
service rsync start
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install swift swift-account swift-container swift-object -y
curl -o /etc/swift/account-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/account-server.conf-sample?h=stable/mitaka
curl -o /etc/swift/container-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/container-server.conf-sample?h=stable/mitaka
curl -o /etc/swift/object-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/object-server.conf-sample?h=stable/mitaka
echo
echo -en " Configuring Swift..."
sleep 1
#cp /etc/swift/account-server.conf /etc/swift/account-server.conf.DEFAULT
#cp /etc/swift/container-server.conf /etc/swift/container-server.conf.DEFAULT
#cp /etc/swift/object-server.conf /etc/swift/object-server.conf.DEFAULT
echo "[DEFAULT]
bind_ip = $MYIP
bind_port = 6002
user = swift
swift_dir = /etc/swift
devices = /srv/node
mount_check = True

[pipeline:main]
pipeline = healthcheck recon account-server

[app:account-server]
use = egg:swift#account

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift

[account-replicator]

[account-auditor]

[account-reaper]

[filter:xprofile]
use = egg:swift#xprofile" > /etc/swift/account-server.conf
echo "[DEFAULT]
bind_ip = $MYIP
bind_port = 6001
user = swift
swift_dir = /etc/swift
devices = /srv/node
mount_check = True

[pipeline:main]
pipeline = healthcheck recon container-server

[app:container-server]
use = egg:swift#container

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift

[container-replicator]

[container-updater]

[container-auditor]

[container-sync]

[filter:xprofile]
use = egg:swift#xprofile" > /etc/swift/container-server.conf
echo "[DEFAULT]
bind_ip = $MYIP
bind_port = 6000
user = swift
swift_dir = /etc/swift
devices = /srv/node
mount_check = True

[pipeline:main]
pipeline = healthcheck recon object-server

[app:object-server]
use = egg:swift#object

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift
recon_lock_path = /var/lock

[object-replicator]

[object-reconstructor]

[object-updater]

[object-auditor]

[filter:xprofile]
use = egg:swift#xprofile" > /etc/swift/object-server.conf
echo "[OK]"
echo
chown -R swift:swift /etc/swift/
chown -R swift:swift /srv/node
mkdir -p /var/cache/swift
chown -R root:swift /var/cache/swift
chmod -R 775 /var/cache/swift
echo " --> Completing Swift Configuration..."
sleep 1
curl -o /etc/swift/swift.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/swift.conf-sample?h=stable/mitaka
#cp /etc/swift/swift.conf /etc/swift/swift.conf.DEFAULT
echo "[swift-hash]
swift_hash_path_suffix = equiinfra
swift_hash_path_prefix = equiinfra

[storage-policy:0]
name = Policy-0
default = yes
aliases = yellow, orange

[swift-constraints]" > /etc/swift/swift.conf
echo
chown -R root:swift /etc/swift
swift-init all start
echo
echo -en " #################################### " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack IS READY ! ############################"
sleep 1
echo
echo " --> Before u begin using you have to do the following:"
echo " 1- Edit and adjust /etc/hosts based on your nodes."
echo " 2- Create Tenant & External Networks on $cloudaka-Controller ($controllerip)"
echo
echo
echo
echo "                             !! The system will now reboot !! "
echo "                                  Hit Enter to Continue        "
read
echo
echo
reboot
echo

####Running Services :
#service chrony restart
#service rsync start
#service swift-account restart
#service swift-account-auditor restart
#service swift-account-reaper restart
#service swift-account-replicator restart
#service swift-container restart
#service swift-container-auditor restart
#service swift-container-replicator restart
#service swift-container-sync restart
#service swift-container-updater restart
#service swift-object restart
#service swift-object-auditor restart
#service swift-object-replicator restart
#service swift-object-updater restart
