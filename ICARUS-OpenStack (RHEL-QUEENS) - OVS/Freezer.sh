cd /root
useradd freezer
git clone https://git.openstack.org/openstack/freezer-api.git
cd freezer-api
pip install ./

yum install java-1.8.0-openjdk-headless
wget https://download.elasticsearch.org/elasticsearch/release/org/elasticsearch/distribution/rpm/elasticsearch/2.3.0/elasticsearch-2.3.0.rpm
yum install elasticsearch-2.3.0.rpm

openstack user create --domain default --password equiinfra freezer
openstack role add --project service --user freezer admin
openstack service create --name freezer --description "Backup" backup
openstack endpoint create --region RegionOne backup public http://controller:9090/
openstack endpoint create --region RegionOne backup internal http://controller:9090/
openstack endpoint create --region RegionOne backup admin http://controller:9090/

systemctl daemon-reload
systemctl enable elasticsearch
service elasticsearch restart

## CONFIG HERE
chown -R freezer:freezer /etc/freezer/
freezer-manage --config-file /etc/freezer/freezer-api.conf db sync
mkdir -p /var/log/freezer/
chown -R freezer:freezer /var/log/freezer/
mkdir -p /opt/stack/
cp -r /root/freezer-api/freezer_api /opt/stack/

#########################################
(Icarus-admin)root@Icarus-Controller:/etc/httpd/conf.d# cat freezer-api.conf 
Listen 9090

<VirtualHost *:9090>
    WSGIDaemonProcess freezer-api processes=2 threads=2 user=freezer display-name=%{GROUP}
    WSGIProcessGroup freezer-api
    WSGIApplicationGroup freezer-api
    WSGIScriptAlias / /opt/stack/freezer_api/cmd/wsgi.py

    <IfVersion >= 2.4>
      ErrorLogFormat "%M"
    </IfVersion>
    ErrorLog /var/log/freezer/freezer-api.log
    LogLevel warn
    CustomLog /var/log/freezer/freezer-api_access.log combined

    <Directory /opt/stack/freezer_api>
      Options Indexes FollowSymLinks MultiViews
      Require all granted
      AllowOverride None
      Order allow,deny
      allow from all
      LimitRequestBody 102400
    </Directory>
</VirtualHost>
#########################

cd /root
git clone https://git.openstack.org/openstack/freezer.git
cd freezer
pip install ./
cd



##BACKUP CMD
#freezer-agent  --action backup --nova-inst-id $inst_id --storage local --container /home/stack/serv1-bkp --backup-name serv1-bkp --mode nova --engine nova --no-incremental true --log-file /$file.log

##RESTORE CMD 
#freezer-agent  --action restore --nova-inst-id $inst_id  --storage local --container /home/stack/serv1-bkp --backup-name serv1-bkp --mode nova --engine nova --no-incremental true --log-file /$file.log

##VOLUME BACKUP 
#freezer-agent --action backup --cinder-vol-id $vol-id  --storage local --container /home/stack/vol-bkp --mode cinder --log-file /$file.log


##BACKUP ON REMOTE HOST
#freezer-agent --action backup --cinder-vol-id $vol_id --storage ssh --container /home/stack/cinder --backup-name $bkp-vol --mode cinder --ssh-host $IP --ssh-username $user_name --ssh-key /home/stack/.ssh/id_rsa.pub --log-file /$file.log

## PROJECT BACKUP 
#freezer-agent --action backup --project-id $ID --storage local --container /home/stack/$file --backup-name --mode nova --engine nova no-incremental true --log-file /$file.log


##ENCRYPT BACKUP
#Freezer-agent --mode cinder --cinder-vol-id $vol_id --encrypt-pass-file /home/oss/domain.key