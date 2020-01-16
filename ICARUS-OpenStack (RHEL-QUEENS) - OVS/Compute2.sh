#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

##################### SCRIPT CONFIGURATION
port0=eth0                    #Mangment Network
port1=eth1                    #Provider Network
MYGW=172.17.14.1                   #MANGMENT GW
MNGsubnetMASK="255.255.255.0"   #Subnet Netmask
mystackname="Icarus-Compute2"   #Hostname
cloudaka="Icarus"               #Cloud Code Name
mydomain="equinoxme.com"        #Cloud Domain Name
controllerip=172.17.14.111          #Controller Node IP
REPOREAPER=10.0.0.101           #RepoReaper Source VM
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
echo " -> INSTALLS RedHat OpenStack 12 on RHEL 7.4"
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
echo "Preparing System..."
yum clean all
yum repolist
yum update -y
yum upgrade -y
yum install openssh openssh-server htop pydf unzip iftop make nano tcpdump gcc sudo dnsutils ntp ethtool nload fping nmap yum-utils net-tools wget telnet -y
yum install python-pip redhat-lsb-core -y
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
echo "
#Special Config Parameters For Fast SSH
UseDNS no
" >> /etc/ssh/sshd_config
echo
echo " #################################### Configuring Hosts Identification ############################"
echo
echo -en "Configuring Hosts File..."
echo "127.0.0.1       localhost.localdomain    localhost
$MYIP       compute2.$mydomain   compute2


##### $cloudaka-OpenStack Nodes
# MANG
172.17.14.1         resources.equinoxme.com resources
172.17.14.111       $cloudaka-Controller.$mydomain   $cloudaka-Controller  controller
172.17.14.121       $cloudaka-Network1.$mydomain     $cloudaka-Network1    network1
172.17.14.131       $cloudaka-Compute1.$mydomain     $cloudaka-Compute1    compute1
172.17.14.132       $cloudaka-Compute2.$mydomain     $cloudaka-Compute2    compute2
172.17.14.141       $cloudaka-Block1.$mydomain       $cloudaka-Block1      block1
172.17.14.151       $cloudaka-Object1.$mydomain      $cloudaka-Object1     object1" > /etc/hosts
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
echo "## Building Required Packages..."
echo
yum upgrade -y
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

linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
vif_plugging_is_fatal = True
vif_plugging_timeout = 300

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
#systemctl start libvirtd.service
#systemctl start openstack-nova-compute.service
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
yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch ebtables ipset -y
echo
echo -en " Configuring Neutron Engine..."
sleep 1
#cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.DEFAULT
echo "[DEFAULT]
core_plugin = ml2
transport_url = rabbit://openstack:equiinfra@controller
auth_strategy = keystone
service_plugins = router
state_path = /var/lib/neutron
allow_overlapping_ips = True

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
lock_path = /var/lib/neutron/tmp" > /etc/neutron/neutron.conf
echo "[OK]"
echo
echo -en " Configuring Ml2 Plugin..."
echo "[DEFAULT]

[ml2]
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = openvswitch,l2population
extension_drivers = port_security

[ml2_type_flat]
flat_networks = provider

[ml2_type_geneve]

[ml2_type_gre]

[ml2_type_vlan]

[ml2_type_vxlan]
vni_ranges = 1:1000

[securitygroup]
enable_ipset = True
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver" > /etc/neutron/plugins/ml2/ml2_conf.ini
echo "[OK]"
echo
echo -en " Configuring the OVS agent..."
sleep 1
echo "[DEFAULT]

[agent]
tunnel_types = vxlan
l2_population = True
prevent_arp_spoofing = True

[ovs]
local_ip = $MYIP
bridge_mappings = provider:br-provider

[securitygroup]
firewall_driver = iptables_hybrid
" > /etc/neutron/plugins/ml2/openvswitch_agent.ini
echo "[OK]"
echo
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
chown -R neutron:neutron /etc/neutron/
systemctl restart openstack-nova-compute.service
systemctl enable openvswitch.service
systemctl enable neutron-openvswitch-agent.service
systemctl start openvswitch.service
systemctl start neutron-openvswitch-agent.service
echo
echo -en " Creating OVS Bridge..."
sleep 1
ovs-vsctl add-br br-int
ovs-vsctl add-br br-provider
ovs-vsctl add-port br-provider $port1
echo "[OK]"
echo
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mCeilometer\033[0m" ;echo " ############################"
sleep 1
echo
echo "--->> Installing Packages..."
echo
sleep 1
yum install openstack-ceilometer-compute python-ceilometerclient python-pecan -y
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
echo -en " #################################### " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " Compute IS READY ! ############################"
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
