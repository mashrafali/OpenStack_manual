#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

##################### SCRIPT CONFIGURATION
#
#CONFIGURE USED PORTS:
###
port0=eth0                        #MANGMENT
port1=eth1                        #Provider Network
MYGW=10.0.0.1                     #MANGMENT GW
MNGsubnetCIDR="10.0.0.0/24"       #MANGMENT SUBNET
MNGsubnetMASK="255.255.255.0"     #Subnet Netmask
mystackname="Cirrus-Controller"   #Hostname
cloudaka="Cirrus"                 #Cloud Code Name
mydomain="equinoxme.com"          #Cloud Domain Name
COWBRINGER=10.0.0.100             #Cow Bringer Source VM
ProvNetStart=192.168.67.200       #Provider Network Allocation Start
ProvNetEnd=192.168.67.210         #Provider Network Allocation End
ProvNetGW=192.168.67.1            #Provider Network GW
ProvNetCIDR=192.168.67.0/24       #Provider Network CIDR
####################################################
echo
echo "##### ADJUST HOSTS FILE WITHIN THE SCRIPT AS DESIRED BEFORE BOOTSTRAP <<"
echo "-> Hit enter to begin"
read
MYIP=$(ifconfig $port0 | grep -i "inet addr:" | awk -F '[/:]' '{print $2}' | awk -F '[/ ]' '{print $1}')
clear
echo
echo -en "                                         " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack Controller Auto Deployment   "
echo "                                                  Script by Mohamed Ashraf "
echo
echo
echo " -> Please run this script as root! "
echo " -> INSTALLS MITAKA ON Ubuntu 14.04 LTS"
echo
echo " Parameters INFO:"
echo "-----------------"
echo " - Mangment Network IP will be used from $port0 : $MYIP"
echo " - Provider Network will be used on $port1"
echo " - My hostname is $mystackname"
echo
echo " >>>>> Hit Enter when you are Ready <<<<<"
read
sleep 2
echo " #################################### PREPARING SYSTEM ############################"
echo
sleep 1
apt-get update
apt-get dist-upgrade -y
apt-get upgrade -y
apt-get --purge autoremove -y
apt-get autoclean
apt-get install ssh htop pydf unzip iftop snmpd snmp make nano tcpdump gcc sudo dnsutils ntp ethtool nload fping nmap git -y
apt-get install open-vm-tools -y
apt-get install python-pip -y
apt-get dist-upgrade -y
apt-get upgrade -y
apt-get --purge autoremove -y
apt-get autoclean
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
$MYIP       controller.$mydomain controller


##### $cloudaka-OpenStack Nodes
# MANG
$MYIP       $cloudaka-Controller.$mydomain   $cloudaka-Controller  controller
10.0.0.31       $cloudaka-Compute1.$mydomain     $cloudaka-Compute1    compute1
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

echo "server 0.debian.pool.ntp.org iburst
server 1.debian.pool.ntp.org iburst
server 2.debian.pool.ntp.org iburst
server 3.debian.pool.ntp.org iburst

allow $MNGsubnetCIDR

keyfile /etc/chrony/chrony.keys
commandkey 1
driftfile /var/lib/chrony/chrony.drift
log tracking measurements statistics
logdir /var/log/chrony
maxupdateskew 100.0
dumponexit
dumpdir /var/lib/chrony
local stratum 10
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
echo " #################################### Installing System SQL DataBase ############################"
echo
echo "--->> Installing DataBase..."
echo
sleep 1
debconf-set-selections <<< 'mysql-server mysql-server/root_password password equiinfra'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password equiinfra'
apt-get install mariadb-server python-pymysql -y
echo
echo -en "Configuring DB for Openstack Parameters..."
echo "[mysqld]
bind-address = $MYIP
default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8" > /etc/mysql/conf.d/openstack.cnf
sleep 2
echo "[OK]"
echo
service mysql restart
service mysql status
echo
echo " #################################### Installing System noSQL DataBase ############################"
echo
apt-get install mongodb-server mongodb-clients python-pymongo -y
echo
echo -en "Configuring DB Parameters..."
echo "bind_ip = $MYIP
dbpath=/var/lib/mongodb
logpath=/var/log/mongodb/mongodb.log
logappend=true
journal=true
smallfiles = true" > /etc/mongodb.conf
sleep 2
echo "[OK]"
echo
service mongodb stop
rm /var/lib/mongodb/journal/prealloc.*
service mongodb start
sleep 1
echo
echo " #################################### Installing Message Queueing Services ############################"
echo
apt-get install rabbitmq-server -y
echo
rabbitmqctl add_user openstack equiinfra
sleep 1
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
echo
sleep 1
/etc/init.d/rabbitmq-server restart
/etc/init.d/rabbitmq-server status | head -9
sleep 2
echo
echo " #################################### Installing MemCached Services ############################"
echo
apt-get install memcached python-memcache -y
echo
echo -en "Configuring Cache..."
echo "-d
logfile /var/log/memcached.log
-m 1024
-p 11211
-u memcache
-l $MYIP" > /etc/memcached.conf
sleep 2
echo "[OK]"
service memcached restart
sleep 1
service memcached status
sleep 2
clear
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mKeyStone\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -pequiinfra -Bse "CREATE DATABASE keystone;"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'equiinfra';"
echo "[OK]"
echo
echo -en " Generating Admin Token..."
#token=$(openssl rand -hex 10)
token=equiinfra
sleep 1
echo "[OK]"
echo
echo -en " Disable Keystone AutoStart..."
sleep 1
echo "manual" > /etc/init/keystone.override
echo "[OK]"
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install keystone apache2 libapache2-mod-wsgi -y
echo
echo -en " Configuring Keystone..."
sleep 1
#cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.DEFAULT
echo "[DEFAULT]
log_dir = /var/log/keystone
admin_token = equiinfra

[assignment]

[auth]

[cache]

[catalog]

[cors]

[cors.subdomain]

[credential]

[database]
connection = mysql+pymysql://keystone:equiinfra@controller/keystone

[domain_config]

[endpoint_filter]

[endpoint_policy]

[eventlet_server]

[eventlet_server_ssl]

[federation]

[fernet_tokens]

[identity]

[identity_mapping]

[kvs]

[ldap]

[matchmaker_redis]

[memcache]
servers = $MYIP:11211

[oauth1]

[os_inherit]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

[oslo_middleware]

[oslo_policy]

[paste_deploy]

[policy]

[resource]

[revoke]

[role]

[saml]

[shadow_users]

[signing]

[ssl]

[token]
provider = fernet

[tokenless_auth]

[trust]

[extra_headers]
Distribution = Ubuntu" > /etc/keystone/keystone.conf
echo "[OK]"
echo
echo "--->> Populating Database..."
echo
sleep 1
su -s /bin/sh -c "keystone-manage db_sync" keystone
echo
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
echo
echo -en " Configuring Apache..."
sleep 1
echo "ServerName $mystackname" >> /etc/apache2/apache2.conf
echo 'Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>' > /etc/apache2/sites-available/wsgi-keystone.conf
echo "[OK]"
echo
echo -en " Enabling Virtual Hosts..."
ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled
sleep 1
echo "[OK]"
echo
service apache2 restart
rm -f /var/lib/keystone/keystone.db
echo
echo "--->> CREATING SERVICE ENTITY AND ENDPOINTS:"
echo
sleep 1
export OS_TOKEN=equiinfra
export OS_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
openstack service create --name keystone --description "OpenStack Identity" identity
openstack endpoint create --region RegionOne identity public http://controller:5000/v3
openstack endpoint create --region RegionOne identity internal http://controller:5000/v3
openstack endpoint create --region RegionOne identity admin http://controller:35357/v3
echo
echo "--->> CREATING PROJECTS AND USERS:"
echo
sleep 1
openstack domain create --description "Default Domain" default
openstack project create --domain default --description "Admin Project" admin
openstack user create --domain default --password equiinfra admin
openstack role create admin
openstack role add --project admin --user admin admin
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password demo demo
openstack role create user
openstack role add --project demo --user demo user
unset OS_TOKEN OS_URL
echo
echo -en " Creating environment scripts..."
sleep 1
echo "export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=equiinfra
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2" > /etc/keystone/admin-openrc.sh
echo "export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=demo
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2" > /etc/keystone/demo-openrc.sh
echo "[OK]"
echo
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mGlance\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -pequiinfra -Bse "CREATE DATABASE glance;"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'equiinfra';"
echo "[OK]"
echo
echo "--->> Configuring Service endpoints..."
echo
sleep 1
source /etc/keystone/admin-openrc.sh
openstack user create --domain default --password equiinfra glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install glance -y
echo

echo -en " Configuring Glance..."
sleep 1
#cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.DEFAULT
#cp /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.DEFAULT
echo "[DEFAULT]
rpc_backend = rabbit

[cors]

[cors.subdomain]

[database]
sqlite_db = /var/lib/glance/glance.sqlite
backend = sqlalchemy
connection = mysql+pymysql://glance:equiinfra@controller/glance

[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

[image_format]
disk_formats = ami,ari,aki,vhd,vmdk,raw,qcow2,vdi,iso,root-tar

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = equiinfra

[matchmaker_redis]

[oslo_concurrency]

[oslo_messaging_amqp]

[oslo_messaging_notifications]
driver = messagingv2

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = equiinfra

[oslo_policy]

[paste_deploy]
flavor = keystone

[profiler]

[store_type_location_strategy]

[task]

[taskflow_executor]" > /etc/glance/glance-api.conf
echo "[DEFAULT]
rpc_backend = rabbit

[database]
sqlite_db = /var/lib/glance/glance.sqlite
backend = sqlalchemy
connection = mysql+pymysql://glance:equiinfra@controller/glance

[glance_store]

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = equiinfra

[matchmaker_redis]

[oslo_messaging_amqp]

[oslo_messaging_notifications]
driver = messagingv2

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = equiinfra

[oslo_policy]

[paste_deploy]
flavor = keystone

[profiler]" > /etc/glance/glance-registry.conf
echo "[OK]"
echo
echo "--->> Populating Database..."
echo
sleep 1
su -s /bin/sh -c "glance-manage db_sync" glance
echo
service glance-registry restart
service glance-api restart
rm -f /var/lib/glance/glance.sqlite
echo
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mNova\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -pequiinfra -Bse "CREATE DATABASE nova_api;"
mysql -u root -pequiinfra -Bse "CREATE DATABASE nova;"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'equiinfra';"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'equiinfra';"
echo "[OK]"
echo
echo "--->> Configuring Service endpoints..."
echo
sleep 1
source /etc/keystone/admin-openrc.sh
openstack user create --domain default --password equiinfra nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1/%\(tenant_id\)s
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler -y
echo
echo -en " Configuring Nova..."
sleep 1
#cp /etc/nova/nova.conf /etc/nova/nova.conf.DEFAULT
echo "[DEFAULT]
my_ip = $MYIP
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
libvirt_use_virtio_for_bridges=True
verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
enabled_apis = osapi_compute,metadata
rpc_backend = rabbit
auth_strategy = keystone

[api_database]
connection = mysql+pymysql://nova:equiinfra@controller/nova_api

[database]
connection = mysql+pymysql://nova:equiinfra@controller/nova

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
vncserver_listen = $MYIP
vncserver_proxyclient_address = $MYIP

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
service_metadata_proxy = True
metadata_proxy_shared_secret = equiinfra

[cinder]
os_region_name = RegionOne" > /etc/nova/nova.conf
echo "[OK]"
echo
echo "--->> Populating Database..."
echo
sleep 1
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova
echo
service nova-api restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
rm -f /var/lib/nova/nova.sqlite
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mNeutron\033[0m" ;echo " ############################"
echo
sleep 1
echo "--->> Preparing System Controls..."
sleep 1
echo
echo "net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
" >> /etc/sysctl.conf
sysctl -p
echo -en " Preparing Database..."
sleep 1
mysql -u root -pequiinfra -Bse "CREATE DATABASE neutron;"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'equiinfra';"
echo "[OK]"
echo
echo "--->> Configuring Service endpoints..."
echo
sleep 1
source /etc/keystone/admin-openrc.sh
openstack user create --domain default --password equiinfra neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install neutron-server neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent -y
apt-get install neutron-vpn-agent neutron-lbaas-agent -y
echo
echo -en " Configuring Neutron Engine..."
sleep 1
#cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.DEFAULT
echo "[DEFAULT]
core_plugin = ml2
service_plugins = firewall,vpnaas,router,lbaas
allow_overlapping_ips = True
rpc_backend = rabbit
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True

[agent]
root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf

[cors]

[cors.subdomain]

[database]
connection = mysql+pymysql://neutron:equiinfra@controller/neutron

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

[service_providers]
service_provider=LOADBALANCER:Haproxy:neutron.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default
service_provider=VPN:openswan:neutron.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default

[matchmaker_redis]

[nova]
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = equiinfra

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
#cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.DEFAULT
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
echo
echo -en " Configuring Neutron FireWall as a Service Plugin..."
sleep 1
echo "[fwaas]
driver = neutron_fwaas.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver
enabled = True
" > /etc/neutron/fwaas_driver.ini
echo "[OK]"
echo
echo -en " Configuring Neutron LoadBalancer as a Service Plugin..."
sleep 1
echo "[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
device_driver = neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver

[haproxy]
" > /etc/neutron/lbaas_agent.ini
echo "[OK]"
#echo
#echo -en " Configuring the Linux bridge agent..."
#sleep 1
##cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.DEFAULT
#echo "[DEFAULT]
#
#[agent]
#
#[linux_bridge]
#physical_interface_mappings = provider:$port1
#
#[securitygroup]
#enable_security_group = True
#firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
#
#[vxlan]
#enable_vxlan = True
#local_ip = $MYIP
#l2_population = True" > /etc/neutron/plugins/ml2/linuxbridge_agent.ini
#echo "[OK]"


echo
echo -en " Configuring the layer-3 agent..."
sleep 1
#cp /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.DEFAULT
echo "[DEFAULT]

[AGENT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
external_network_bridge =
router_delete_namespaces = True

# The external_network_bridge option intentionally lacks a value
# to enable multiple external networks on a single agent" > /etc/neutron/l3_agent.ini
echo "[OK]"
echo
echo -en " Configuring the DHCP agent..."
sleep 1
#cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.DEFAULT
echo "[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = True
dnsmasq_config_file = /etc/neutron/dnsmasq-neutron.conf

[AGENT]" > /etc/neutron/dhcp_agent.ini
echo "[OK]"
echo
echo -en " Configuring Neutron MTU Plugin..."
sleep 1
echo "dhcp-option-force=26,1454
" > /etc/neutron/dnsmasq-neutron.conf
echo "[OK]"
pkill dnsmasq
echo
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
echo "[OK]"
echo
echo -en " Configuring the metadata agent..."
sleep 1
#cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.DEFAULT
echo "[DEFAULT]
nova_metadata_ip = controller
metadata_proxy_shared_secret = equiinfra

[AGENT]" > /etc/neutron/metadata_agent.ini
echo "[OK]"
echo
echo "--->> Populating Database..."
echo
sleep 1
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
echo
service neutron-plugin-openvswitch-agent restart
service neutron-ovs-cleanup restart
service nova-api restart
service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart
service neutron-lbaas-agent restart
service neutron-vpn-agent restart
service openvswitch-switch restart
sleep 2
neutron ext-list
sleep 1
neutron agent-list
sleep 2
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mHorizon\033[0m" ;echo " ############################"
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install openstack-dashboard -y
apt-get remove openstack-dashboard-ubuntu-theme -y
echo
echo -en " Configuring Horizon..."
sleep 1
#cp /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.DEFAULT
cat > /etc/openstack-dashboard/local_settings.py << 'EOF'
import os
from django.utils.translation import ugettext_lazy as _
from horizon.utils import secret_key
from openstack_dashboard import exceptions
from openstack_dashboard.settings import HORIZON_CONFIG
DEBUG = False
TEMPLATE_DEBUG = DEBUG
WEBROOT = '/'
LOCAL_PATH = os.path.dirname(os.path.abspath(__file__))
SECRET_KEY = secret_key.generate_or_read_from_file('/var/lib/openstack-dashboard/secret_key')
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': 'controller:11211',
    },
}
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
OPENSTACK_HOST = "controller"
OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "default"
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}
OPENSTACK_KEYSTONE_BACKEND = {
    'name': 'native',
    'can_edit_user': True,
    'can_edit_group': True,
    'can_edit_project': True,
    'can_edit_domain': True,
    'can_edit_role': True,
}
OPENSTACK_HYPERVISOR_FEATURES = {
    'can_set_mount_point': False,
    'can_set_password': False,
    'requires_keypair': False,
}
OPENSTACK_CINDER_FEATURES = {
    'enable_backup': False,
}
OPENSTACK_NEUTRON_NETWORK = {
    'enable_router': True,
    'enable_quotas': True,
    'enable_ipv6': True,
    'enable_distributed_router': False,
    'enable_ha_router': False,
    'enable_lb': True,
    'enable_firewall': True,
    'enable_vpn': True,
    'enable_fip_topology_check': True,
    'default_ipv4_subnet_pool_label': None,
    'default_ipv6_subnet_pool_label': None,
    'profile_support': None,
    'supported_provider_types': ['*'],
    'supported_vnic_types': ['*'],
}
OPENSTACK_HEAT_STACK = {
    'enable_user_pass': True,
}
IMAGE_CUSTOM_PROPERTY_TITLES = {
    "architecture": _("Architecture"),
    "kernel_id": _("Kernel ID"),
    "ramdisk_id": _("Ramdisk ID"),
    "image_state": _("Euca2ools state"),
    "project_id": _("Project ID"),
    "image_type": _("Image Type"),
}
IMAGE_RESERVED_CUSTOM_PROPERTIES = []
API_RESULT_LIMIT = 1000
API_RESULT_PAGE_SIZE = 20
SWIFT_FILE_TRANSFER_CHUNK_SIZE = 512 * 1024
DROPDOWN_MAX_ITEMS = 30
TIME_ZONE = "EET"
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'null': {
            'level': 'DEBUG',
            'class': 'logging.NullHandler',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django.db.backends': {
            'handlers': ['null'],
            'propagate': False,
        },
        'requests': {
            'handlers': ['null'],
            'propagate': False,
        },
        'horizon': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'openstack_dashboard': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'novaclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'cinderclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'keystoneclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'glanceclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'neutronclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'heatclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'ceilometerclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'swiftclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'openstack_auth': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'nose.plugins.manager': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'django': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'iso8601': {
            'handlers': ['null'],
            'propagate': False,
        },
        'scss': {
            'handlers': ['null'],
            'propagate': False,
        },
    },
}
SECURITY_GROUP_RULES = {
    'all_tcp': {
        'name': _('All TCP'),
        'ip_protocol': 'tcp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_udp': {
        'name': _('All UDP'),
        'ip_protocol': 'udp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_icmp': {
        'name': _('All ICMP'),
        'ip_protocol': 'icmp',
        'from_port': '-1',
        'to_port': '-1',
    },
    'ssh': {
        'name': 'SSH',
        'ip_protocol': 'tcp',
        'from_port': '22',
        'to_port': '22',
    },
    'smtp': {
        'name': 'SMTP',
        'ip_protocol': 'tcp',
        'from_port': '25',
        'to_port': '25',
    },
    'dns': {
        'name': 'DNS',
        'ip_protocol': 'tcp',
        'from_port': '53',
        'to_port': '53',
    },
    'http': {
        'name': 'HTTP',
        'ip_protocol': 'tcp',
        'from_port': '80',
        'to_port': '80',
    },
    'pop3': {
        'name': 'POP3',
        'ip_protocol': 'tcp',
        'from_port': '110',
        'to_port': '110',
    },
    'imap': {
        'name': 'IMAP',
        'ip_protocol': 'tcp',
        'from_port': '143',
        'to_port': '143',
    },
    'ldap': {
        'name': 'LDAP',
        'ip_protocol': 'tcp',
        'from_port': '389',
        'to_port': '389',
    },
    'https': {
        'name': 'HTTPS',
        'ip_protocol': 'tcp',
        'from_port': '443',
        'to_port': '443',
    },
    'smtps': {
        'name': 'SMTPS',
        'ip_protocol': 'tcp',
        'from_port': '465',
        'to_port': '465',
    },
    'imaps': {
        'name': 'IMAPS',
        'ip_protocol': 'tcp',
        'from_port': '993',
        'to_port': '993',
    },
    'pop3s': {
        'name': 'POP3S',
        'ip_protocol': 'tcp',
        'from_port': '995',
        'to_port': '995',
    },
    'ms_sql': {
        'name': 'MS SQL',
        'ip_protocol': 'tcp',
        'from_port': '1433',
        'to_port': '1433',
    },
    'mysql': {
        'name': 'MYSQL',
        'ip_protocol': 'tcp',
        'from_port': '3306',
        'to_port': '3306',
    },
    'rdp': {
        'name': 'RDP',
        'ip_protocol': 'tcp',
        'from_port': '3389',
        'to_port': '3389',
    },
}
REST_API_REQUIRED_SETTINGS = ['OPENSTACK_HYPERVISOR_FEATURES',
                              'LAUNCH_INSTANCE_DEFAULTS']
try:
  from ubuntu_theme import *
except ImportError:
  pass
WEBROOT='/horizon/'
COMPRESS_OFFLINE = True
ALLOWED_HOSTS = ['*', ]
EOF
echo "[OK]"
echo
echo -en " Configuring Apache..."
sleep 1
echo -en '<VirtualHost *:80>
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        RedirectMatch ^/$ /horizon/
</VirtualHost>
' > /etc/apache2/sites-available/000-default.conf
echo "[OK]"
echo
service apache2 reload
service apache2 restart
echo
echo "--->> Branding $cloudaka OpenStack..."
echo
sleep 1
wget -P /tmp/images http://$COWBRINGER/openstack-images/logo.png
wget -P /tmp/images http://$COWBRINGER/openstack-images/logo-splash.png
mv /usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo.png /usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo.png.BAK
mv /usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo-splash.png /usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo-splash.png.BAK
mv /tmp/images/logo.png /usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo.png
mv /tmp/images/logo-splash.png /usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo-splash.png
chown horizon:horizon /usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo.png
chown horizon:horizon /usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo-splash.png
echo
service apache2 reload
service apache2 restart
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mCinder\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -pequiinfra -Bse "CREATE DATABASE cinder;"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'equiinfra';"
echo "[OK]"
echo
echo "--->> Configuring Service endpoints..."
echo
sleep 1
source /etc/keystone/admin-openrc.sh
openstack user create --domain default --password equiinfra cinder
openstack role add --project service --user cinder admin
openstack service create --name cinder --description "OpenStack Block Storage" volume
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack endpoint create --region RegionOne volume public http://controller:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volume internal http://controller:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volume admin http://controller:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 public http://controller:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://controller:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://controller:8776/v2/%\(tenant_id\)s
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install cinder-api cinder-scheduler -y
echo
echo -en " Configuring Cinder..."
sleep 1
#cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.DEFAULT
echo "[DEFAULT]
my_ip = $MYIP
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
rpc_backend = rabbit
auth_strategy = keystone

[database]
connection = mysql+pymysql://cinder:equiinfra@controller/cinder

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
username = cinder
password = equiinfra

[oslo_concurrency]
lock_path = /var/lib/cinder/tmp

[oslo_messaging_notifications]
driver = messagingv2" > /etc/cinder/cinder.conf
echo "[OK]"
echo
echo "--->> Populating Database..."
echo
sleep 1
su -s /bin/sh -c "cinder-manage db sync" cinder
echo
service nova-api restart
service cinder-scheduler restart
service cinder-api restart
rm -f /var/lib/cinder/cinder.sqlite
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mManila\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -pequiinfra -Bse "CREATE DATABASE manila;"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON manila.* TO 'manila'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON manila.* TO 'manila'@'%' IDENTIFIED BY 'equiinfra';"
echo "[OK]"
echo
echo "--->> Configuring Service endpoints..."
echo
sleep 1
source /etc/keystone/admin-openrc.sh
openstack user create --domain default --password equiinfra manila
openstack role add --project service --user manila admin
openstack service create --name manila --description "OpenStack Shared File Systems" share
openstack service create --name manilav2 --description "OpenStack Shared File Systems" sharev2
openstack endpoint create --region RegionOne share public http://controller:8786/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne share internal http://controller:8786/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne share admin http://controller:8786/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne sharev2 public http://controller:8786/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne sharev2 internal http://controller:8786/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne sharev2 admin http://controller:8786/v2/%\(tenant_id\)s
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install manila-api manila-scheduler python-manilaclient -y
echo
echo -en " Configuring Manila..."
sleep 1
#cp /etc/manila/manila.conf /etc/manila/manila.conf.DEFAULT
echo "[DEFAULT]
my_ip = $MYIP
rpc_backend = rabbit
default_share_type = default_share_type
rootwrap_config = /etc/manila/rootwrap.conf
auth_strategy = keystone

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

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = equiinfra

[oslo_concurrency]
lock_path = /var/lib/manila/tmp" > /etc/manila/manila.conf
echo "[OK]"
echo
echo "--->> Populating Database..."
echo
sleep 1
su -s /bin/sh -c "manila-manage db sync" manila
echo
service manila-scheduler restart
service manila-api restart
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mSwift\033[0m" ;echo " ############################"
echo
echo "--->> Configuring Service endpoints..."
echo
sleep 1
source /etc/keystone/admin-openrc.sh
openstack user create --domain default --password equiinfra swift
openstack role add --project service --user swift admin
openstack service create --name swift --description "OpenStack Object Storage" object-store
openstack endpoint create --region RegionOne object-store public http://controller:8080/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region RegionOne object-store internal http://controller:8080/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region RegionOne object-store admin http://controller:8080/v1
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install swift swift-proxy python-swiftclient python-keystoneclient python-keystonemiddleware memcached -y
echo
echo -en " Configuring Swift..."
sleep 1
mkdir -p /etc/swift
curl -o /etc/swift/proxy-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/proxy-server.conf-sample?h=stable/mitaka
#cp /etc/swift/proxy-server.conf /etc/swift/proxy-server.conf.DEFAULT
echo "[DEFAULT]
bind_port = 8080
user = swift
swift_dir = /etc/swift

[pipeline:main]
pipeline = ceilometer catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server

[app:proxy-server]
use = egg:swift#proxy
account_autocreate = True

[filter:tempauth]
use = egg:swift#tempauth
user_admin_admin = admin .admin .reseller_admin
user_test_tester = testing .admin
user_test2_tester2 = testing2 .admin
user_test_tester3 = testing3
user_test5_tester5 = testing5 service

[filter:healthcheck]
use = egg:swift#healthcheck

[filter:cache]
use = egg:swift#memcache
memcache_servers = controller:11211

[filter:ratelimit]
use = egg:swift#ratelimit

[filter:domain_remap]
use = egg:swift#domain_remap

[filter:catch_errors]
use = egg:swift#catch_errors

[filter:cname_lookup]
use = egg:swift#cname_lookup

[filter:staticweb]
use = egg:swift#staticweb

[filter:tempurl]
use = egg:swift#tempurl

[filter:formpost]
use = egg:swift#formpost

[filter:name_check]
use = egg:swift#name_check

[filter:list-endpoints]
use = egg:swift#list_endpoints

[filter:proxy-logging]
use = egg:swift#proxy_logging

[filter:bulk]
use = egg:swift#bulk

[filter:slo]
use = egg:swift#slo

[filter:dlo]
use = egg:swift#dlo

[filter:container-quotas]
use = egg:swift#container_quotas

[filter:account-quotas]
use = egg:swift#account_quotas

[filter:gatekeeper]
use = egg:swift#gatekeeper

[filter:container_sync]
use = egg:swift#container_sync

[filter:xprofile]
use = egg:swift#xprofile

[filter:versioned_writes]
use = egg:swift#versioned_writes

[filter:keystoneauth]
use = egg:swift#keystoneauth
operator_roles = admin, user, ResellerAdmin

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = swift
password = equiinfra
delay_auth_decision = True

[filter:ceilometer]
paste.filter_factory = ceilometermiddleware.swift:filter_factory
control_exchange = swift
url = rabbit://openstack:equiinfra@controller:5672/
driver = messagingv2
topic = notifications
log_level = WARN" > /etc/swift/proxy-server.conf
echo "[OK]"
echo
chown -R swift:swift /etc/swift/
echo
echo "--> Creating Account Ring"
echo
sleep 1
cd /etc/swift
swift-ring-builder account.builder create 10 1 1
swift-ring-builder account.builder add --region 1 --zone 1 --ip 10.0.0.51 --port 6002 --device sdb --weight 100
swift-ring-builder account.builder add --region 1 --zone 1 --ip 10.0.0.51 --port 6002 --device sdc --weight 100
swift-ring-builder account.builder
swift-ring-builder account.builder rebalance
sleep 2
swift-ring-builder container.builder create 10 1 1
swift-ring-builder container.builder add --region 1 --zone 1 --ip 10.0.0.51 --port 6001 --device sdb --weight 100
swift-ring-builder container.builder add --region 1 --zone 1 --ip 10.0.0.51 --port 6001 --device sdc --weight 100
swift-ring-builder container.builder
swift-ring-builder container.builder rebalance
sleep 2
swift-ring-builder object.builder create 10 1 1
swift-ring-builder object.builder add --region 1 --zone 1 --ip 10.0.0.51 --port 6000 --device sdb --weight 100
swift-ring-builder object.builder add --region 1 --zone 1 --ip 10.0.0.51 --port 6000 --device sdc --weight 100
swift-ring-builder object.builder
swift-ring-builder object.builder rebalance
sleep 2
clear
echo ; echo ; echo " >>> I Need the SSH Root Password for Object Node : 10.0.0.51"
echo "-> Hit enter when you are ready"
read
echo ; echo
scp account.ring.gz container.ring.gz object.ring.gz root@10.0.0.51:/etc/swift
echo
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
service memcached restart
service swift-proxy restart
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mHeat\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -pequiinfra -Bse "CREATE DATABASE heat;"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY 'equiinfra';"
echo "[OK]"
echo
echo "--->> Configuring Service endpoints..."
echo
sleep 1
source /etc/keystone/admin-openrc.sh
openstack user create --domain default --password equiinfra heat
openstack role add --project service --user heat admin
openstack service create --name heat --description "Orchestration" orchestration
openstack service create --name heat-cfn --description "Orchestration"  cloudformation
openstack endpoint create --region RegionOne orchestration public http://controller:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne orchestration internal http://controller:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne orchestration admin http://controller:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne cloudformation public http://controller:8000/v1
openstack endpoint create --region RegionOne cloudformation internal http://controller:8000/v1
openstack endpoint create --region RegionOne cloudformation admin http://controller:8000/v1
openstack domain create --description "Stack projects and users" heat
openstack user create --domain heat --password equiinfra heat_domain_admin
openstack role add --domain heat --user-domain heat --user heat_domain_admin admin
openstack role create heat_stack_owner
openstack role add --project demo --user demo heat_stack_owner
openstack role create heat_stack_user
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install heat-api heat-api-cfn heat-engine -y
echo
echo -en " Configuring Heat..."
sleep 1
#cp /etc/heat/heat.conf /etc/heat/heat.conf.DEFAULT
echo "[DEFAULT]
rpc_backend = rabbit
heat_metadata_server_url = http://controller:8000
heat_waitcondition_server_url = http://controller:8000/v1/waitcondition
stack_domain_admin = heat_domain_admin
stack_domain_admin_password = equiinfra
stack_user_domain_name = heat

[cors]

[cors.subdomain]

[database]
connection = mysql+pymysql://heat:equiinfra@controller/heat

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = heat
password = equiinfra

[matchmaker_redis]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = equiinfra

[oslo_middleware]

[oslo_policy]

[ssl]

[trustee]
auth_plugin = password
auth_url = http://controller:35357
username = heat
password = equiinfra
user_domain_name = default

[clients_keystone]
auth_uri = http://controller:35357

[ec2authtoken]
auth_uri = http://controller:5000/v2.0" > /etc/heat/heat.conf
echo "[OK]"
echo
echo "--->> Populating Database..."
echo
sleep 1
su -s /bin/sh -c "heat-manage db_sync" heat
echo
service heat-api restart
service heat-api-cfn restart
service heat-engine restart
rm -f /var/lib/heat/heat.sqlite
echo
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mCeilometer\033[0m" ;echo " ############################"
echo
echo "--->> Configuring Ceilometer DataBase..."
echo
sleep 1
mongo --host controller --eval '
  db = db.getSiblingDB("ceilometer");
  db.addUser({user: "ceilometer",
  pwd: "equiinfra",
  roles: [ "readWrite", "dbAdmin" ]})'
echo
mysql -u root -pequiinfra -Bse "CREATE DATABASE aodh;"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'%' IDENTIFIED BY 'equiinfra';"
echo "--->> Configuring Service endpoints..."
echo
sleep 1
source /etc/keystone/admin-openrc.sh
openstack user create --domain default --password equiinfra ceilometer
openstack role add --project service --user ceilometer admin
openstack service create --name ceilometer --description "Telemetry" metering
openstack endpoint create --region RegionOne metering public http://controller:8777
openstack endpoint create --region RegionOne metering internal http://controller:8777
openstack endpoint create --region RegionOne metering admin http://controller:8777
openstack role create ResellerAdmin
openstack role add --project service --user ceilometer ResellerAdmin
openstack user create --domain default --password equiinfra aodh
openstack role add --project service --user aodh admin
openstack service create --name aodh --description "Telemetry" alarming
openstack endpoint create --region RegionOne alarming public http://controller:8042
openstack endpoint create --region RegionOne alarming internal http://controller:8042
openstack endpoint create --region RegionOne alarming admin http://controller:8042
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install ceilometer-api ceilometer-collector ceilometer-agent-central ceilometer-agent-notification python-ceilometerclient -y
apt-get install python-ceilometermiddleware -y
apt-get install aodh-api aodh-evaluator aodh-notifier aodh-listener aodh-expirer python-ceilometerclient -y
echo
echo -en " Configuring Ceilometer..."
sleep 1
#cp /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.DEFAULT
#cp /etc/aodh/aodh.conf /etc/aodh/aodh.conf.DEFAULT
#cp /etc/aodh/api_paste.ini /etc/aodh/api_paste.ini.DEFAULT
echo "[DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone

[cors]

[cors.subdomain]

[database]
connection = mongodb://ceilometer:equiinfra@controller:27017/ceilometer

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
echo "[DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone

[api]

[coordination]

[cors]

[cors.subdomain]

[database]
connection = mysql+pymysql://aodh:equiinfra@controller/aodh

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = aodh
password = equiinfra

[matchmaker_redis]

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
username = aodh
password = equiinfra
interface = internalURL
region_name = RegionOne" > /etc/aodh/aodh.conf
echo "[pipeline:main]
pipeline = cors request_id authtoken api-server

[app:api-server]
paste.app_factory = aodh.api.app:app_factory

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory
oslo_config_project = aodh

[filter:request_id]
paste.filter_factory = oslo_middleware:RequestId.factory

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = aodh" > /etc/aodh/api_paste.ini
echo "[OK]"
echo
echo "--->> Populating Database..."
echo
sleep 1
su -s /bin/sh -c "aodh-dbsync" aodh
echo
echo "--->> Finalizing Ceilometer Installation..."
echo
sleep 1
service ceilometer-agent-central restart
service ceilometer-agent-notification restart
service ceilometer-api restart
service ceilometer-collector restart
service glance-registry restart
service glance-api restart
service cinder-api restart
service cinder-scheduler restart
service swift-proxy restart
service aodh-api restart
service aodh-evaluator restart
service aodh-notifier restart
service aodh-listener restart
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mTrove\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -pequiinfra -Bse "CREATE DATABASE trove;"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON trove.* TO 'trove'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -pequiinfra -Bse "GRANT ALL PRIVILEGES ON trove.* TO 'trove'@'%' IDENTIFIED BY 'equiinfra';"
echo "[OK]"
echo
echo "--->> Configuring Service endpoints..."
echo
sleep 1
source /etc/keystone/admin-openrc.sh
openstack user create --domain default --password equiinfra trove
openstack role add --project service --user trove admin
openstack service create --name trove --description "Database" database
openstack endpoint create --region RegionOne database public http://controller:8779/v1.0/%\(tenant_id\)s
openstack endpoint create --region RegionOne database internal http://controller:8779/v1.0/%\(tenant_id\)s
openstack endpoint create --region RegionOne database admin http://controller:8779/v1.0/%\(tenant_id\)s
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install python-trove python-troveclient python-glanceclient trove-common trove-api trove-taskmanager trove-conductor -y
echo
echo -en " Configuring Heat..."
sleep 1
#cp /etc/trove/trove.conf /etc/trove/trove.conf.DEFAULT
#cp /etc/trove/trove-taskmanager.conf /etc/trove/trove-taskmanager.conf.DEFAULT
#cp /etc/trove/trove-conductor.conf /etc/trove/trove-conductor.conf.DEFAULT
echo "[DEFAULT]
add_addresses = True
auth_strategy = keystone
rpc_backend = rabbit
log_dir = /var/log/trove
trove_auth_url = http://controller:5000/v2.0
nova_compute_url = http://controller:8774/v2
cinder_url = http://controller:8776/v1
swift_url = http://controller:8080/v1/AUTH_
notifier_queue_hostname = controller
verbose = True
debug = False
bind_host = 0.0.0.0
bind_port = 8779
control_exchange = trove
db_api_implementation = "trove.db.sqlalchemy.api"
network_label_regex = ^NETWORK_LABEL$
trove_volume_support = True
block_device_mapping = vdb
device_path = /dev/vdb
max_accepted_volume_size = 10
max_instances_per_tenant = 5
max_volumes_per_tenant = 100
max_backups_per_tenant = 5
volume_time_out=30
http_get_rate = 200
http_post_rate = 200
http_put_rate = 200
http_delete_rate = 200
http_mgmt_post_rate = 200
trove_dns_support = False
dns_account_id = 123456
dns_auth_url = http://127.0.0.1:5000/v2.0
dns_username = user
dns_passkey = password
dns_ttl = 3600
dns_domain_name = 'trove.com.'
dns_domain_id = 11111111-1111-1111-1111-111111111111
dns_driver = trove.dns.designate.driver.DesignateDriver
dns_instance_entry_factory = trove.dns.designate.driver.DesignateInstanceEntryFactory
dns_endpoint_url = http://127.0.0.1/v1/
dns_service_type = dns
network_driver = trove.network.nova.NovaNetwork
default_neutron_networks =
taskmanager_queue = taskmanager
admin_roles = admin
agent_heartbeat_time = 10
agent_call_low_timeout = 5
agent_call_high_timeout = 150
reboot_time_out = 60
api_paste_config = /etc/trove/api-paste.ini

[database]
connection = mysql://trove:equiinfra@controller/trove
idle_timeout = 3600

[profiler]

[ssl]

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = equiinfra

[mysql]
root_on_create = False
tcp_ports = 3306
volume_support = True
device_path = /dev/vdb
ignore_users = os_admin, root
ignore_dbs = mysql, information_schema, performance_schema

[redis]
tcp_ports = 6379
volume_support = False

[cassandra]
tcp_ports = 7000, 7001, 9042, 9160
volume_support = True
device_path = /dev/vdb

[couchbase]
tcp_ports = 8091, 8092, 4369, 11209-11211, 21100-21199
volume_support = True
device_path = /dev/vdb

[mongodb]
tcp_ports = 2500, 27017
volume_support = True
device_path = /dev/vdb
num_config_servers_per_cluster = 1
num_query_routers_per_cluster = 1

[vertica]
tcp_ports = 5433, 5434, 22, 5444, 5450, 4803
udp_ports = 5433, 4803, 4804, 6453
volume_support = True
device_path = /dev/vdb
cluster_support = True
cluster_member_count = 3
api_strategy = trove.common.strategies.cluster.experimental.vertica.api.VerticaAPIStrategy

[cors]

[cors.subdomain]

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = trove
password = equiinfra" > /etc/trove/trove.conf
echo "[DEFAULT]
rpc_backend = rabbit
log_dir = /var/log/trove
trove_auth_url = http://controller:5000/v2.0
nova_compute_url = http://controller:8774/v2
cinder_url = http://controller:8776/v1
swift_url = http://controller:8080/v1/AUTH_
notifier_queue_hostname = controller
verbose = True
debug = False
update_status_on_fail = True
control_exchange = trove
db_api_implementation = trove.db.sqlalchemy.api
trove_volume_support = True
block_device_mapping = vdb
device_path = /dev/vdb
mount_point = /var/lib/mysql
volume_time_out=30
server_delete_time_out=480
use_nova_server_config_drive = True
nova_proxy_admin_user = admin
nova_proxy_admin_pass = equiinfra
nova_proxy_admin_tenant_name = service
taskmanager_manager = trove.taskmanager.manager.Manager
exists_notification_transformer = trove.extensions.mgmt.instances.models.NovaNotificationTransformer
exists_notification_ticks = 30
notification_service_id = mysql:2f3ff068-2bfb-4f70-9a9d-a6bb65bc084b
trove_dns_support = False
dns_account_id = 123456
dns_auth_url = http://127.0.0.1:5000/v2.0
dns_username = user
dns_passkey = password
dns_ttl = 3600
dns_domain_name = 'trove.com.'
dns_domain_id = 11111111-1111-1111-1111-111111111111
dns_driver = trove.dns.designate.driver.DesignateDriver
dns_instance_entry_factory = trove.dns.designate.driver.DesignateInstanceEntryFactory
dns_endpoint_url = http://127.0.0.1/v1/
dns_service_type = dns
network_driver = trove.network.nova.NovaNetwork
default_neutron_networks =
trove_security_groups_support = True
trove_security_group_rule_cidr = 0.0.0.0/0
agent_heartbeat_time = 10
agent_call_low_timeout = 5
agent_call_high_timeout = 150
agent_replication_snapshot_timeout = 36000
use_nova_server_volume = False
network_label_regex = ^private$
template_path = /etc/trove/templates/
pydev_debug = disabled

[database]
connection = mysql://trove:equiinfra@controller/trove
idle_timeout = 3600

[profiler]

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = equiinfra

[mysql]
tcp_ports = 3306
volume_support = True
device_path = /dev/vdb

[redis]
tcp_ports = 6379
volume_support = False

[cassandra]
tcp_ports = 7000, 7001, 9042, 9160
volume_support = True
device_path = /dev/vdb

[couchbase]
tcp_ports = 8091, 8092, 4369, 11209-11211, 21100-21199
volume_support = True
device_path = /dev/vdb

[mongodb]
volume_support = True
device_path = /dev/vdb

[vertica]
tcp_ports = 5433, 5434, 22, 5444, 5450, 4803
udp_ports = 5433, 4803, 4804, 6453
volume_support = True
device_path = /dev/vdb
mount_point = /var/lib/vertica
taskmanager_strategy = trove.common.strategies.cluster.experimental.vertica.taskmanager.VerticaTaskManagerStrategy" > /etc/trove/trove-taskmanager.conf
echo "[DEFAULT]
rpc_backend = rabbit
log_dir = /var/log/trove
trove_auth_url = http://controller:5000/v2.0
nova_compute_url = http://controller:8774/v2
cinder_url = http://controller:8776/v1
swift_url = http://controller:8080/v1/AUTH_
notifier_queue_hostname = controller
verbose = True
debug = False
connection = sqlite:////var/lib/trove/trove.sqlite
conductor_manager = trove.conductor.manager.Manager
control_exchange = trove

[profiler]

[database]
connection = mysql://trove:equiinfra@controller/trove

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = equiinfra" > /etc/trove/trove-conductor.conf
echo "rabbit_host = controller
rabbit_password = equiinfra
nova_proxy_admin_user = admin
nova_proxy_admin_pass = equiinfra
nova_proxy_admin_tenant_name = service
trove_auth_url = http://controller:35357/v2.0" > /etc/trove/trove-guestagent.conf
echo "[OK]"
echo
echo "--->> Populating Database..."
echo
sleep 1
su -s /bin/sh -c "trove-manage db_sync" trove
echo
echo "--->> Installing Trove Dashboard"
echo
sleep 1
#pip install -Iv trove-dashboard==7.0.0.0b2
pip install trove-dashboard
cp /usr/local/lib/python2.7/dist-packages/trove_dashboard/enabled/* /usr/share/openstack-dashboard/openstack_dashboard/local/enabled/
service apache2 restart
echo
echo "--->> Finalizing Trove Installation..."
echo
sleep 1
service trove-api restart
service trove-taskmanager restart
service trove-conductor restart
echo
echo
echo " #################################### $cloudaka Images Flavors Adjustment & Configuration ############################"
sleep 1
echo
echo
echo "--->> Configuring $cloudaka Image Flavors..."
source /etc/keystone/admin-openrc.sh
sleep 2
nova flavor-delete 1
nova flavor-delete 2
nova flavor-delete 3
nova flavor-delete 4
nova flavor-delete 5
nova flavor-create Standard.1x1 1 1024 10 1 --ephemeral 0 --swap 1024 --is-public True
nova flavor-create Standard.2x2 2 2048 20 2 --ephemeral 0 --swap 2048 --is-public True
nova flavor-create Standard.3x3 3 3072 30 3 --ephemeral 0 --swap 3072 --is-public True
nova flavor-create Standard.4x4 4 4096 40 4 --ephemeral 0 --swap 4096 --is-public True
nova flavor-create Standard.5x5 5 5120 50 5 --ephemeral 0 --swap 5120 --is-public True
nova flavor-create Standard.6x6 6 6144 60 6 --ephemeral 0 --swap 6144 --is-public True
nova flavor-create Standard.7x7 7 7168 70 7 --ephemeral 0 --swap 7168 --is-public True
nova flavor-create Standard.8x8 8 8192 80 8 --ephemeral 0 --swap 8192 --is-public True
nova flavor-create HighCPU.4x2 9 2048 40 4 --ephemeral 0 --swap 2048 --is-public True
nova flavor-create HighCPU.5x3 10 3072 50 5 --ephemeral 0 --swap 3072 --is-public True
nova flavor-create HighCPU.6x4 11 4096 60 6 --ephemeral 0 --swap 4096 --is-public True
nova flavor-create HighCPU.7x5 12 5120 70 7 --ephemeral 0 --swap 5120 --is-public True
nova flavor-create HighCPU.8x6 13 6144 80 8 --ephemeral 0 --swap 6144 --is-public True
nova flavor-create HighMEM.2x6 14 6144 60 2 --ephemeral 0 --swap 6144 --is-public True
nova flavor-create HighMEM.3x7 15 7168 70 3 --ephemeral 0 --swap 7168 --is-public True
nova flavor-create HighMEM.4x8 16 8192 80 4 --ephemeral 0 --swap 8192 --is-public True
nova flavor-create HighMEM.5x9 17 9216 90 5 --ephemeral 0 --swap 9216 --is-public True
nova flavor-create HighMEM.6x10 18 10240 100 6 --ephemeral 0 --swap 10240 --is-public True
nova flavor-create HighMEM.7x11 19 11264 110 7 --ephemeral 0 --swap 11264 --is-public True
nova flavor-create HighMEM.8x12 20 12288 120 8 --ephemeral 0 --swap 12288 --is-public True
nova flavor-create HighDISK.1x1 21 1024 60 1 --ephemeral 0 --swap 1024 --is-public True
nova flavor-create HighDISK.2x2 22 2048 70 2 --ephemeral 0 --swap 2048 --is-public True
nova flavor-create HighDISK.3x3 23 3072 80 3 --ephemeral 0 --swap 3072 --is-public True
nova flavor-create HighDISK.4x4 24 4096 90 4 --ephemeral 0 --swap 4096 --is-public True
nova flavor-create HighDISK.5x5 25 5120 100 5 --ephemeral 0 --swap 5120 --is-public True
nova flavor-create HighDISK.6x6 26 6144 110 6 --ephemeral 0 --swap 6144 --is-public True
nova flavor-create HighDISK.7x7 27 7168 120 7 --ephemeral 0 --swap 7168 --is-public True
nova flavor-create HighDISK.8x8 28 8192 130 8 --ephemeral 0 --swap 8192 --is-public True
nova flavor-create Tiny.1x512 29 512 5 1 --ephemeral 0 --swap 512 --is-public True
nova flavor-list
echo
echo " #################################### Fetching & Loading Operating Systems Images ############################"
echo
source /etc/keystone/admin-openrc.sh
mkdir -p /tmp/images
sleep 1
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mOS: Cirros\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/cirros-0.3.4-x86_64-disk.img
glance image-create --name "OS:Cirros-0.3.4" --file /tmp/images/cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mOS: CoreOS\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/coreos_production_openstack_image.img
glance image-create --name "OS:CoreOS-766.4" --file /tmp/images/coreos_production_openstack_image.img --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mOS: CentOS\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/CentOS-7-x86_64-GenericCloud.qcow2
glance image-create --name "OS:CentOS-7" --file /tmp/images/CentOS-7-x86_64-GenericCloud.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mOS: Fedora\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/Fedora-Cloud-Base-22-20150521.x86_64.qcow2
glance image-create --name "OS:Fedora-22" --file /tmp/images/Fedora-Cloud-Base-22-20150521.x86_64.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mOS: SUSE Linux Enterprise\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/SUSE_Linux_Enterprise_12.x86_64-0.0.1.qcow2
glance image-create --name "OS:SUSE-12" --file /tmp/images/SUSE_Linux_Enterprise_12.x86_64-0.0.1.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mOS: Open SUSE\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/openSUSE-13.2-OpenStack-Guest.x86_64-0.0.10-Build1.32.qcow2
glance image-create --name "OS:OpenSUSE-13.2" --file /tmp/images/openSUSE-13.2-OpenStack-Guest.x86_64-0.0.10-Build1.32.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mOS: Ubuntu\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/Ubuntu-precise-server-cloudimg-amd64-disk1.img
glance image-create --name "OS:Ubuntu-12.04" --file /tmp/images/Ubuntu-precise-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
wget -P /tmp/images http://$COWBRINGER/openstack-images/Ubuntu-trusty-server-cloudimg-amd64-disk1.img
glance image-create --name "OS:Ubuntu-14.04" --file /tmp/images/Ubuntu-trusty-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
wget -P /tmp/images http://$COWBRINGER/openstack-images/xenial-server-cloudimg-amd64-disk1.img
glance image-create --name "OS:Ubuntu-16.04" --file /tmp/images/xenial-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mOS: Debian\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/debian-8.2.0-openstack-amd64.qcow2
glance image-create --name "OS:Debian-8.2" --file /tmp/images/debian-8.2.0-openstack-amd64.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mOS: Red Hat EL\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/rhel-guest-image-7.0-20140506.1.x86_64.qcow2
glance image-create --name "OS:RHEL-7.0" --file /tmp/images/rhel-guest-image-7.0-20140506.1.x86_64.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mOS: Windows\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/windows-server-2012-r2.qcow2
glance image-create --name "OS:Windows-2012R2" --file /tmp/images/windows-server-2012-r2.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mApplication:Jenkins\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-jenkins-1.613-0-ubuntu-14.04.qcow
glance image-create --name "APP:Jenkins-1.613" --file /tmp/images/bitnami-jenkins-1.613-0-ubuntu-14.04.qcow --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mApplication:WordPress\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-wordpress-4.3.1-0-ubuntu-14.04.qcow2
glance image-create --name "APP:WordPress-4.3.1" --file /tmp/images/bitnami-wordpress-4.3.1-0-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mApplication:Joomla\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-joomla-3.4.4-1-ubuntu-14.04.qcow2
glance image-create --name "APP:Joomla-3.4.4" --file /tmp/images/bitnami-joomla-3.4.4-1-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mApplication:Redmine\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-redmine-3.1.1-1-ubuntu-14.04.qcow2
glance image-create --name "APP:Redmine-3.1.1" --file /tmp/images/bitnami-redmine-3.1.1-1-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mApplication:MediaWiki\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-mediawiki-1.25.2-1-ubuntu-14.04.qcow2
glance image-create --name "APP:MediaWiki-1.25.2" --file /tmp/images/bitnami-mediawiki-1.25.2-1-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mApplication:SugarCRM\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-sugarcrm-6.5.22-1-ubuntu-14.04.qcow2
glance image-create --name "APP:SugarCRM-6.5.22" --file /tmp/images/bitnami-sugarcrm-6.5.22-1-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mApplication:OpenERP\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-openerp-7.0-19-ubuntu-14.04.qcow2
glance image-create --name "APP:OpenERP-7.0" --file /tmp/images/bitnami-openerp-7.0-19-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mApplication:GitLab\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-gitlab-7.14.3-1-ubuntu-14.04.qcow2
glance image-create --name "APP:GitLab-7.14.3" --file /tmp/images/bitnami-gitlab-7.14.3-1-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mApplication:Drupal\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-drupal-7.40-0-ubuntu-14.04.qcow2
glance image-create --name "APP:Drupal-7.40" --file /tmp/images/bitnami-drupal-7.40-0-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mApplication:Alfresco\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-alfresco-5.0.d-0-ubuntu-14.04.qcow2
glance image-create --name "APP:Alfresco-5.0.d" --file /tmp/images/bitnami-alfresco-5.0.d-0-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mApplication:Piwik\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-piwik-2.14.3-1-ubuntu-14.04.qcow2
glance image-create --name "APP:Piwik-2.14.3" --file /tmp/images/bitnami-piwik-2.14.3-1-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mApplication:OpenProject\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-openproject-4.2.6-1-ubuntu-14.04.qcow2
glance image-create --name "APP:OpenProject-4.2.6" --file /tmp/images/bitnami-openproject-4.2.6-1-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mINFRA:Django Stack\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-djangostack-1.7.10-1-ubuntu-14.04.qcow2
glance image-create --name "INFRA:Django Stack" --file /tmp/images/bitnami-djangostack-1.7.10-1-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mINFRA:LAPP Stack\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-lappstack-5.5.30-0-ubuntu-14.04.qcow2
glance image-create --name "INFRA:LAPP Stack" --file /tmp/images/bitnami-lappstack-5.5.30-0-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mINFRA:LAMP Stack\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/bitnami-lampstack-5.5.30-0-ubuntu-14.04.qcow2
glance image-create --name "INFRA:LAMP Stack" --file /tmp/images/bitnami-lampstack-5.5.30-0-ubuntu-14.04.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mVR: FortiGate 5.4.4\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/fortios.qcow2
glance image-create --name "VR:FortiGate-5.4.4" --file /tmp/images/fortios.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mVR: Juniper vSRX 15.1X49\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/media-vsrx-vmdisk-15.1X49-D40.6.qcow2
glance image-create --name "VR:Juniper-vSRX-15.1X49-D40.6" --file /tmp/images/media-vsrx-vmdisk-15.1X49-D40.6.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mVR: Cisco CSR1000v\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/csr1000v-universalk9.03.15.00.S.155-2.S-std.qcow2
glance image-create --name "VR:Cisco-CSR1000v-3.15s" --file /tmp/images/csr1000v-universalk9.03.15.00.S.155-2.S-std.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
sleep 1
clear
echo ; echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mNetwork Attachments\033[0m" ;echo " ############################"
echo
#### FOR PROVIDER & SELF NETWORKING ENTER THIS
########## https://docs.openstack.org/mitaka/install-guide-ubuntu/launch-instance-networks-provider.html
source /etc/keystone/admin-openrc.sh
echo " -> Configuring Provider Network:"
echo " --------------------------------"
neutron net-create --shared --provider:physical_network provider --provider:network_type flat provider
neutron subnet-create --name provider --allocation-pool start=$ProvNetStart,end=$ProvNetEnd --dns-nameserver 8.8.8.8 --gateway $ProvNetGW provider $ProvNetCIDR
neutron net-update provider --router:external
echo
source /etc/keystone/demo-openrc.sh
echo " -> Configuring Service Network:"
echo " --------------------------------"
neutron net-create selfservice
neutron subnet-create --name selfservice --dns-nameserver 8.8.8.8 --gateway 10.20.30.1 selfservice 10.20.30.0/24
neutron router-create router
neutron router-interface-add router selfservice
neutron router-gateway-set router provider
echo
echo -en " #################################### " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack IS READY ! ############################"
sleep 1
echo
echo "   Horizon Dashbord is @ http://$MYIP/"
echo "   Username : admin"
echo "   Password : equiinfra"
echo
echo " --> Before u begin using you have to do the following:"
echo " 1- Edit and adjust /etc/hosts based on your nodes."
echo " 2- Create Tenant & External Networks."
echo " 3- Add $MYIP to DNS Server to resolve to $mystackname.$mydomain"
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
#service rabbitmq-server restart
#service mysql restart
#service mongodb restart
#service memcached restart
#service apache2 restart
#service glance-registry restart
#service glance-api restart
#service nova-api restart
#service nova-consoleauth restart
#service nova-scheduler restart
#service nova-conductor restart
#service nova-novncproxy restart
#service nova-api restart
#service neutron-server restart
#service neutron-linuxbridge-agent restart
#service neutron-dhcp-agent restart
#service neutron-metadata-agent restart
#service neutron-l3-agent restart
#service cinder-scheduler restart
#service cinder-api restart
#service manila-scheduler restart
#service manila-api restart
#service swift-proxy restart
#service heat-api restart
#service heat-api-cfn restart
#service heat-engine restart
#service ceilometer-agent-central restart
#service ceilometer-agent-notification restart
#service ceilometer-api restart
#service ceilometer-collector restart
#service aodh-api restart
#service aodh-evaluator restart
#service aodh-notifier restart
#service aodh-listener restart
#service trove-api restart
#service trove-taskmanager restart
#service trove-conductor restart
