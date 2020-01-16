#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

##################### SCRIPT CONFIGURATION
port0=eth0                      #Mangment Network
MYGW=172.17.14.1                #MANGMENT GW
MNGsubnetMASK="255.255.255.0"   #Subnet Netmask
mystackname="Icarus-Block1"     #Hostname
cloudaka="Icarus"               #Cloud Code Name
mydomain="equinoxme.com"        #Cloud Domain Name
controllerip=172.17.14.111      #Controller Node IP
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
echo -en "                                         " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack Block Auto Deployment   "
echo "                                                  Script by Mohamed Ashraf "
echo
echo
echo " -> Please run this script as root! "
echo " -> INSTALLS RedHat OpenStack 12 on RHEL 7.4"
echo
echo " Parameters INFO:"
echo "-----------------"
echo " - Mangment Network IP will be used from $port0 : $MYIP"
echo " - Block Backend will be used on /dev/vda"
echo " - Manila Backend will be used on /dev/vdc"
echo " - Linking Block Node to Controller Node of IP : $controllerip"
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
$MYIP       block1.$mydomain block1


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
sed -i 's$# Configuration option devices/dir.$filter = [ "a/vda/", "a/vdc/", "r/.*/"]$g' /etc/lvm/lvm.conf
echo "[OK]"
echo
pvcreate /dev/vda
vgcreate cinder-volumes /dev/vda
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
pvcreate /dev/vdc
vgcreate manila-volumes /dev/vdc
mkdir -p /var/lib/manila/
chown -R manila:manila /var/lib/manila/
echo
systemctl enable openstack-manila-share.service
systemctl enable target.service
systemctl start openstack-manila-share.service
systemctl start target.service
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
echo -en " #################################### " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " Block IS READY ! ############################"
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
