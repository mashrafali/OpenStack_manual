#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

##################### SCRIPT CONFIGURATION
#CONFIGURE Below:
###
port0=ens192                    #Mangment Network
MYGW=10.0.0.1                   #MANGMENT GW
MNGsubnetMASK="255.255.255.0"   #Subnet Netmask
mystackname="Icarus-Block1"     #Hostname
cloudaka="Icarus"               #Cloud Code Name
mydomain="equinoxme.com"        #Cloud Domain Name
controllerip=10.0.0.11          #Controller Node IP
####################################################
echo
echo " DOES NOT NEED INIT SCRIPT"
echo "##### ADJUST HOSTS FILE WITHIN THE SCRIPT AS DESIRED BEFORE BOOTSTRAP <<"
echo "-> Hit enter to begin"
read
MYIP=$(ip addr | grep $port0 | grep inet | awk '{print $2}' | cut -d "/" -f1)
clear
echo
echo -en "                                         " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack Block Auto Deployment   "
echo "                                                  Script by Mohamed Ashraf "
echo
echo
echo " -> Please run this script as root! "
echo " -> INSTALLS OCATA ON RHEL 7.3"
echo
echo " Parameters INFO:"
echo "-----------------"
echo " - Mangment Network IP will be used from $port0 : $MYIP"
echo " - Block Backend will be used on /dev/sdb"
echo " - Manila Backend will be used on /dev/sdc"
echo " - Linking Object Node to Controller Node of IP : $controllerip"
echo
echo " >>>>> Hit Enter when you are Ready <<<<<"
read
sleep 2
echo " #################################### PREPARING SYSTEM ############################"
echo
sleep 1
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
rpm -Uvh https://www.mirrorservice.org/sites/dl.atrpms.net/src/el7-x86_64/atrpms/stable/atrpms-repo-7-7.src.rpm
rpm -Uvh http://repo.webtatic.com/yum/el7/webtatic-release.rpm
yum clean all
yum repolist
yum update -y
yum upgrade -y
yum install openssh openssh-server htop pydf unzip iftop make nano tcpdump gcc sudo dnsutils ntp ethtool nload fping nmap yum-utils net-tools wget telnet -y
yum install python-pip redhat-lsb-core -y
yum install open-vm-tools -y
pip install --upgrade pip
pip install pydf
systemctl disable firewalld
systemctl stop firewalld
systemctl disable iptables
systemctl stop iptables
systemctl disable NetworkManager
systemctl stop NetworkManager
sed -i 's/SELINUX=/SELINUX=disabled #/g' /etc/selinux/config
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
#sleep 1
#systemctl stop NetworkManager
#systemctl disable NetworkManager
#echo
#echo -en "Configuring Interfaces..."
#sleep 1
#echo "TYPE=Ethernet
#BOOTPROTO=static
#NAME=$port0
#DEVICE=$port0
#ONBOOT=yes
#IPADDR=$MYIP
#PREFIX=24
#GATEWAY=$MYGW
#DNS1=8.8.8.8
#DNS2=8.8.4.4" > /etc/sysconfig/network-scripts/ifcfg-$port0
###
#echo "[OK]"
#service network restart
#echo
#sleep 1
#ping -c1 $MYGW
#sleep 1
#echo
echo " #################################### Configuring Hosts Identification ############################"
echo
echo -en "Configuring Hosts File..."
echo "127.0.0.1       localhost.localdomain    localhost
$MYIP       block1.$mydomain block1


##### $cloudaka-OpenStack Nodes
# MANG
$controllerip       $cloudaka-Controller.$mydomain   $cloudaka-Controller  controller
10.0.0.31       $cloudaka-Compute1.$mydomain     $cloudaka-Compute1    compute1
$MYIP       $cloudaka-Block1.$mydomain       $cloudaka-Block1      block1
10.0.0.51       $cloudaka-Object1.$mydomain      $cloudaka-Object1     object1
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
yum install chrony -y
systemctl enable chronyd.service
systemctl start chronyd.service
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
rtconutc" > /etc/chrony.conf
sleep 1
echo "[OK]"
echo
service chronyd restart
sleep 1
chronyc sources
sleep 1
echo
echo " #################################### Linking OpenStack Packages ############################"
echo
echo "Disabling EXtra Repos..."
sleep 1
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/epel*
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/remi*
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/webtatic*
yum repolist
##
echo "## Building Required Packages..."
echo
sleep 1
wget https://rdoproject.org/repos/rdo-release.rpm
yum install rdo-release.rpm -y
rm rdo-release.rpm
yum upgrade
yum install python-openstackclient -y
yum install openstack-selinux -y
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mCinder\033[0m" ;echo " ############################"
echo
sleep 1
echo "--->> Installing LVM Packages..."
echo
sleep 1
yum install lvm2 -y
systemctl enable lvm2-lvmetad.service
systemctl start lvm2-lvmetad.service
echo
echo -en " Configuring LVM..."
#cp /etc/lvm/lvm.conf /etc/lvm/lvm.conf.DEFAULT
sleep 1
sed -i 's$# Configuration option devices/dir.$filter = [ "a/sdb/", "a/sdc/", "r/.*/"]$g' /etc/lvm/lvm.conf
echo "[OK]"
echo
pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb
echo
sleep 1
echo "--->> Installing Cinder Packages..."
echo
sleep 1
yum install openstack-cinder targetcli python-keystone -y
echo
echo -en " Configuring Cinder..."
sleep 1
#cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.DEFAULT
echo "[DEFAULT]
my_ip = $MYIP
enabled_backends = lvm
rootwrap_config = /etc/cinder/rootwrap.conf
api_paste_confg = /etc/cinder/api-paste.ini
iscsi_helper = tgtadm
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
auth_strategy = keystone
state_path = /var/lib/cinder
lock_path = /var/lock/cinder
volumes_dir = /var/lib/cinder/volumes
transport_url = rabbit://openstack:equiinfra@controller
auth_strategy = keystone
glance_api_servers = http://controller:9292

[database]
connection = mysql+pymysql://cinder:equiinfra@controller/cinder

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = equiinfra

[lvm]
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
iscsi_protocol = iscsi
iscsi_helper = lioadm
volume_clear_size=50
volume_clear=none
type=thin

[oslo_concurrency]
lock_path = /var/lib/cinder/tmp

[oslo_messaging_notifications]
driver = messagingv2" > /etc/cinder/cinder.conf
echo "[OK]"
echo
systemctl enable openstack-cinder-volume.service
systemctl enable target.service
systemctl start openstack-cinder-volume.service
systemctl start target.service
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mManila\033[0m" ;echo " ############################"
echo
echo "--->> Installing Packages..."
echo
sleep 1
### OPTION 1 WAS SELECTED TO EVADE NETWORKING ABUSE
yum install openstack-manila-share python2-PyMySQL -y
yum install lvm2 nfs-utils nfs4-acl-tools portmap -y
systemctl enable lvm2-lvmetad.service
systemctl start lvm2-lvmetad.service
echo
echo -en " Configuring Manila..."
sleep 1
#cp /etc/manila/manila.conf /etc/manila/manila.conf.DEFAULT
echo "[DEFAULT]
my_ip = $MYIP
transport_url = rabbit://openstack:equiinfra@controller
default_share_type = default_share_type
rootwrap_config = /etc/manila/rootwrap.conf
auth_strategy = keystone
enabled_share_backends = lvm
enabled_share_protocols = NFS

[cors]

[cors.subdomain]

[database]
connection = mysql+pymysql://manila:equiinfra@controller/manila

[keystone_authtoken]
memcached_servers = controller:11211
auth_uri = http://controller:5000
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = manila
password = equiinfra

[matchmaker_redis]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_concurrency]
lock_path = /var/lib/manila/tmp

[lvm]
share_backend_name = LVM
share_driver = manila.share.drivers.lvm.LVMShareDriver
driver_handles_share_servers = False
lvm_share_volume_group = manila-volumes
lvm_share_export_ip = $MYIP
" > /etc/manila/manila.conf
echo "[OK]"
echo
pvcreate /dev/sdc
vgcreate manila-volumes /dev/sdc
mkdir -p /var/lib/manila/
chown -R manila:manila /var/lib/manila/
echo
systemctl enable openstack-manila-share.service
systemctl enable target.service
systemctl start openstack-manila-share.service
systemctl start target.service
echo
echo -en " #################################### " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack IS READY ! ############################"
sleep 1
echo
echo " --> Before u begin using you have to do the following:"
echo " 1- Create Tenant & External Networks on $cloudaka-Controller ($controllerip)"
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
#service tgt restart
#service cinder-volume restart
#service manila-share restart
