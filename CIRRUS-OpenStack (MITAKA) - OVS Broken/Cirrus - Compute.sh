#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

##################### SCRIPT CONFIGURATION
#CONFIGURE Below:
###
port0=eth0                      #Mangment Network
port1=eth1                      #Provider Network
MYGW=10.0.0.1                   #MANGMENT GW
MNGsubnetMASK="255.255.255.0"   #Subnet Netmask
mystackname="Cirrus-Compute1"   #Hostname
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
echo -en "                                         " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack Compute Auto Deployment   "
echo "                                                  Script by Mohamed Ashraf "
echo
echo
echo " -> Please run this script as root! "
echo " -> INSTALLS MITAKA ON Ubuntu 14.04 LTS"
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
##PROVIDER NETWORK
#auto $port1
#iface $port1 inet manual" > /etc/network/interfaces
#echo '        pre-up /sbin/ethtool -K $IFACE gro off
#        up ip link set dev $IFACE up
#        up ip link set $IFACE promisc on
#        down ip link set dev $IFACE down
#        down ip link set $IFACE promisc off' >> /etc/network/interfaces
#echo "[OK]"
#echo
#/etc/init.d/networking restart
#ifdown $port0 && ifup $port0
#ifdown $port1 && ifup $port1
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
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mNova\033[0m" ;echo " ############################"
echo
sleep 1
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install nova-compute -y
#cp /etc/nova/nova.conf /etc/nova/nova.conf.DEFAULT
echo
echo -en " Configuring Nova..."
sleep 1
echo "[DEFAULT]
reserved_host_memory_mb = 0
ram_allocation_ratio = 1.5
cpu_allocation_ratio = 16.0
disk_allocation_ratio = 1.0

my_ip = $MYIP
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
libvirt_use_virtio_for_bridges=True
verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
enabled_apis=ec2,osapi_compute,metadata
rpc_backend = rabbit
auth_strategy = keystone
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
instance_usage_audit = True
instance_usage_audit_period = hour
notify_on_state_change = vm_and_task_state
notification_driver = messagingv2

allow_resize_to_same_host = true
allow_migrate_to_same_host = true

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = equiinfra

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
password = equiinfra" > /etc/nova/nova.conf
echo "[OK]"
echo
echo -en " Configuring Virtualization Driver..."
sleep 1
testvir=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
if [ $testvir == 0 ]
then
echo "[DEFAULT]
compute_driver=libvirt.LibvirtDriver
[libvirt]
virt_type=qemu
" > /etc/nova/nova-compute.conf
else
echo "[DEFAULT]
compute_driver=libvirt.LibvirtDriver
[libvirt]
virt_type=kvm
" > /etc/nova/nova-compute.conf
fi
echo "[OK]"
echo
service nova-compute restart
rm -f /var/lib/nova/nova.sqlite
echo
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mNeutron\033[0m" ;echo " ############################"
echo
sleep 1
echo "--->> Preparing System Controls..."
sleep 1
echo
echo "net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
" >> /etc/sysctl.conf
sysctl -p
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install neutron-plugin-ml2 neutron-plugin-openvswitch-agent -y
echo
echo -en " Configuring Neutron Engine..."
sleep 1
#cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.DEFAULT
echo "[DEFAULT]
core_plugin = ml2
rpc_backend = rabbit
auth_strategy = keystone

[agent]
root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf

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
username = neutron
password = equiinfra

[matchmaker_redis]

[nova]

[oslo_concurrency]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = equiinfra

[oslo_policy]

[qos]

[quotas]

[ssl]" > /etc/neutron/neutron.conf
echo "[OK]"
echo
echo -en " Configuring Neutron L2 Plugin..."
sleep 1
#cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.DEFAULT
echo "[DEFAULT]

[ml2]
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = openvswitch,linuxbridge,l2population
extension_drivers = port_security

[ml2_type_flat]
flat_networks = provider

[ml2_type_geneve]

[ml2_type_gre]

[ml2_type_vlan]

[ml2_type_vxlan]
vni_ranges = 1:1000

[securitygroup]
enable_security_group = True
enable_ipset = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

[ovs]
local_ip = $MYIP
bridge_mappings = external:br-ex

[agent]
tunnel_types = vxlan
l2_population = true
" > /etc/neutron/plugins/ml2/ml2_conf.ini
echo "[OK]"
echo -en "--->> Configuring Open Vswitch..."
sleep 1
echo "[OK]"
echo
service openvswitch-switch restart
echo
echo -en "--->> Adding External Bridge..."
sleep 1
ovs-vsctl add-br br-ex
echo "[OK]"
echo
echo -en "--->> Mapping Bridge to Interface..."
sleep 1
ovs-vsctl add-port br-ex $port1
echo "[OK]"
echo
echo -en "--->> Disabling Generic Receive Offload (GRO)..."
sleep 1
ethtool -K $port1 gro off
echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
@reboot /sbin/ethtool -K $port1 gro off
" > /etc/cron.d/gro-off
echo
echo
service openvswitch-switch restart
service nova-compute restart
service neutron-plugin-openvswitch-agent restart
service neutron-ovs-cleanup restart
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mCeilometer\033[0m" ;echo " ############################"
sleep1
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install ceilometer-agent-compute -y
echo
echo -en " Configuring Ceilometer..."
sleep 1
#cp /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.DEFAULT
echo "[DEFAULT]
rpc_backend = rabbit
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

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = equiinfra

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
service ceilometer-agent-compute restart
service nova-compute restart
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
#service nova-compute restart
#service neutron-linuxbridge-agent restart
#service ceilometer-agent-compute restart
