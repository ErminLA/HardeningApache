#!/bin/bash

wget https://github.com/ErminLA/HardeningApache/archive/master.zip
yum install unzip -y
unzip master.zip
mkdir /home/cloud_user/Backend
mv HardeningApache-master/app.py /home/cloud_user/Backend/
chown -Rv cloud_user:cloud_user /home/cloud_user/Backend/
mv HardeningApache-master/flaskapp.service /etc/systemd/system/
yum install epel-release -y
yum install python36.x86_64 -y
yum install python36-devel.x86_64 -y
yum groupinstall "Development Tools" -y
yum install python36-pip -y
ln -s /usr/local/bin/pip3 /usr/bin/pip3
pip3 install Flask
pip3 install flask-cors
pip3 install psutil
yum install tcpdump -y

yum install firewalld -y
systemctl start firewalld
firewall-cmd --permanent --add-port=65535/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --reload
systemctl enable firewalld

yum install httpd -y
systemctl start httpd
systemctl enable httpd

systemctl daemon-reload
systemctl start flaskapp.service
systemctl enable flaskapp

hostname="$(cat /etc/hostname)"
mkdir -p /var/www/$hostname/html
mkdir -p /var/www/$hostname/log

chown cloud_user:cloud_user /var/www/$hostname/html/
chown cloud_user:cloud_user /var/www/$hostname/
chown cloud_user:cloud_user /var/www/$hostname/log/

mv HardeningApache-master/index.html /var/www/$hostname/html/
sed -i \"s/$hostname/$MyStr/g\" /var/www/$hostname/html/index.html

mkdir /etc/httpd/sites-available
mkdir /etc/httpd/sites-enabled
echo "IncludeOptional sites-enabled/*.conf" >> /etc/httpd/conf/httpd.conf

echo "<VirtualHost *:80>
	ServerName www.$hostname
	ServerAlias $hostname
	DocumentRoot /var/www/$hostname/html
	ErrorLog /var/www/$hostname/log/error.log
	CustomLog /var/www/$hostname/log/requests.log 	combined
</VirtualHost>" > /etc/httpd/sites-available/ermin1c.mylabserver.com.conf

ln -s /etc/httpd/sites-available/ermin1c.mylabserver.com.conf /etc/httpd/sites-enabled/ermin1c.mylabserver.com.conf

