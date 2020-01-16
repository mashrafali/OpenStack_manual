#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

##################### SCRIPT CONFIGURATION
#CONFIGURE Below:
###
port0=ens34                     #Mangment Network
NPORT1=ens38                    #External Port of Network1 Node
NIP1=10.0.0.21                  #Network1 Node Mang/Tunnel Net IP
CPORT1=ens38                    #External port of compute1 Node
CIP1=10.0.0.31                  #Compute1 Node Mang/Tunnel Net IP
MYGW=10.0.0.1                   #MANGMENT GW
MNGsubnetMASK="255.255.255.0"   #Subnet Netmask
mystackname="Icarus-ODL"        #Hostname
cloudaka="Icarus"               #Cloud Code Name
mydomain="equinoxme.com"        #Cloud Domain Name
controllerip=10.0.0.11          #Controller Node IP
COWBRINGER=10.0.0.100           #Cow Bringer Source VM
ProvNetStart=192.168.67.50      #Provider Network Allocation Start
ProvNetEnd=192.168.67.60        #Provider Network Allocation End
ProvNetGW=192.168.67.1          #Provider Network GW
ProvNetCIDR=192.168.67.0/24     #Provider Network CIDR
####################################################
echo
echo " DOES NOT NEED INIT SCRIPT"
echo "##### ADJUST HOSTS FILE WITHIN THE SCRIPT AS DESIRED BEFORE BOOTSTRAP <<"
echo "-> Hit enter to begin"
read
echo "    >>>>>>>>>>>>>>>>>>>>>> MAKE SURE OPENSTACK NETWORK IS IN A FULL CLEAN SLATE STATE! <<<<<<<<<<<<<<<<<<<<<<<"
echo "-> Hit enter to begin"
read
MYIP=$(ip addr | grep $port0 | grep inet | awk '{print $2}' | cut -d "/" -f1)
clear
echo
echo -en "                                         " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack ODL Auto Deployment   "
echo "                                                  Script by Mohamed Ashraf "
echo
echo
echo " -> Please run this script as root! "
echo " -> INSTALLS OpenDayLight SDN Controller for OCATA ON RHEL 7.3"
echo
echo " Parameters INFO:"
echo "-----------------"
echo " - Mangment Network IP will be used from $port0 : $MYIP"
echo " - Linking ODL Node to Controller Node of IP : $controllerip"
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
$MYIP       ODL.$mydomain ODL


##### $cloudaka-OpenStack Nodes
# MANG
$controllerip       $cloudaka-Controller.$mydomain   $cloudaka-Controller  controller
10.0.0.21       $cloudaka-Network1.$mydomain     $cloudaka-Network1    network1
10.0.0.31       $cloudaka-Compute1.$mydomain     $cloudaka-Compute1    compute1
10.0.0.41       $cloudaka-Block1.$mydomain       $cloudaka-Block1      block1
10.0.0.51       $cloudaka-Object1.$mydomain      $cloudaka-Object1     object1
$MYIP       $cloudaka-ODL.$mydomain          $cloudaka-ODL         odl" > /etc/hosts
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
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mODL\033[0m" ;echo " ############################"
echo
echo
echo "Disabling EXtra Repos..."
sleep 1
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/epel*
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/remi*
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/webtatic*
yum repolist
##
echo
sleep 1
echo "--->> Installing JRE 8 ..."
echo
sleep 1
#404#wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jre-8u60-linux-x64.rpm"
wget http://$COWBRINGER/openstack-images/jre-8u131-linux-x64.rpm
yum localinstall jre-8u131-linux-x64.rpm -y
rm -f jre-8u131-linux-x64.rpm
echo
echo "--->> Fetching ODL Boron SR3 ..."
sleep 1
#wget -P /root/ODL-SOURCE https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/distribution-karaf/0.5.3-Boron-SR3/distribution-karaf-0.5.3-Boron-SR3.tar.gz
wget -P /root/ODL-SOURCE http://$COWBRINGER/openstack-images/distribution-karaf-0.5.3-Boron-SR3.tar.gz
echo
cd /root/
tar xvfz /root/ODL-SOURCE/distribution-karaf-0.5.3-Boron-SR3.tar.gz
echo
sleep 1
echo " Waiting for KARAF Container ..."
echo
/root/distribution-karaf-0.5.3-Boron-SR3/bin/start
sleep 10
/root/distribution-karaf-0.5.3-Boron-SR3/bin/status
echo
echo "/root/distribution-karaf-0.5.3-Boron-SR3/bin/start" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
echo " ------->> Installing ODL Modules ... be patient <<-------"
echo
sleep 2
#/root/distribution-karaf-0.5.3-Boron-SR3/bin/client -u karaf "feature:install odl-aaa-authn odl-l2switch-switch odl-restconf odl-mdsal-apidocs odl-ovsdb-openstack odl-dlux-core odl-dlux-all"
/root/distribution-karaf-0.5.3-Boron-SR3/bin/client -u karaf "feature:install odl-l2switch-switch odl-ovsdb-openstack odl-dlux-core odl-dlux-all"
echo "/root/distribution-karaf-0.5.3-Boron-SR3/bin/client -u karaf" >> /root/.bashrc
echo "#! /bin/bash
/root/distribution-karaf-0.5.3-Boron-SR3/bin/client -u karaf" > /usr/bin/KARAF
chmod a+x /usr/bin/KARAF
echo
echo "##################################### Nodes SSH SYNC #########################"
sleep 1
echo
echo "--> I will begin Copying Keys to Controller, Network & compute Nodes now...."
echo "---> Hit Enter to begin"
read
cat /dev/zero | ssh-keygen -q -N "" ; echo
ssh-copy-id root@controller
ssh-copy-id root@network1
ssh-copy-id root@compute1
echo
echo
cat > /tmp/PURGE-NEUTRON.sh << 'EOF'
source /etc/keystone/admin-openrc.sh
echo "---> PURGING PROVIDER ROUTER GATEWAY..."
#neutron router-gateway-clear router
openstack router unset --external-gateway router
sleep 2
echo "---> PURGING PROVIDER ROUTER PORTS..."
for i in $(neutron router-port-list router | grep -i subnet | awk -F '"subnet_id": ' {'print $2'} | cut -d "\"" -f2)
do
  neutron router-interface-delete router $i
done
echo "---> DELETING PROVIDER ROUTER..."
#neutron router-delete router
openstack router delete router
sleep 2
echo "---> PURGING NEUTRON SUBNETS..."
#for i in $(neutron subnet-list | grep -E 'provider|selfservice' | awk {'print $2'})
#do
#  neutron subnet-delete $i
#done
openstack subnet delete selfservice
sleep 2
openstack subnet delete provider
sleep 2
echo "---> PURGING NEUTRON NETWORKS..."
#for i in $(neutron net-list | grep -E 'provider|selfservice' | awk {'print $2'})
#do
#  neutron net-delete $i
#done
openstack network delete selfservice
sleep 2
openstack network delete provider
sleep 2
echo
echo "---> Neutron is now a clean slate !"
sleep 2
EOF
scp /tmp/PURGE-NEUTRON.sh root@controller:/tmp/
ssh root@controller "chmod +x /tmp/PURGE-NEUTRON.sh"
ssh root@controller "/tmp/PURGE-NEUTRON.sh 2> /dev/null"
echo
echo "---> Disabling Neutron Components..."
echo
ssh root@controller "systemctl stop neutron-server"
ssh root@controller "systemctl disable neutron-server"
ssh root@network1 "systemctl stop neutron-openvswitch-agent"
ssh root@network1 "systemctl disable neutron-openvswitch-agent"
ssh root@compute1 "systemctl stop neutron-openvswitch-agent"
ssh root@compute1 "systemctl disable neutron-openvswitch-agent"
#
echo
echo -en "---> Configuring OVS to be managed by OpenDaylight..."
## Cleaning OVS
ssh root@network1 "systemctl stop openvswitch
rm -rf /var/log/openvswitch/*
rm -rf /etc/openvswitch/conf.db
systemctl start openvswitch
sleep 1
systemctl restart openvswitch"
ssh root@compute1 "systemctl stop openvswitch
rm -rf /var/log/openvswitch/*
rm -rf /etc/openvswitch/conf.db
systemctl start openvswitch
sleep 1
systemctl restart openvswitch"
## Pointing Manager
ssh root@network1 "ovs-vsctl set-manager tcp:$MYIP:6640"
ssh root@compute1 "ovs-vsctl set-manager tcp:$MYIP:6640"
## Creating new OVS Ports
ssh root@network1 "ovs-vsctl add-br br-provider"
#ssh root@network1 "ovs-vsctl add-br br-int"
ssh root@network1 "ovs-vsctl add-port br-provider $NPORT1"
ssh root@compute1 "ovs-vsctl add-br br-provider"
#ssh root@compute1 "ovs-vsctl add-br br-int"
ssh root@compute1 "ovs-vsctl add-port br-provider $CPORT1"
echo "[OK]"
echo
echo "---> Pushing New Configurations..."
echo "[ml2]
type_drivers = flat,gre,vxlan
tenant_network_types = vxlan
mechanism_drivers = opendaylight

[ml2_odl]
password = admin
username = admin
url = http://$MYIP:8080/controller/nb/v2/neutron
[ml2_type_vxlan]
vni_ranges = 1:1000" > /tmp/Controller-ml2
#
echo "[ml2]
type_drivers = flat,gre,vxlan
tenant_network_types = vxlan
mechanism_drivers = opendaylight

[ml2_odl]
password = admin
username = admin
url = http://$MYIP:8080/controller/nb/v2/neutron

[ml2_type_vxlan]
vni_ranges = 1:1000" > /tmp/Network-ml2
#
echo "[agent]
tunnel_types = vxlan

[ovs]
local_ip = $NIP1
bridge_mappings = provider:br-provider" > /tmp/Network-OVSagent
#
echo "[DEFAULT]
interface_driver = openvswitch
external_network_bridge =
router_delete_namespaces = True
verbose = True" > /tmp/Network-l3
#
echo "[ml2]
type_drivers = flat,gre,vxlan
tenant_network_types = vxlan
mechanism_drivers = opendaylight

[ml2_odl]
password = admin
username = admin
url = http://$MYIP:8080/controller/nb/v2/neutron

[ml2_type_vxlan]
vni_ranges = 1:1000" > /tmp/Compute-ml2
#
echo "[agent]
tunnel_types = vxlan

[ovs]
local_ip = $CIP1
bridge_mappings = provider:br-provider" > /tmp/Compute-OVSagent
#
scp /tmp/Controller-ml2 root@controller:/etc/neutron/plugins/ml2/ml2_conf.ini
scp /tmp/Network-ml2 root@network1:/etc/neutron/plugins/ml2/ml2_conf.ini
scp /tmp/Network-l3 root@network1:/etc/neutron/l3_agent.ini
scp /tmp/Network-OVSagent root@network1:/etc/neutron/plugins/ml2/openvswitch_agent.ini
scp /tmp/Compute-ml2 root@compute1:/etc/neutron/plugins/ml2/ml2_conf.ini
scp /tmp/Compute-OVSagent root@compute1:/etc/neutron/plugins/ml2/openvswitch_agent.ini
ssh root@controller "chown -R neutron:neutron /etc/neutron/"
ssh root@network1 "chown -R neutron:neutron /etc/neutron/"
ssh root@compute1 "chown -R neutron:neutron /etc/neutron/"
#
echo
echo "---> Rebuilding Neutron Database..."
ssh root@controller << EOF
mysql -u root -Bse "DROP DATABASE neutron;"
mysql -u root -Bse "CREATE DATABASE neutron;"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'equiinfra';"
mysql -u root -Bse "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'equiinfra';"
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
EOF
#
echo
echo "---> Restarting Service..."
ssh root@controller "systemctl restart openstack-nova-api.service"
ssh root@controller "systemctl restart neutron-server.service"
ssh root@network1 "systemctl restart openvswitch.service"
ssh root@network1 "systemctl restart neutron-dhcp-agent.service"
ssh root@network1 "systemctl restart neutron-metadata-agent.service"
ssh root@network1 "systemctl restart neutron-l3-agent.service"
ssh root@compute1 "systemctl restart openvswitch.service"
#
echo
echo "---> Installing ODL Neutron Server..."
echo
ssh root@controller << EOF
#cd /tmp
#git clone -b stable/ocata https://github.com/openstack/networking-odl
#cd /tmp/networking-odl
pip install networking-odl
#
#wget https://launchpadlibrarian.net/306652577/networking-odl-4.0.0.tar.gz
#tar zxvf networking-odl-4.0.0.tar.gz
#cd /tmp/networking-odl-4.0.0
#
#python setup.py install
sleep 1
systemctl enable neutron-server.service
systemctl restart neutron-server.service
EOF
echo
echo "Waiting for ODL-Neutron Server..."
sleep 15
echo "Constructing Networking Components..."
echo
echo "source /etc/keystone/admin-openrc.sh
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
neutron router-gateway-set router provider" > /tmp/Controller-Build.sh
#
scp /tmp/Controller-Build.sh root@controller:/tmp/Controller-Build.sh
ssh root@controller "chmod +x /tmp/Controller-Build.sh"
ssh root@controller "/tmp/Controller-Build.sh"
echo
## http://sciencecloud-community.cs.tu.ac.th/?p=238
## https://wiki.opendaylight.org/view/OpenStack_and_OpenDaylight
echo
yum autoremove -y
echo
echo -en " #################################### " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " ODL IS READY ! ############################"
sleep 1
echo
echo " --> Before u begin using you have to do the following:"
echo " 1- ODL Dashboard Available @http://$MYIP:8181/index.html"
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
