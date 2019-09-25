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
sed -i "s/$hostname/$MyStr/g" /var/www/$hostname/html/index.html

mv HardeningApache-master/Linux\ Full\ Logo-01.png /var/www/$hostname/html/
chown cloud_user:cloud_user /var/www/$hostname/html/LA_Logo.png

mkdir /etc/httpd/sites-available
mkdir /etc/httpd/sites-enabled
echo "IncludeOptional sites-enabled/*.conf" >> /etc/httpd/conf/httpd.conf

echo "<VirtualHost *:80>
	ServerName www.$hostname
	ServerAlias $hostname
	DocumentRoot /var/www/$hostname/html
	ErrorLog /var/www/$hostname/log/error.log
	CustomLog /var/www/$hostname/log/requests.log 	combined
</VirtualHost>" > /etc/httpd/sites-available/$hostname.conf

ln -s /etc/httpd/sites-available/e$hostname.conf /etc/httpd/sites-enabled/$hostname.conf

semanage fcontext -a -t httpd_sys_content_t /var/www/$hostname/
semanage fcontext -a -t httpd_sys_content_t /var/www/$hostname/html/
semanage fcontext -a -t httpd_sys_content_t /var/www/$hostname/html/index.html
semanage fcontext -a -t httpd_sys_content_t /var/www/$hostname/html/LA_Logo.png

restorecon -v /var/www/$hostname/
restorecon -v /var/www/$hostname/html/
restorecon -v /var/www/$hostname/html/index.html
restorecon -v /var/www/$hostname/html/LA_Logo.png

semanage fcontext -a -t httpd_log_t /var/www/$hostname/log
semanage fcontext -a -t httpd_log_t /var/www/$hostname/log/error.log
semanage fcontext -a -t httpd_log_t /var/www/$hostname/log/requests.log

restorecon -v /var/www/$hostname/log
restorecon -v /var/www/$hostname/log/error.log
restorecon -v /var/www/$hostname/log/requests.log

yum install certbot -y
certbot -d $hostname
yum install python2-certbot-apache mod_ssl -y

#Answer questions
certbot --apache -d $hostname


#HSTS
# Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

sed -i '8iHeader always set Strict-Transport-Security "max-age=31536000; includeSubDomains"' /etc/httpd/sites-available/$hostname-le-ssl.conf
sed -i '9i\LimitRequestBody 500000000\nTimeOut 300\nKeepAliveTimeout 3\nLimitRequestFields 60\nLimitRequestFieldSize 4094\nOptions -Includes\nOptions -ExecCGI\n<Directory \"/var/www/$hostname/html/\">\nAllowOverride None\nRequire all granted\n<LimitExcept POST GET>\nDeny from all\n</LimitExcept>\n</Directory>\nLoadModule headers_module modules/mod_headers.so\nHeader edit Set-Cookie ^(.*)$ $1;HttpOnly;Secure\nHeader set X-XSS-Protection "1; mode=block"\nHeader always append X-Frame-Options DENY\nRewriteEngine On\nRewriteCond %{THE_REQUEST} !HTTP/1.1$\nRewriteRule .* - [F]\nOptions -FollowSymLinks\nHostnameLookups Off' /etc/httpd/sites-available/$hostname-le-ssl.conf

echo "MaxClient 150" >> /etc/httpd/conf/httpd.conf
echo "FileETag None" >> /etc/httpd/conf/httpd.conf
echo "ServerSignature Off" >> /etc/httpd/conf/httpd.conf
echo "ServerTokens Prod" >> /etc/httpd/conf/httpd.conf

systemctl restart httpd
