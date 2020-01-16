#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

##################### SCRIPT CONFIGURATION
#CONFIGURE Below:
###
port0=ens192                    #Mangment Network
port1=ens224                    #Provider Network
MYGW=10.0.0.1                   #MANGMENT GW
MNGsubnetMASK="255.255.255.0"   #Subnet Netmask
mystackname="Icarus-Compute1"   #Hostname
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
echo -en "                                         " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack Compute Auto Deployment   "
echo "                                                  Script by Mohamed Ashraf "
echo
echo
echo " -> Please run this script as root! "
echo " -> INSTALLS OCATA ON RHEL 7.3"
echo
echo " Parameters INFO:"
echo "-----------------"
echo " - Mangment Network IP will be used from $port0 : $MYIP"
echo " - Provider Network will be attached to $port1"
echo " - Linking Compute Node to Controller Node of IP : $controllerip"
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
#echo "TYPE=Ethernet
#BOOTPROTO=none
#DEVICE=$port1
#ONBOOT=yes" > /etc/sysconfig/network-scripts/ifcfg-$port1
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
$MYIP       compute1.$mydomain   compute1


##### $cloudaka-OpenStack Nodes
# MANG
$controllerip       $cloudaka-Controller.$mydomain   $cloudaka-Controller  controller
$MYIP       $cloudaka-Compute1.$mydomain     $cloudaka-Compute1    compute1
10.0.0.41       $cloudaka-Block1.$mydomain       $cloudaka-Block1      block1
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
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mNova\033[0m" ;echo " ############################"
echo
sleep 1
echo "--->> Installing Packages..."
echo
sleep 1
yum install openstack-nova-compute -y
echo
echo -en " Configuring Nova..."
sleep 1
echo "[DEFAULT]
reserved_host_memory_mb = 0
ram_allocation_ratio = 1.5
cpu_allocation_ratio = 16.0
disk_allocation_ratio = 1.0

my_ip = $MYIP
logdir=/var/log/nova
enabled_apis=osapi_compute,metadata
transport_url = rabbit://openstack:equiinfra@controller
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
instance_usage_audit = True
instance_usage_audit_period = hour
notify_on_state_change = vm_and_task_state

[api]
auth_strategy = keystone

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = equiinfra

[vnc]
enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = $MYIP
novncproxy_base_url = http://$controllerip:6080/vnc_auto.html

[glance]
api_servers = http://controller:9292

[oslo_concurrency]
lock_path = /var/lib/nova/tmp

[neutron]
url = http://controller:9696
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = equiinfra

[placement]
os_region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:35357/v3
username = placement
password = equiinfra

[oslo_messaging_notifications]
driver = messagingv2" > /etc/nova/nova.conf
echo "[OK]"
echo
echo -en " Configuring Virtualization Driver..."
sleep 1
testvir=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
if [ $testvir == 0 ]
then
echo "
[libvirt]
virt_type=qemu
" >> /etc/nova/nova.conf
else
echo "
[libvirt]
virt_type=kvm
" >> /etc/nova/nova.conf
fi
echo "[OK]"
echo
systemctl enable libvirtd.service
systemctl enable openstack-nova-compute.service
systemctl start libvirtd.service
systemctl start openstack-nova-compute.service
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mNeutron\033[0m" ;echo " ############################"
echo
sleep 1
#
#echo "--->> Preparing System Controls..."
#sleep 1
#echo
#echo "net.ipv4.conf.all.rp_filter=0
#net.ipv4.conf.default.rp_filter=0
#net.bridge.bridge-nf-call-iptables=1
#net.bridge.bridge-nf-call-ip6tables=1
#" >> /etc/sysctl.conf
#sysctl -p
#echo
#
echo "--->> Installing Packages..."
echo
sleep 1
yum install openstack-neutron-linuxbridge ebtables ipset -y
echo
echo -en " Configuring Neutron Engine..."
sleep 1
#cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.DEFAULT
echo "[DEFAULT]
core_plugin = ml2
transport_url = rabbit://openstack:equiinfra@controller
auth_strategy = keystone

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = equiinfra

[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
" > /etc/neutron/neutron.conf
echo "[OK]"
echo
echo -en " Configuring the Linux bridge agent..."
sleep 1
#cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.DEFAULT
echo "[DEFAULT]

[agent]

[linux_bridge]
physical_interface_mappings = provider:$port1

[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

[vxlan]
enable_vxlan = True
local_ip = $MYIP
l2_population = True" > /etc/neutron/plugins/ml2/linuxbridge_agent.ini
echo "[OK]"
echo
systemctl restart openstack-nova-compute.service
systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mCeilometer\033[0m" ;echo " ############################"
sleep1
echo
echo "--->> Installing Packages..."
echo
sleep 1
yum install openstack-ceilometer-compute -y
echo
echo -en " Configuring Ceilometer..."
sleep 1
#cp /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.DEFAULT
echo "[DEFAULT]
transport_url = rabbit://openstack:equiinfra@controller
auth_strategy = keystone

[cors]

[cors.subdomain]

[database]

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = ceilometer
password = equiinfra

[matchmaker_redis]

[oslo_concurrency]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_policy]

[service_credentials]
auth_type = password
auth_url = http://controller:5000/v3
project_domain_name = default
user_domain_name = default
project_name = service
username = ceilometer
password = equiinfra
interface = internalURL
region_name = RegionOne" > /etc/ceilometer/ceilometer.conf
echo "[OK]"
echo
echo "--->> Finalizing Ceilometer Installation..."
echo
sleep 1
systemctl enable openstack-ceilometer-compute.service
systemctl start openstack-ceilometer-compute.service
systemctl restart openstack-nova-compute.service
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
#service nova-compute restart
#service neutron-linuxbridge-agent restart
#service ceilometer-agent-compute restart
