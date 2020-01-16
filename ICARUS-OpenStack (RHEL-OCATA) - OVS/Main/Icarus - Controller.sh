#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

##################### SCRIPT CONFIGURATION
port0=ens33                       #MANGMENT
MYGW=10.0.0.1                     #MANGMENT GW
MNGsubnetCIDR="10.0.0.0/24"       #MANGMENT SUBNET
MNGsubnetMASK="255.255.255.0"     #Subnet Netmask
mystackname="Icarus-Controller"   #Hostname
cloudaka="Icarus"                 #Cloud Code Name
mydomain="equinoxme.com"          #Cloud Domain Name
COWBRINGER=10.0.0.100             #Cow Bringer Source VM
REPOREAPER=10.0.0.101             #RepoReaper Source VM
ProvNetStart=192.168.67.200       #Provider Network Allocation Start
ProvNetEnd=192.168.67.209         #Provider Network Allocation End
ProvNetGW=192.168.67.1            #Provider Network GW
ProvNetCIDR=192.168.67.0/24       #Provider Network CIDR
##################### SERVICES SELECTION

####################################################
echo
echo " DOES NOT NEED INIT SCRIPT"
echo "##### ADJUST HOSTS FILE WITHIN THE SCRIPT AS DESIRED BEFORE BOOTSTRAP <<"
echo "-> Hit enter to begin"
read
MYIP=$(ip addr | grep $port0 | grep inet | awk '{print $2}' | cut -d "/" -f1)
clear
echo
echo -en "                                         " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack Controller Auto Deployment   "
echo "                                                  Script by Mohamed Ashraf "
echo
echo
echo " -> Please run this script as root! "
echo " -> INSTALLS RDO OCATA ON RHEL 7.3"
echo
echo " Parameters INFO:"
echo "-----------------"
echo " - Mangment Network IP will be used from $port0 : $MYIP"
echo " - Provider Network will be used from Network Node"
echo " - My hostname is $mystackname"
echo
echo " >>>>> Hit Enter when you are Ready <<<<<"
read
sleep 2
echo " #################################### PREPARING SYSTEM ############################"
echo
sleep 1
echo "Fetching RepoReaper Link..."
sleep 2
cd /etc/yum.repos.d
curl -O http://$REPOREAPER/rhel-repo/equinox.repo
yum install yum-utils -y
yum-config-manager --disable equinox-rdo-ocata | grep "enabled"
yum clean all
yum repolist
yum update -y
yum upgrade -y
yum install openssh openssh-server htop pydf unzip iftop make nano tcpdump gcc sudo dnsutils ntp ethtool nload fping nmap yum-utils net-tools wget telnet -y
yum install python-pip redhat-lsb-core git -y
yum install open-vm-tools -y
yum install pydf -y
systemctl stop firewalld
systemctl disable firewalld
systemctl stop iptables
systemctl disable iptables
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl enable network
systemctl start network
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
$MYIP       controller.$mydomain controller


##### $cloudaka-OpenStack Nodes
# MANG
$MYIP       $cloudaka-Controller.$mydomain   $cloudaka-Controller  controller
10.0.0.21       $cloudaka-Network1.$mydomain     $cloudaka-Network1    network1
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
/usr/bin/hostnamectl set-hostname $mystackname
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
sleep 2
yum-config-manager --disable equinox-* | grep "enabled"
sleep 1
yum-config-manager --enable equinox-rhel-7-server-openstack-11-*   | grep "ui_id"
yum-config-manager --enable equinox-rhel-7-server-rpms             | grep "ui_id"
yum-config-manager --enable equinox-rhel-7-server-extras-rpms      | grep "ui_id"
yum-config-manager --enable equinox-rhel-7-server-optional-rpms    | grep "ui_id"
yum-config-manager --enable equinox-rhel-ha-for-rhel-7-server-rpms | grep "ui_id"
sleep 2
yum repolist
##
echo "## Building Required Packages..."
echo
yum upgrade -y
yum install python-openstackclient -y
yum install openstack-selinux -y
echo
echo " #################################### Installing System SQL DataBase ############################"
echo
sleep 1
echo "--->> Installing DataBase..."
echo
sleep 1
yum install mariadb mariadb-server python2-PyMySQL -y
echo
echo -en "Configuring DB for Openstack Parameters..."
echo "[mysqld]
bind-address = $MYIP
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8" > /etc/my.cnf.d/openstack.cnf
sleep 2
echo "[OK]"
echo
systemctl enable mariadb.service
systemctl start mariadb.service
echo
echo " #################################### Installing System noSQL DataBase ############################"
echo
sleep 1
yum install mongodb-server mongodb -y
echo
echo -en "Configuring DB Parameters..."
echo "bind_ip = $MYIP
fork = true
pidfilepath = /var/run/mongodb/mongod.pid
logpath = /var/log/mongodb/mongod.log
unixSocketPrefix = /var/run/mongodb
dbpath = /var/lib/mongodb
smallfiles = true" > /etc/mongod.conf
sleep 2
echo "[OK]"
echo
systemctl enable mongod.service
systemctl start mongod.service
sleep 1
echo
echo " #################################### Installing Message Queueing Services ############################"
echo
sleep 1
yum install rabbitmq-server -y
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service
echo -en "Waiting for RabbitMQ Node..."
sleep 10
echo "[OK]"
echo
/usr/sbin/rabbitmqctl -n rabbit@$mystackname add_user openstack equiinfra
sleep 1
/usr/sbin/rabbitmqctl -n rabbit@$mystackname set_permissions openstack ".*" ".*" ".*"
echo
sleep 1
systemctl restart rabbitmq-server.service
sleep 2
echo
echo " #################################### Installing MemCached Services ############################"
echo
sleep 1
yum install memcached python-memcached -y
echo
echo -en "Configuring Cache..."
echo "PORT=11211
USER=memcached
MAXCONN=1024
CACHESIZE=1024
OPTIONS=-l $MYIP,127.0.0.1" > /etc/sysconfig/memcached
sleep 2
echo "[OK]"
echo
systemctl enable memcached.service
systemctl start memcached.service
clear
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mKeyStone\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -Bse "CREATE DATABASE keystone;"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'equiinfra';"
echo "[OK]"
echo
echo "--->> Installing Packages..."
echo
sleep 1
yum install openstack-keystone httpd mod_wsgi -y
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
" > /etc/keystone/keystone.conf
echo "[OK]"
echo
echo "--->> Populating Database..."
echo
sleep 1
su -s /bin/sh -c "keystone-manage db_sync" keystone
echo
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
echo
keystone-manage bootstrap --bootstrap-password equiinfra --bootstrap-admin-url http://controller:35357/v3/ --bootstrap-internal-url http://controller:5000/v3/ --bootstrap-public-url http://controller:5000/v3/ --bootstrap-region-id RegionOne
echo -en " Configuring Apache..."
sleep 1
echo "ServerName $mystackname" >> /etc/httpd/conf/httpd.conf
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl enable httpd.service
systemctl start httpd.service
echo
echo -en "--->> CREATING SERVICE ENTITY AND ENDPOINTS..."
echo
sleep 1
export OS_USERNAME=admin
export OS_PASSWORD=equiinfra
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
echo "[OK]"
echo
echo "--->> CREATING PROJECTS AND USERS:"
echo
sleep 1
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password demo demo
openstack role create user
openstack role add --project demo --user demo user
unset OS_AUTH_URL OS_PASSWORD
echo
echo -en " Creating environment scripts..."
sleep 1
echo "export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=equiinfra
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2" > /etc/keystone/admin-openrc.sh
echo "export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
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
mysql -u root -Bse "CREATE DATABASE glance;"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'equiinfra';"
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
yum install openstack-glance -y
echo
echo -en " Configuring Glance..."
sleep 1
#cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.DEFAULT
#cp /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.DEFAULT
echo "[DEFAULT]
transport_url = rabbit://openstack:equiinfra@controller

[cors]

[cors.subdomain]

[database]
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

[oslo_policy]

[paste_deploy]
flavor = keystone

[profiler]

[store_type_location_strategy]

[task]

[taskflow_executor]" > /etc/glance/glance-api.conf
echo "[DEFAULT]
transport_url = rabbit://openstack:equiinfra@controller

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
systemctl enable openstack-glance-api.service
systemctl enable openstack-glance-registry.service
systemctl start openstack-glance-api.service
systemctl start openstack-glance-registry.service
echo
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mNova\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -Bse "CREATE DATABASE nova_api;"
mysql -u root -Bse "CREATE DATABASE nova;"
mysql -u root -Bse "CREATE DATABASE nova_cell0;"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'equiinfra';"
echo "[OK]"
echo
echo "--->> Configuring Service endpoints..."
echo
sleep 1
source /etc/keystone/admin-openrc.sh
openstack user create --domain default --password equiinfra nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1
openstack user create --domain default --password equiinfra placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778
echo
echo "--->> Installing Packages..."
echo
sleep 1
yum install openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler openstack-nova-placement-api -y
echo
echo -en " Configuring Nova..."
sleep 1
#cp /etc/nova/nova.conf /etc/nova/nova.conf.DEFAULT
echo "[DEFAULT]
my_ip = $MYIP
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:equiinfra@controller
linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
vif_plugging_is_fatal = True
vif_plugging_timeout = 300

[api]
auth_strategy = keystone

[api_database]
connection = mysql+pymysql://nova:equiinfra@controller/nova_api

[database]
connection = mysql+pymysql://nova:equiinfra@controller/nova

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
enabled= true
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
os_region_name = RegionOne

[placement]
os_region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:35357/v3
username = placement
password = equiinfra

[scheduler]
discover_hosts_in_cells_interval = 300" > /etc/nova/nova.conf
#
echo "

<Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
</Directory>" >> /etc/httpd/conf.d/00-nova-placement-api.conf
echo "[OK]"
echo
echo "--->> Populating Database..."
echo
sleep 1
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova
echo
nova-manage cell_v2 list_cells
echo
systemctl enable openstack-nova-api.service
systemctl enable openstack-nova-consoleauth.service
systemctl enable openstack-nova-scheduler.service
systemctl enable openstack-nova-conductor.service
systemctl enable openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service
systemctl start openstack-nova-consoleauth.service
systemctl start openstack-nova-scheduler.service
systemctl start openstack-nova-conductor.service
systemctl start openstack-nova-novncproxy.service
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mNeutron\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -Bse "CREATE DATABASE neutron;"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'equiinfra';"
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
yum install openstack-neutron openstack-neutron-ml2 -y
echo
echo -en " Configuring Neutron Engine..."
sleep 1
#cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.DEFAULT
echo "[DEFAULT]
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
transport_url = rabbit://openstack:equiinfra@controller
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
state_path = /var/lib/neutron
dhcp_agent_notification = True

[agent]
root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf

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
lock_path = /var/lib/neutron/tmp" > /etc/neutron/neutron.conf
echo "[OK]"
echo
echo -en " Configuring Neutron L2 Plugin..."
sleep 1
#cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.DEFAULT
echo "[DEFAULT]

[ml2]
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = openvswitch,l2population
extension_drivers = port_security

[ml2_type_flat]
flat_networks = provider

[ml2_type_vxlan]
vni_ranges = 1:1000

[securitygroup]
enable_ipset = True
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver" > /etc/neutron/plugins/ml2/ml2_conf.ini
echo "[OK]"

#echo
#echo " Configuring Neutron FireWall as a Service Plugin..."
#sleep 1
#echo "[fwaas]
#driver = neutron_fwaas.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver
#enabled = True
#" > /etc/neutron/fwaas_driver.ini
#echo "[OK]"

echo
echo "--->> Populating Database..."
echo
sleep 1
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
echo
echo " Starting Services..."
echo
chown -R neutron:neutron /etc/neutron/
systemctl restart openstack-nova-api.service
systemctl enable neutron-server.service
systemctl start neutron-server.service
sleep 2
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mHorizon\033[0m" ;echo " ############################"
echo
echo "--->> Installing Packages..."
echo
sleep 1
yum install openstack-dashboard -y
echo
echo -en " Configuring Horizon..."
sleep 1
#cp /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.DEFAULT
cat > /etc/openstack-dashboard/local_settings << 'EOF'
import os
from django.utils.translation import ugettext_lazy as _
from openstack_dashboard.settings import HORIZON_CONFIG
DEBUG = False
WEBROOT = '/dashboard/'
ALLOWED_HOSTS = ['*']
LOCAL_PATH = '/tmp'
SECRET_KEY='ffbb60aed6b3050cbb08'
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': 'controller:11211',
    }
}
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
OPENSTACK_HOST = "controller"
OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
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
    'enable_quotas': True
}
OPENSTACK_CINDER_FEATURES = {
    'enable_backup': False,
}
OPENSTACK_NEUTRON_NETWORK = {
    'enable_router': True,
    'enable_quotas': True,
    'enable_ipv6': True,
    'enable_distributed_router': True,
    'enable_ha_router': True,
    'enable_lb': True,
    'enable_firewall': True,
    'enable_vpn': True,
    'enable_fip_topology_check': True,
    'profile_support': None,
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
INSTANCE_LOG_LENGTH = 35
DROPDOWN_MAX_ITEMS = 30
TIME_ZONE = "EET"
POLICY_FILES_PATH = '/etc/openstack-dashboard'
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'operation': {
            'format': '%(asctime)s %(message)s'
        },
    },
    'handlers': {
        'null': {
            'level': 'DEBUG',
            'class': 'logging.NullHandler',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
        },
        'operation': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'operation',
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
        'horizon.operation_log': {
            'handlers': ['operation'],
            'level': 'INFO',
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
                              'LAUNCH_INSTANCE_DEFAULTS',
                              'OPENSTACK_IMAGE_FORMATS',
                              'OPENSTACK_KEYSTONE_DEFAULT_DOMAIN']
ALLOWED_PRIVATE_SUBNET_CIDR = {'ipv4': [], 'ipv6': []}
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "default"
DESIGNATE = { 'records_use_fips': True }
EOF
echo "[OK]"
echo
systemctl restart httpd.service
systemctl restart memcached.service
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mCinder\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -Bse "CREATE DATABASE cinder;"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'equiinfra';"
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
yum install openstack-cinder -y
echo
echo -en " Configuring Cinder..."
sleep 1
#cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.DEFAULT
echo "[DEFAULT]
my_ip = $MYIP
rootwrap_config = /etc/cinder/rootwrap.conf
api_paste_confg = /etc/cinder/api-paste.ini
iscsi_helper = lioadm
volume_name_template = volume-%s
volume_group = cinder-volumes
auth_strategy = keystone
state_path = /var/lib/cinder
lock_path = /var/lock/cinder
volumes_dir = /var/lib/cinder/volumes
transport_url = rabbit://openstack:equiinfra@controller
auth_strategy = keystone

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
systemctl restart openstack-nova-api.service
systemctl enable openstack-cinder-api.service
systemctl enable openstack-cinder-scheduler.service
systemctl start openstack-cinder-api.service
systemctl start openstack-cinder-scheduler.service
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mManila\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -Bse "CREATE DATABASE manila;"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON manila.* TO 'manila'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON manila.* TO 'manila'@'%' IDENTIFIED BY 'equiinfra';"
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
yum install openstack-manila python-manilaclient -y
echo
echo -en " Configuring Manila..."
sleep 1
#cp /etc/manila/manila.conf /etc/manila/manila.conf.DEFAULT
echo "[DEFAULT]
my_ip = $MYIP
transport_url = rabbit://openstack:equiinfra@controller
default_share_type = default_share_type
share_name_template = share-%s
rootwrap_config = /etc/manila/rootwrap.conf
api_paste_config = /etc/manila/api-paste.ini
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

[oslo_concurrency]
lock_path = /var/lib/manila/tmp" > /etc/manila/manila.conf
echo "[OK]"
echo
echo "--->> Populating Database..."
echo
sleep 1
su -s /bin/sh -c "manila-manage db sync" manila
echo
systemctl enable openstack-manila-api.service
systemctl enable openstack-manila-scheduler.service
systemctl start openstack-manila-api.service
systemctl start openstack-manila-scheduler.service
echo
yum install openstack-manila-ui -y
systemctl restart httpd
systemctl restart memcached
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
yum install openstack-swift-proxy python-swiftclient python-keystoneclient python-keystonemiddleware memcached -y
echo
echo -en " Configuring Swift..."
sleep 1
mkdir -p /etc/swift
#curl -o /etc/swift/proxy-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/proxy-server.conf-sample?h=stable/ocata
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
swift-ring-builder account.builder add --region 1 --zone 1 --ip 10.0.0.51 --port 6202 --device sdb --weight 100
swift-ring-builder account.builder add --region 1 --zone 1 --ip 10.0.0.51 --port 6202 --device sdc --weight 100
swift-ring-builder account.builder
swift-ring-builder account.builder rebalance
sleep 2
swift-ring-builder container.builder create 10 1 1
swift-ring-builder container.builder add --region 1 --zone 1 --ip 10.0.0.51 --port 6201 --device sdb --weight 100
swift-ring-builder container.builder add --region 1 --zone 1 --ip 10.0.0.51 --port 6201 --device sdc --weight 100
swift-ring-builder container.builder
swift-ring-builder container.builder rebalance
sleep 2
swift-ring-builder object.builder create 10 1 1
swift-ring-builder object.builder add --region 1 --zone 1 --ip 10.0.0.51 --port 6200 --device sdb --weight 100
swift-ring-builder object.builder add --region 1 --zone 1 --ip 10.0.0.51 --port 6200 --device sdc --weight 100
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
#curl -o /etc/swift/swift.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/swift.conf-sample?h=stable/ocata
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
systemctl enable openstack-swift-proxy.service
systemctl enable memcached.service
systemctl start openstack-swift-proxy.service
systemctl start memcached.service
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mHeat\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -Bse "CREATE DATABASE heat;"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY 'equiinfra';"
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
openstack endpoint create --region RegionOne cloudformation public http://controller:8001/v1
openstack endpoint create --region RegionOne cloudformation internal http://controller:8001/v1
openstack endpoint create --region RegionOne cloudformation admin http://controller:8001/v1
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
yum install openstack-heat-api openstack-heat-api-cfn openstack-heat-engine -y
echo
echo -en " Configuring Heat..."
sleep 1
#cp /etc/heat/heat.conf /etc/heat/heat.conf.DEFAULT
echo "[DEFAULT]
transport_url = rabbit://openstack:equiinfra@controller
heat_metadata_server_url = http://controller:8001
heat_waitcondition_server_url = http://controller:8001/v1/waitcondition
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
systemctl enable openstack-heat-api.service
systemctl enable openstack-heat-api-cfn.service
systemctl enable openstack-heat-engine.service
systemctl start openstack-heat-api.service
systemctl start openstack-heat-api-cfn.service
systemctl start openstack-heat-engine.service
echo
sleep 2
openstack orchestration service list
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mCeilometer\033[0m" ;echo " ############################"
echo
echo "--->> Configuring Ceilometer DataBase..."
echo
sleep 1
mongo --host controller --eval '
  db = db.getSiblingDB("ceilometer");
  db.createUser({user: "ceilometer",
  pwd: "equiinfra",
  roles: [ "readWrite", "dbAdmin" ]})'
echo
mysql -u root -Bse "CREATE DATABASE aodh;"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'%' IDENTIFIED BY 'equiinfra';"
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
yum install openstack-ceilometer-api openstack-ceilometer-collector openstack-ceilometer-notification openstack-ceilometer-central python-ceilometerclient -y
yum install python-ceilometermiddleware -y
yum install openstack-aodh-api openstack-aodh-evaluator openstack-aodh-notifier openstack-aodh-listener openstack-aodh-expirer python-aodhclient -y
echo
echo -en " Configuring Ceilometer..."
sleep 1
#cp /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.DEFAULT
#cp /etc/aodh/aodh.conf /etc/aodh/aodh.conf.DEFAULT
#cp /etc/aodh/api_paste.ini /etc/aodh/api_paste.ini.DEFAULT
echo "[DEFAULT]
transport_url = rabbit://openstack:equiinfra@controller
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
transport_url = rabbit://openstack:equiinfra@controller
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
systemctl enable openstack-ceilometer-api.service
systemctl enable openstack-ceilometer-notification.service
systemctl enable openstack-ceilometer-central.service
systemctl enable openstack-ceilometer-collector.service
systemctl start openstack-ceilometer-api.service
systemctl start openstack-ceilometer-notification.service
systemctl start openstack-ceilometer-central.service
systemctl start openstack-ceilometer-collector.service
systemctl restart openstack-swift-proxy.service
systemctl enable openstack-aodh-api.service
systemctl enable openstack-aodh-evaluator.service
systemctl enable openstack-aodh-notifier.service
systemctl enable openstack-aodh-listener.service
systemctl start openstack-aodh-api.service
systemctl start openstack-aodh-evaluator.service
systemctl start openstack-aodh-notifier.service
systemctl start openstack-aodh-listener.service
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mDesignate\033[0m" ;echo " ############################"
echo
echo -en " Preparing Database..."
sleep 1
mysql -u root -Bse "CREATE DATABASE designate;"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON designate.* TO 'designate'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON designate.* TO 'designate'@'%' IDENTIFIED BY 'equiinfra';"
echo "[OK]"
echo "--->> Configuring Service endpoints..."
echo
sleep 1
source /etc/keystone/admin-openrc.sh
openstack user create --domain default --password equiinfra designate
openstack role add --project service --user designate admin
openstack service create --name designate --description "DNS" dns
openstack endpoint create --region RegionOne dns public http://controller:9001/
openstack endpoint create --region RegionOne dns internal http://controller:9001/
openstack endpoint create --region RegionOne dns admin http://controller:9001/
echo
echo " -->> Installing Packages..."
echo
yum install bind openstack-designate\* -y
echo
echo -en " --> Configuring Designate..."
sleep 1
cat > /etc/named.conf << 'EOF'
options {
        listen-on port 53 { 127.0.0.1; };
        listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        allow-query     { localhost; };

        allow-new-zones yes;
        request-ixfr no;
        recursion no;

        dnssec-enable yes;
        dnssec-validation yes;

        bindkeys-file "/etc/named.iscdlv.key";

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};

key "designate" {
        algorithm hmac-md5;
        secret "WS0E6q895QShCQ79Q9UyvA4e";
};

controls {
  inet 127.0.0.1 port 953
    allow { 127.0.0.1; } keys { "designate"; };
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF
######
cat > /etc/designate/rndc.key << 'EOF'
key "designate" {
        algorithm hmac-md5;
        secret "WS0E6q895QShCQ79Q9UyvA4e";
};
EOF
######
echo "[DEFAULT]
verbose = True
debug = False
transport_url = rabbit://openstack:equiinfra@controller

[oslo_messaging_rabbit]

[service:api]
api_host = 0.0.0.0
api_port = 9001
auth_strategy = keystone
enable_api_v1 = True
enabled_extensions_v1 = quotas, reports
enable_api_v2 = True

[keystone_authtoken]
auth_host = controller
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = designate
admin_password = equiinfra

[service:worker]
enabled = True
notify = True

[storage:sqlalchemy]
connection = mysql+pymysql://designate:equiinfra@controller/designate" > /etc/designate/designate.conf
#######
cat > /etc/designate/pools.yaml << 'EOF'
- name: default
  # The name is immutable. There will be no option to change the name after
  # creation and the only way will to change it will be to delete it
  # (and all zones associated with it) and recreate it.
  description: Default Pool

  attributes: {}

  # List out the NS records for zones hosted within this pool
  # This should be a record that is created outside of designate, that
  # points to the public IP of the controller node.
  ns_records:
    - hostname: ns1-1.example.org.
      priority: 1

  # List out the nameservers for this pool. These are the actual BIND servers.
  # We use these to verify changes have propagated to all nameservers.
  nameservers:
    - host: 127.0.0.1
      port: 53

  # List out the targets for this pool. For BIND there will be one
  # entry for each BIND server, as we have to run rndc command on each server
  targets:
    - type: bind
      description: BIND9 Server 1

      # List out the designate-mdns servers from which BIND servers should
      # request zone transfers (AXFRs) from.
      # This should be the IP of the controller node.
      # If you have multiple controllers you can add multiple masters
      # by running designate-mdns on them, and adding them here.
      masters:
        - host: 127.0.0.1
          port: 5354

      # BIND Configuration options
      options:
        host: 127.0.0.1
        port: 53
        rndc_host: 127.0.0.1
        rndc_port: 953
        rndc_key_file: /etc/designate/rndc.key
EOF
echo "[OK]"
echo
echo " --> Populating Database..."
echo
su -s /bin/sh -c "designate-manage database sync" designate
echo
echo " --> Starting Services..."
sleep 1
echo
systemctl enable named
systemctl start named
systemctl enable designate-central
systemctl enable designate-api
systemctl start designate-central
systemctl start designate-api
sleep 5
su -s /bin/sh -c "designate-manage pool update" designate
systemctl enable designate-worker
systemctl enable designate-producer
systemctl enable designate-mdns
systemctl start designate-worker
systemctl start designate-producer
systemctl start designate-mdns
echo
cd /tmp
#wget https://tarballs.openstack.org/designate-dashboard/designate-dashboard-4.0.0.tar.gz
#tar zxvf designate-dashboard-4.0.0.tar.gz
#cd designate-dashboard-4.0.0
#pip install -r requirements.txt
#python setup.py install
#cp designatedashboard/enabled/_17* /usr/share/openstack-dashboard/openstack_dashboard/local/enabled/
systemctl restart memcached
systemctl restart httpd
echo
echo " #################################### $cloudaka Images Flavors Adjustment & Configuration ############################"
sleep 1
echo
echo
echo "--->> Configuring $cloudaka Image Flavors..."
source /etc/keystone/admin-openrc.sh
sleep 2
openstack flavor create Tiny.1x512   --id 1  --ram 512   --swap 512   --disk 5   --vcpus 1 --ephemeral 0
openstack flavor create Standard.1x1 --id 2  --ram 1024  --swap 1024  --disk 10  --vcpus 1 --ephemeral 0
openstack flavor create Standard.2x2 --id 3  --ram 2048  --swap 2048  --disk 20  --vcpus 2 --ephemeral 0
openstack flavor create Standard.3x3 --id 4  --ram 3072  --swap 3072  --disk 30  --vcpus 3 --ephemeral 0
openstack flavor create Standard.4x4 --id 5  --ram 4096  --swap 4096  --disk 40  --vcpus 4 --ephemeral 0
openstack flavor create Standard.5x5 --id 6  --ram 5120  --swap 5120  --disk 50  --vcpus 5 --ephemeral 0
openstack flavor create Standard.6x6 --id 7  --ram 6144  --swap 6144  --disk 60  --vcpus 6 --ephemeral 0
openstack flavor create Standard.7x7 --id 8  --ram 7168  --swap 7168  --disk 70  --vcpus 7 --ephemeral 0
openstack flavor create Standard.8x8 --id 9  --ram 8192  --swap 8192  --disk 80  --vcpus 8 --ephemeral 0
openstack flavor create HighCPU.3x1  --id 10 --ram 1024  --swap 1024  --disk 30  --vcpus 3 --ephemeral 0
openstack flavor create HighCPU.4x2  --id 11 --ram 2048  --swap 2048  --disk 40  --vcpus 4 --ephemeral 0
openstack flavor create HighCPU.5x3  --id 12 --ram 3072  --swap 3072  --disk 50  --vcpus 5 --ephemeral 0
openstack flavor create HighCPU.6x4  --id 13 --ram 4096  --swap 4096  --disk 60  --vcpus 6 --ephemeral 0
openstack flavor create HighCPU.7x5  --id 14 --ram 5120  --swap 5120  --disk 70  --vcpus 7 --ephemeral 0
openstack flavor create HighCPU.8x6  --id 15 --ram 6144  --swap 6144  --disk 80  --vcpus 8 --ephemeral 0
openstack flavor create HighMEM.1x5  --id 16 --ram 5120  --swap 5120  --disk 50  --vcpus 1 --ephemeral 0
openstack flavor create HighMEM.2x6  --id 17 --ram 6144  --swap 6144  --disk 60  --vcpus 2 --ephemeral 0
openstack flavor create HighMEM.3x7  --id 18 --ram 7168  --swap 7168  --disk 70  --vcpus 3 --ephemeral 0
openstack flavor create HighMEM.4x8  --id 19 --ram 8192  --swap 8192  --disk 80  --vcpus 4 --ephemeral 0
openstack flavor create HighMEM.5x9  --id 20 --ram 9216  --swap 9216  --disk 90  --vcpus 5 --ephemeral 0
openstack flavor create HighMEM.6x10 --id 21 --ram 10240 --swap 10240 --disk 100 --vcpus 6 --ephemeral 0
openstack flavor create HighMEM.7x11 --id 22 --ram 11264 --swap 11264 --disk 110 --vcpus 7 --ephemeral 0
openstack flavor create HighMEM.8x12 --id 23 --ram 12288 --swap 12288 --disk 120 --vcpus 8 --ephemeral 0
openstack flavor create HighDISK.1x1 --id 24 --ram 1024  --swap 1024  --disk 60  --vcpus 1 --ephemeral 0
openstack flavor create HighDISK.2x2 --id 25 --ram 2048  --swap 2048  --disk 70  --vcpus 2 --ephemeral 0
openstack flavor create HighDISK.3x3 --id 26 --ram 3072  --swap 3072  --disk 80  --vcpus 3 --ephemeral 0
openstack flavor create HighDISK.4x4 --id 27 --ram 4096  --swap 4096  --disk 90  --vcpus 4 --ephemeral 0
openstack flavor create HighDISK.5x5 --id 28 --ram 5120  --swap 5120  --disk 100 --vcpus 5 --ephemeral 0
openstack flavor create HighDISK.6x6 --id 29 --ram 6144  --swap 6144  --disk 110 --vcpus 6 --ephemeral 0
openstack flavor create HighDISK.7x7 --id 30 --ram 7168  --swap 7168  --disk 120 --vcpus 7 --ephemeral 0
openstack flavor create HighDISK.8x8 --id 31 --ram 8192  --swap 8192  --disk 130 --vcpus 8 --ephemeral 0
openstack flavor list
echo
echo " #################################### Fetching & Loading Operating Systems Images ############################"
echo
source /etc/keystone/admin-openrc.sh
mkdir /tmp/images
sleep 1
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mOS: Cirros\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/cirros-0.3.4-x86_64-disk.img
glance image-create --name "OS:Cirros-0.3.4" --file /tmp/images/cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --visibility public --progress
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
wget -P /tmp/images http://$COWBRINGER/openstack-images/CSR1000v.qcow2
glance image-create --name "VR:Cisco-CSR1000v" --file /tmp/images/CSR1000v.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mVR: Cisco ASAv\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/ASAv.qcow2
glance image-create --name "VR:Cisco-ASAv" --file /tmp/images/ASAv.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mVR: Cisco IOS-XRv\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/IOS-XRv.qcow2
glance image-create --name "VR:Cisco-IOS-XRv" --file /tmp/images/IOS-XRv.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mVR: Cisco IOSv\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/IOSv.qcow2
glance image-create --name "VR:Cisco-IOSv" --file /tmp/images/IOSv.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mVR: Cisco IOSvL2\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/IOSvL2.qcow2
glance image-create --name "VR:Cisco-IOSvL2" --file /tmp/images/IOSvL2.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mVR: Cisco Nexus OSv 9K\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/NX-OSv-9000.qcow2
glance image-create --name "VR:Cisco-NXv-9k" --file /tmp/images/NX-OSv-9000.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mVR: Cisco Nexus OSv\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/NX-OSv.qcow2
glance image-create --name "VR:Cisco-NXv" --file /tmp/images/NX-OSv.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mContainers: Fedora-Atomic\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/fedora-atomic-ocata.qcow2
glance image-create --name "Containers:Fedora-Atomic" --file /tmp/images/fedora-atomic-ocata.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mContainers: CoreOS\033[0m"; echo " <<------"
sleep 1
echo
wget -P /tmp/images http://$COWBRINGER/openstack-images/coreos_production_openstack_image.img
glance image-create --name "Containers:CoreOS-1395" --file /tmp/images/coreos_production_openstack_image.img --disk-format qcow2 --container-format bare --visibility public --progress
rm -r /tmp/images
echo
sleep 1
#echo "--->> Branding $cloudaka OpenStack..."
#echo
#sleep 1
#wget -P /tmp/images http://$COWBRINGER/openstack-images/logo.svg
#wget -P /tmp/images http://$COWBRINGER/openstack-images/logo-splash.svg
#mv /usr/share/openstack-dashboard/static/dashboard/img/logo.svg /usr/share/openstack-dashboard/static/dashboard/img/logo.svg.BAK
#mv /usr/share/openstack-dashboard/static/dashboard/img/logo-splash.svg /usr/share/openstack-dashboard/static/dashboard/img/logo-splash.svg.BAK
#mv /tmp/images/logo.svg /usr/share/openstack-dashboard/static/dashboard/img/logo.svg
#mv /tmp/images/logo-splash.svg /usr/share/openstack-dashboard/static/dashboard/img/logo-splash.svg
#echo ; echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mNetwork Attachments\033[0m" ;echo " ############################"
echo
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
yum autoremove -y
echo
echo " ############################ Debianzing Bash Environment #########################"
echo
echo -en "Adjusting Root user Bashrc Configuration..."
cat > /root/.bashrc << 'EOF'
[ -z "$PS1" ] && return

HISTCONTROL=ignoredups:ignorespace

shopt -s histappend

HISTSIZE=1000
HISTFILESIZE=2000

shopt -s checkwinsize

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'


if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
EOF
echo "[OK]"
echo
echo -en " #################################### " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " Controller IS READY ! ############################"
sleep 1
echo
echo "   Horizon Dashbord is @ http://$MYIP/dashboard"
echo "   Username : admin"
echo "   Password : equiinfra"
echo
echo " --> Before u begin using you have to do the following:"
echo " 1- Create Tenant & External Networks, if needed."
echo " 2- Add $MYIP to DNS Server to resolve to $mystackname.$mydomain"
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
