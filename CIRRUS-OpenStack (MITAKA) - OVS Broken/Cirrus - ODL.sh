#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

##################### SCRIPT CONFIGURATION
#CONFIGURE Below:
###
port0=eth0                      #Mangment Network
MYGW=10.0.0.1                   #MANGMENT GW
MNGsubnetMASK="255.255.255.0"   #Subnet Netmask
mystackname="Cirrus-ODL"        #Hostname
cloudaka="Cirrus"               #Cloud Code Name
mydomain="equinoxme.com"        #Cloud Domain Name
controllerip=10.0.0.11          #Controller Node IP
COWBRINGER=10.0.0.100           #Cow Bringer Source VM
####################################################
echo "##### ADJUST HOSTS FILE WITHIN THE SCRIPT AS DESIRED BEFORE BOOTSTRAP <<"
echo "-> Hit enter to begin"
read
echo "    >>>>>>>>>>>>>>>>>>>>>> MAKE SURE OPENSTACK NETWORK IS IN A FULL CLEAN SLATE STATE! <<<<<<<<<<<<<<<<<<<<<<<"
echo "-> Hit enter to begin"
read
MYIP=$(ifconfig $port0 | grep -i "inet addr:" | awk -F '[/:]' '{print $2}' | awk -F '[/ ]' '{print $1}')
clear
echo
echo -en "                                         " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack ODL Auto Deployment   "
echo "                                                  Script by Mohamed Ashraf "
echo
echo
echo " -> Please run this script as root! "
echo " -> INSTALLS OpenDayLight SDN Controller for MITAKA ON Ubuntu 14.04 LTS"
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
sleep 1
echo
sleep 1
apt-get update
apt-get dist-upgrade -y
apt-get upgrade -y
apt-get --purge autoremove -y
apt-get autoclean
apt-get install ssh htop pydf unzip iftop snmpd snmp make nano tcpdump gcc sudo dnsutils ntp ethtool nload fping nmap git -y
apt-get install sshpass -y
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
$MYIP       ODL.$mydomain ODL


##### $cloudaka-OpenStack Nodes
# MANG
$controllerip       $cloudaka-Controller.$mydomain   $cloudaka-Controller  controller
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
echo -en " #################################### Installing & Configuring "; echo  -en "\033[31;1mODL\033[0m" ;echo " ############################"
echo
sleep 1
echo "--->> Installing JRE 8 ..."
echo
sleep 1
add-apt-repository ppa:webupd8team/java -y
apt-get update && apt-get dist-upgrade -y && apt-get upgrade -y && apt-get --purge autoremove -y && apt-get autoclean
apt-get install oracle-java8-installer -y
echo
echo "--->> Fetching ODL Boron SR2 ..."
sleep 1
#wget -P /root/ODL-SOURCE https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/distribution-karaf/0.5.2-Boron-SR2/distribution-karaf-0.5.2-Boron-SR2.tar.gz
wget -P /root/ODL-SOURCE http://$COWBRINGER/openstack-images/distribution-karaf-0.5.2-Boron-SR2.tar.gz
echo
cd /root/
tar xvfz /root/ODL-SOURCE/distribution-karaf-0.5.2-Boron-SR2.tar.gz
echo
sleep 1
echo " Waiting for KARAF Container ..."
echo
/root/distribution-karaf-0.5.2-Boron-SR2/bin/start
sleep 5
/root/distribution-karaf-0.5.2-Boron-SR2/bin/status
echo
sed -i 's#exit 0#/root/distribution-karaf-0.5.2-Boron-SR2/bin/start#g' /etc/rc.local
echo "exit 0" >> /etc/rc.local
echo " Installing ODL Modules ..."
sleep
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-aaa-shiro\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-aaa-shiro"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-bgpcep-bgp\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-bgpcep-bgp"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-bgpcep-bmp\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-bgpcep-bmp"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-didm-all\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-didm-all"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-centinel-all\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-centinel-all"
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-dlux-all\033[0m"; echo " :"
/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-dlux-all"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-faas-all\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-faas-all"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-groupbasedpolicy-ofoverlay\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-groupbasedpolicy-ofoverlay"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-groupbasedpolicyi-ui\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-groupbasedpolicyi-ui"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-groupbasedpolicy-neutronmapper\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-groupbasedpolicy-neutronmapper"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-lispflowmapping-msmr\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-lispflowmapping-msmr"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-nemo-cli-renderer\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-nemo-cli-renderer"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-netide-rest\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-netide-rest"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-netconf-connector-ssh\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-netconf-connector-ssh"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-of-config-rest\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-of-config-rest"
echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-ovsdb-openstack\033[0m"; echo " :"
/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-ovsdb-openstack"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-ovsdb-southbound-impl-ui\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-ovsdb-southbound-impl-ui"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-ovsdb-hwvtepsouthbound-ui\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-ovsdb-hwvtepsouthbound-ui"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-ovsdb-sfc-ui\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-ovsdb-sfc-ui"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-openflowplugin-flow-services-ui\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-openflowplugin-flow-services-ui"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-ttp-all\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-ttp-all"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-bgpcep-pcep\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-bgpcep-pcep"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-restconf\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-restconf"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-sdninterfaceapp-all\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-sdninterfaceapp-all"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-sfclisp\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-sfclisp"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-sfc-sb-rest\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-sfc-sb-rest"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-snmp-plugin\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-snmp-plugin"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-snmp4sdn-all\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-snmp4sdn-all"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-aaa-sssd-plugin\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-aaa-sssd-plugin"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-sxp-controller\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-sxp-controller"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-tsdr-hsqldb-all\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-tsdr-hsqldb-all"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mTSDR Data Collectors\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-tsdr-openflow-statistics-collector, odl-tsdr-netflow-statistics-collector, odl-tsdr-snmp-data-collector, odl-tsdr-syslog-collector, odl-tsdr-controller-metrics-collector"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5mTSDR Data Stores\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-tsdr-hsqldb, odl-tsdr-hbase, or odl-tsdr-cassandra"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-topoprocessing-framework\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-topoprocessing-framework"
#echo -en "   ------>> FETCHING & LOADING "; echo  -en "\033[36;5modl-usc-channel-ui\033[0m"; echo " :"
#/root/distribution-karaf-0.5.2-Boron-SR2/bin/client -u karaf "feature:install odl-usc-channel-ui"
echo
echo " Installing Apache Redirect ..."
echo
sleep 1
apt-get install apache2 -y
a2enmod ssl > /dev/null 2>&1
a2enmod rewrite > /dev/null 2>&1
a2enmod ssl > /dev/null 2>&1
a2enmod proxy > /dev/null 2>&1
a2enmod proxy_http > /dev/null 2>&1
a2enmod proxy_ajp > /dev/null 2>&1
a2enmod file_cache > /dev/null 2>&1
a2enmod rewrite > /dev/null 2>&1
a2enmod deflate > /dev/null 2>&1
a2enmod headers > /dev/null 2>&1
a2enmod proxy_balancer > /dev/null 2>&1
a2enmod proxy_connect > /dev/null 2>&1
a2enmod proxy_html > /dev/null 2>&1
a2enmod cgi > /dev/null 2>&1
a2enmod cache > /dev/null 2>&1
a2enmod cache_disk > /dev/null 2>&1
a2enmod xml2enc > /dev/null 2>&1
a2enmod rewrite > /dev/null 2>&1
a2enmod expires > /dev/null 2>&1
a2enmod ssl > /dev/null 2>&1
a2enmod proxy > /dev/null 2>&1
a2enmod proxy_http > /dev/null 2>&1
a2enmod proxy_ajp > /dev/null 2>&1
a2enmod rewrite > /dev/null 2>&1
a2enmod deflate > /dev/null 2>&1
a2enmod headers > /dev/null 2>&1
a2enmod proxy_balancer > /dev/null 2>&1
a2enmod proxy_connect > /dev/null 2>&1
a2enmod proxy_html > /dev/null 2>&1
a2enmod cgi > /dev/null 2>&1
a2enmod cache > /dev/null 2>&1
a2enmod cache_disk > /dev/null 2>&1
a2enmod xml2enc > /dev/null 2>&1
a2enmod file_cache > /dev/null 2>&1
a2enmod expires > /dev/null 2>&1
echo "<VirtualHost *:80>
        RewriteEngine on
        Redirect / http://$MYIP:8181/index.html
#       RewriteCond %{REQUEST_URI} !^/index.html/
#       RewriteRule (.*) http://$MYIP:8181/index.html$1 [L,R]
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf
echo
service apache2 restart
echo






## http://sciencecloud-community.cs.tu.ac.th/?p=238

## LEAVE NODES UNTOUCHED, MAKE ODL NODE REMOTE CONFIGURE THE CHANGES REQUIRED.

















echo
echo -en " #################################### " ; echo  -en "\033[36;1m$cloudaka\033[0m" ; echo " OpenStack IS READY ! ############################"
sleep 1
echo
echo " --> Before u begin using you have to do the following:"
echo " 1- ODL Dashboard Available @http://$MYIP/"
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
