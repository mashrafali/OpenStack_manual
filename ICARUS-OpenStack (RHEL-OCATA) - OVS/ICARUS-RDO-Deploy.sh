#! /bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

##################### SCRIPT CONFIGURATION
#
#CONFIGURE USED PORTS:
###
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
####################################################
