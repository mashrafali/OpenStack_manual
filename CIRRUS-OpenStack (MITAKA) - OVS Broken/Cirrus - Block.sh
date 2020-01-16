#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

##################### SCRIPT CONFIGURATION
#CONFIGURE Below:
###
port0=eth0                      #Mangment Network
MYGW=10.0.0.1                   #MANGMENT GW
MNGsubnetMASK="255.255.255.0"   #Subnet Netmask
mystackname="Cirrus-Block1"     #Hostname
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
echo -en "                                         " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack Block Auto Deployment   "
echo "                                                  Script by Mohamed Ashraf "
echo
echo
echo " -> Please run this script as root! "
echo " -> INSTALLS MITAKA ON Ubuntu 14.04 LTS"
echo
echo " Parameters INFO:"
echo "-----------------"
echo " - Mangment Network IP will be used from $port0 : $MYIP"
echo " - Block Backend will be used on /dev/sdb"
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
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mCinder\033[0m" ;echo " ############################"
echo
sleep 1
echo "--->> Installing LVM Packages..."
echo
sleep 1
apt-get install lvm2 -y
echo
echo -en " Configuring LVM..."
#cp /etc/lvm/lvm.conf /etc/lvm/lvm.conf.DEFAULT
sleep 1
echo 'devices {
    dir = "/dev"
    scan = [ "/dev" ]
    obtain_device_list_from_udev = 1
    preferred_names = [ ]
    filter = [ "a/sdb/", "r/.*/"]
    cache_dir = "/run/lvm"
    cache_file_prefix = ""
    write_cache_state = 1
    sysfs_scan = 1
    multipath_component_detection = 1
    md_component_detection = 1
    md_chunk_alignment = 1
    data_alignment_detection = 1
    data_alignment = 0
    data_alignment_offset_detection = 1
    ignore_suspended_devices = 0
    disable_after_error_count = 0
    require_restorefile_with_uuid = 1
    pv_min_size = 2048
    issue_discards = 1
}
allocation {

    maximise_cling = 1
    mirror_logs_require_separate_pvs = 0
    thin_pool_metadata_require_separate_pvs = 0
}
log {
    verbose = 0
    silent = 0
    syslog = 1
    overwrite = 0
    level = 0
    indent = 1
    command_names = 0
    prefix = "  "
}
backup {
    backup = 1
    backup_dir = "/etc/lvm/backup"
    archive = 1
    archive_dir = "/etc/lvm/archive"
    retain_min = 10
    retain_days = 30
}
shell {
    history_size = 100
}
global {
    umask = 077
    test = 0
    units = "h"
    si_unit_consistency = 1
    activation = 1
    proc = "/proc"
    locking_type = 1
    wait_for_locks = 1
    fallback_to_clustered_locking = 1
    fallback_to_local_locking = 1
    locking_dir = "/run/lock/lvm"
    prioritise_write_locks = 1
    abort_on_internal_errors = 0
    detect_internal_vg_cache_corruption = 0
    metadata_read_only = 0
    mirror_segtype_default = "mirror"
    use_lvmetad = 0
    thin_check_executable = "/usr/sbin/thin_check"
    thin_check_options = [ "-q" ]
}
activation {
    checks = 0
    udev_sync = 1
    udev_rules = 1
    verify_udev_operations = 0
    retry_deactivation = 1
    missing_stripe_filler = "error"
    use_linear_target = 1
    reserved_stack = 64
    reserved_memory = 8192
    process_priority = -18
    mirror_region_size = 512
    readahead = "auto"
    raid_fault_policy = "warn"
    mirror_log_fault_policy = "allocate"
    mirror_image_fault_policy = "remove"
    snapshot_autoextend_threshold = 100
    snapshot_autoextend_percent = 20
    thin_pool_autoextend_threshold = 100
    thin_pool_autoextend_percent = 20
    use_mlockall = 0
    monitoring = 0
    polling_interval = 15
}
dmeventd {
    mirror_library = "libdevmapper-event-lvm2mirror.so"
    snapshot_library = "libdevmapper-event-lvm2snapshot.so"
    thin_library = "libdevmapper-event-lvm2thin.so"
}' > /etc/lvm/lvm.conf
echo "[OK]"
echo
pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb
echo
sleep 1
echo "--->> Installing Cinder Packages..."
echo
sleep 1
apt-get install cinder-volume -y
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
rpc_backend = rabbit
auth_strategy = keystone
glance_api_servers = http://controller:9292

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

[lvm]
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
iscsi_protocol = iscsi
iscsi_helper = tgtadm
volume_clear_size=50
volume_clear=none
type=thin

[oslo_concurrency]
lock_path = /var/lib/cinder/tmp

[oslo_messaging_notifications]
driver = messagingv2" > /etc/cinder/cinder.conf
echo "[OK]"
echo
service tgt restart
service cinder-volume restart
rm -f /var/lib/cinder/cinder.sqlite
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mManila\033[0m" ;echo " ############################"
echo
echo "--->> Installing Packages..."
echo
sleep 1
apt-get install manila-share python-pymysql -y
apt-get install neutron-plugin-linuxbridge-agent -y
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
enabled_share_backends = generic
enabled_share_protocols = NFS,CIFS

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
lock_path = /var/lib/manila/tmp

[neutron]
url = http://controller:9696
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = equiinfra

[nova]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = equiinfra

[cinder]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = cinder
password = equiinfra

[generic]
share_backend_name = GENERIC
share_driver = manila.share.drivers.generic.GenericShareDriver
driver_handles_share_servers = True
service_instance_flavor_id = 100
service_image_name = manila-service-image
service_instance_user = manila
service_instance_password = manila
interface_driver = manila.network.linux.interface.BridgeInterfaceDriver" > /etc/manila/manila.conf
echo "[OK]"
echo
service manila-share restart
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mCeilometer\033[0m" ;echo " ############################"
echo
echo "--->> Finalizing Ceilometer Installation..."
echo
sleep 1
service cinder-volume restart
echo
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
#service tgt restart
#service cinder-volume restart
#service manila-share restart
