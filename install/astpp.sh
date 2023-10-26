#!/bin/bash

#################################
##########  variables ###########
#################################

#General Congifuration
TEMP_USER_ANSWER="yes"
ASTPP_SOURCE_DIR=/opt/astpp
ASTPP_HOST_DOMAIN_NAME="astpp.innotel.us"
IS_ENTERPRISE="False"

#ASTPP Configuration
ASTPPDIR=/var/lib/astpp/
ASTPPEXECDIR=/usr/local/astpp/
ASTPPLOGDIR=/var/log/astpp/

#Freeswich Configuration
FS_DIR=/usr/share/freeswitch
FS_SOUNDSDIR=${FS_DIR}/sounds/en/us/callie

#HTML and Mysql Configuraition
WWWDIR=/var/www/html
ASTPP_DATABASE_NAME="astpp"
ASTPP_DB_USER="astppuser"

MYSQL_ROOT_PASSWORD=DD@l1lama
ASTPPUSER_MYSQL_PASSWORD=DD@l1lama

wget --http-user=signalwire --http-password=pat_Uo42CTrcKR19H58uqgtpj9qB -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg

#Install Prerequisties

systemctl stop apache2
systemctl disable apache2
apt install -y sudo
apt-get update
apt-get install -y wget curl git dnsutils ntpdate systemd net-tools whois sendmail-bin sensible-mda mlocate vim imagemagick


#Fetch ASTPP Source

cd /opt
git clone https://github.com/innotelinc/astpp.git
	

#Install PHP

cd /usr/src
apt -y install lsb-release apt-transport-https ca-certificates
add-apt-repository -y ppa:ondrej/php
apt-get update
apt install -y php7.4 php7.4-fpm php7.4-mysql php7.4-cli php7.4-json php7.4-readline php7.4-xml php7.4-curl php7.4-gd php7.4-json php7.4-mbstring php7.4-opcache php7.4-imap php7.4-geoip php-pear php7.4-imagick libreoffice ghostscript
apt purge php8.*
systemctl stop apache2
systemctl disable apache2

#Install Mysql

cd /usr/src
apt install gnupg -y
sudo apt install dirmngr --install-recommends
apt-get install software-properties-common -y
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 467B942D3A79BD29
sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 3A79BD29

apt -y install mysql-apt-config
apt update -y
apt-get install unixodbc unixodbc-dev
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)"
DEBIAN_FRONTEND=noninteractive apt install mysql-server

cd /opt/astpp/misc/
tar -xzvf odbc.tar.gz
mkdir -p /usr/lib/x86_64-linux-gnu/odbc/.
cp -rf odbc/libmyodbc8* /usr/lib/x86_64-linux-gnu/odbc/.

###CHECK
#cd /usr/src
#tar zxf mariadb-connector-odbc-3.1.19-ubuntu-focal-amd64.tar.gz
#cd mariadb-connector-odbc-3.1.19-ubuntu-focal-amd64
#install lib/mariadb/libmaodbc.so /usr/lib64/
#install -d /usr/lib64/mariadb/
#install -d /usr/lib64/mariadb/plugin/
###CHECK

#Normalize mysql installation

cp ${ASTPP_SOURCE_DIR}/misc/odbc/deb_odbc.ini /etc/odbc.ini
                             
sed -i '28i wait_timeout=600' /etc/mysql/conf.d/mysql.cnf
sed -i '28i interactive_timeout = 600' /etc/mysql/conf.d/mysql.cnf
sed -i '28i sql_mode=""' /etc/mysql/conf.d/mysql.cnf
sed -i '33i log_bin_trust_function_creators = 1' /etc/mysql/conf.d/mysql.cnf
sed -i '28i [mysqld]' /etc/mysql/conf.d/mysql.cnf
systemctl restart mysql
systemctl enable mysql


#Install ASTPP with dependencies
 
apt update
apt install -y nginx ntpdate ntp lua5.1 bc libxml2 libxml2-dev openssl libcurl4-openssl-dev gettext gcc g++
mkdir -p ${ASTPPDIR}
mkdir -p ${ASTPPLOGDIR}
mkdir -p ${ASTPPEXECDIR}
mkdir -p ${WWWDIR}
cp -rf ${ASTPP_SOURCE_DIR}/config/astpp-config.conf ${ASTPPDIR}astpp-config.conf
cp -rf ${ASTPP_SOURCE_DIR}/config/astpp.lua ${ASTPPDIR}astpp.lua
ln -s ${ASTPP_SOURCE_DIR}/web_interface/astpp ${WWWDIR}
ln -s ${ASTPP_SOURCE_DIR}/freeswitch/fs ${WWWDIR}

#Normalize astpp installation

sudo apt-get install -y locales-all
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt
sudo apt-get install -y locales-all
#/bin/cp /usr/src/ioncube/ioncube_loader_lin_7.3.so /usr/lib/php/20180731/
#sed -i '2i zend_extension ="/usr/lib/php/20180731/ioncube_loader_lin_7.3.so"' /etc/php/7.3/fpm/php.ini
#sed -i '2i zend_extension ="/usr/lib/php/20180731/ioncube_loader_lin_7.3.so"' /etc/php/7.3/cli/php.ini
cp -rf ${ASTPP_SOURCE_DIR}/web_interface/nginx/deb_astpp.conf /etc/nginx/conf.d/astpp.conf
systemctl start nginx
systemctl enable nginx
systemctl start php7.4-fpm
systemctl enable php7.4-fpm
chown -Rf root.root ${ASTPPDIR}
chown -Rf www-data.www-data ${ASTPPLOGDIR}
chown -Rf root.root ${ASTPPEXECDIR}
chown -Rf www-data.www-data ${WWWDIR}/astpp
chown -Rf www-data.www-data ${ASTPP_SOURCE_DIR}/web_interface/astpp
chmod -Rf 755 ${WWWDIR}/astpp
sed -i "s/;request_terminate_timeout = 0/request_terminate_timeout = 300/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s#short_open_tag = Off#short_open_tag = On#g" /etc/php/7.4/fpm/php.ini
sed -i "s#;cgi.fix_pathinfo=1#cgi.fix_pathinfo=1#g" /etc/php/7.4/fpm/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = 3000/" /etc/php/7.4/fpm/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 20M/" /etc/php/7.4/fpm/php.ini
sed -i "s/post_max_size = 8M/post_max_size = 20M/" /etc/php/7.4/fpm/php.ini
sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php/7.4/fpm/php.ini
systemctl restart php7.4-fpm
CRONPATH='/var/spool/cron/crontabs/astpp'

echo "# To call all crons   
* * * * * cd ${ASTPP_SOURCE_DIR}/web_interface/astpp/cron/ && php cron.php crons
" > $CRONPATH
chmod 600 $CRONPATH
crontab $CRONPATH
touch /var/log/astpp/astpp.log
touch /var/log/astpp/astpp_email.log
chmod -Rf 755 $ASTPP_SOURCE_DIR
chmod -Rf 777 /opt/astpp/
chmod -Rf 777 /opt/astpp/*
chmod -Rf 777 /opt/astpp
chmod 777 /var/log/astpp/astpp.log
chmod 777 /var/log/astpp/astpp_email.log
sed -i "s#dbpass = <PASSSWORD>#dbpass = ${ASTPPUSER_MYSQL_PASSWORD}#g" ${ASTPPDIR}astpp-config.conf
sed -i "s#DB_PASSWD=\"<PASSSWORD>\"#DB_PASSWD = \"${ASTPPUSER_MYSQL_PASSWORD}\"#g" ${ASTPPDIR}astpp.lua
sed -i "s#base_url=https://localhost:443/#base_url=https://${ASTPP_HOST_DOMAIN_NAME}/#g" ${ASTPPDIR}/astpp-config.conf
sed -i "s#PASSWORD = <PASSWORD>#PASSWORD = ${ASTPPUSER_MYSQL_PASSWORD}#g" /etc/odbc.ini
systemctl restart nginx

#Install freeswitch with dependencies

echo "Installing FREESWITCH"
sleep 6s
apt-get update && apt-get install -y gnupg2 wget lsb-release
sleep 2s
                
mv -f ${FS_DIR}/scripts /tmp/.
ln -s ${ASTPP_SOURCE_DIR}/freeswitch/fs ${WWWDIR}
ln -s ${ASTPP_SOURCE_DIR}/freeswitch/scripts ${FS_DIR}
cp -rf ${ASTPP_SOURCE_DIR}/freeswitch/sounds/*.wav ${FS_SOUNDSDIR}/
cp -rf ${ASTPP_SOURCE_DIR}/freeswitch/conf/autoload_configs/* /etc/freeswitch/autoload_configs/

#Normalize freeswitch installation

systemctl start freeswitch
systemctl enable freeswitch
sed -i "s#max-sessions\" value=\"1000#max-sessions\" value=\"2000#g" /etc/freeswitch/autoload_configs/switch.conf.xml
sed -i "s#sessions-per-second\" value=\"30#sessions-per-second\" value=\"50#g" /etc/freeswitch/autoload_configs/switch.conf.xml
sed -i "s#max-db-handles\" value=\"50#max-db-handles\" value=\"500#g" /etc/freeswitch/autoload_configs/switch.conf.xml
sed -i "s#db-handle-timeout\" value=\"10#db-handle-timeout\" value=\"30#g" /etc/freeswitch/autoload_configs/switch.conf.xml
rm -rf  /etc/freeswitch/dialplan/*
touch /etc/freeswitch/dialplan/astpp.xml
rm -rf  /etc/freeswitch/directory/*
touch /etc/freeswitch/directory/astpp.xml
rm -rf  /etc/freeswitch/sip_profiles/*
touch /etc/freeswitch/sip_profiles/astpp.xml
chmod -Rf 755 ${FS_SOUNDSDIR}
chmod -Rf 777 /opt/astpp/
chmod -Rf 777 /usr/share/freeswitch/scripts/astpp/lib
chmod -Rf 777 /var/lib/freeswitch/recordings
chmod -Rf 777 /var/lib/freeswitch/recordings/*
cp -rf ${ASTPP_SOURCE_DIR}/web_interface/nginx/deb_fs.conf /etc/nginx/conf.d/fs.conf
chown -Rf root.root ${WWWDIR}/fs
chmod -Rf 755 ${WWWDIR}/fs
/bin/systemctl restart freeswitch
/bin/systemctl enable freeswitch

#Install Database for ASTPP
mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} create ${ASTPP_DATABASE_NAME}
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER 'astppuser'@'localhost' IDENTIFIED BY '${ASTPPUSER_MYSQL_PASSWORD}';"
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "ALTER USER 'astppuser'@'localhost' IDENTIFIED WITH mysql_native_password BY '${ASTPPUSER_MYSQL_PASSWORD}';"
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON \`${ASTPP_DATABASE_NAME}\` . * TO 'astppuser'@'localhost' WITH GRANT OPTION;FLUSH PRIVILEGES;"
mysql -uroot -p${MYSQL_ROOT_PASSWORD} astpp < ${ASTPP_SOURCE_DIR}/database/astpp-6.0.sql
mysql -uroot -p${MYSQL_ROOT_PASSWORD} astpp < ${ASTPP_SOURCE_DIR}/database/astpp-6.0.1.sql

#Firewall Configuration

apt install -y firewalld
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-port=22/tcp
firewall-cmd --permanent --zone=public --add-port=5060/udp
firewall-cmd --permanent --zone=public --add-port=5060/tcp
firewall-cmd --permanent --zone=public --add-port=16384-32767/udp
firewall-cmd --reload
        

#Install Fail2ban for security

apt-get update -y
sleep 2s
apt-get install fail2ban -y
sleep 2s
echo ""
read -p "Enter Client's Notification email address: ${NOTIEMAIL}"
NOTIEMAIL=${REPLY}
echo ""
read -p "Enter sender email address: ${NOTISENDEREMAIL}"
NOTISENDEREMAIL=${REPLY}
cd /usr/src
#wget --no-check-certificate --max-redirect=0 https://latest.astppbilling.org/fail2ban_Deb.tar.gz
#tar xzvf fail2ban_Deb.tar.gz
mv /etc/fail2ban /tmp/
cd ${ASTPP_SOURCE_DIR}/misc/
tar -xzvf fail2ban_deb10.tar.gz
cp -rf ${ASTPP_SOURCE_DIR}/misc/fail2ban_deb10 /etc/fail2ban
#cp -rf /usr/src/fail2ban /etc/fail2ban
#cp -rf ${ASTPP_SOURCE_DIR}/misc/deb_files/fail2ban/jail.local /etc/fail2ban/jail.local

sed -i -e "s/{INTF}/${INTF}/g" /etc/fail2ban/jail.local
sed -i -e "s/{NOTISENDEREMAIL}/${NOTISENDEREMAIL}/g" /etc/fail2ban/jail.local
sed -i -e "s/{NOTIEMAIL}/${NOTIEMAIL}/g" /etc/fail2ban/jail.local

mkdir /var/run/fail2ban
chkconfig fail2ban on
systemctl restart fail2ban
systemctl enable fail2ban


#Install Monit for service monitoring

cd /usr/src/
sudo apt-get update -y
sudo apt-get install monit -y
sed -i -e 's/# set mailserver mail.innotel.us,/set mailserver localhost/g' /etc/monit/monitrc
sed -i -e '/# set mail-format { from: monit@foo.bar }/a set alert '$EMAIL /etc/monit/monitrc
sed -i -e 's/##   subject: monit alert on --  $EVENT $SERVICE/   subject: monit alert --  $EVENT $SERVICE/g' /etc/monit/monitrc
sed -i -e 's/##   subject: monit alert --  $EVENT $SERVICE/   subject: monit alert on '${INTF}' --  $EVENT $SERVICE/g' /etc/monit/monitrc
sed -i -e 's/## set mail-format {/set mail-format {/g' /etc/monit/monitrc
sed -i -e 's/## }/ }/g' /etc/monit/monitrc
echo '
#------------MySQL
check process mysqld with pidfile /var/run/mysqld/mysqld.pid
    start program = "/bin/systemctl start mysqld"
    stop program = "/bin/systemctl stop mysqld"
if failed host 127.0.0.1 port 3306 then restart
if 5 restarts within 5 cycles then timeout

#------------Fail2ban
check process fail2ban with pidfile /var/run/fail2ban/fail2ban.pid
    start program = "/bin/systemctl start fail2ban"
    stop program = "/bin/systemctl stop fail2ban"

# ---- FreeSWITCH ----
check process freeswitch with pidfile /var/run/freeswitch/freeswitch.pid
    start program = "/bin/systemctl start freeswitch"
    stop program  = "/bin/systemctl stop freeswitch"

#-------nginx----------------------
check process nginx with pidfile /var/run/nginx.pid
    start program = "/bin/systemctl start nginx" with timeout 30 seconds
    stop program  = "/bin/systemctl stop nginx"
    
#-------php-fpm----------------------
check process php-fpm with pidfile /var/run/php-fpm/php-fpm.pid
    start program = "/bin/systemctl start php-fpm" with timeout 30 seconds
    stop program  = "/bin/systemctl stop php-fpm"

#--------system
check system localhost
    if loadavg (5min) > 8 for 4 cycles then alert
    if loadavg (15min) > 8 for 4 cycles then alert
    if memory usage > 80% for 4 cycles then alert
    if swap usage > 20% for 4 cycles then alert
    if cpu usage (user) > 80% for 4 cycles then alert
    if cpu usage (system) > 20% for 4 cycles then alert
    if cpu usage (wait) > 20% for 4 cycles then alert

check filesystem "root" with path /
    if space usage > 80% for 1 cycles then alert' >> /etc/monitrc
sleep 1s
systemctl restart monit
systemctl enable monit

#Configure logrotation for maintain log size

sed -i -e 's/daily/size 30M/g' /etc/logrotate.d/rsyslog
sed -i -e 's/weekly/size 30M/g' /etc/logrotate.d/rsyslog
sed -i -e 's/rotate 7/rotate 5/g' /etc/logrotate.d/rsyslog
sed -i -e 's/weekly/size 30M/g' /etc/logrotate.d/php7.4-fpm
sed -i -e 's/rotate 12/rotate 5/g' /etc/logrotate.d/php7.4-fpm
sed -i -e 's/weekly/size 30M/g' /etc/logrotate.d/nginx
sed -i -e 's/rotate 52/rotate 5/g' /etc/logrotate.d/nginx
sed -i -e 's/weekly/size 30M/g' /etc/logrotate.d/fail2ban
sed -i -e 's/weekly/size 30M/g' /etc/logrotate.d/monit

#Remove all downloaded and temp files from server

cd /usr/src
rm -rf fail2ban* GNU-AGPLv3.6.txt install.sh mysql80-community-release-el7-1.noarch.rpm
systemctl restart freeswitch
