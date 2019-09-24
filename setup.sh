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

systemctl daemon-reload
systemctl start flaskapp.service
systemctl enable flaskapp
