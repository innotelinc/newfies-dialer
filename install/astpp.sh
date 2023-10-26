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
FS_DIR=/usr/local/freeswitch
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

apt install -y mariadb-client libmariadb3 mariadb-server

cd /usr/src
wget https://dlm.mariadb.com/3286241/Connectors/odbc/connector-odbc-3.1.19/mariadb-connector-odbc-3.1.19-ubuntu-focal-amd64.tar.gz
tar zxf mariadb-connector-odbc-3.1.19-ubuntu-focal-amd64.tar.gz
cd mariadb-connector-odbc-3.1.19-ubuntu-focal-amd64
install lib/mariadb/libmaodbc.so /usr/lib64/
install -d /usr/lib64/mariadb/
install -d /usr/lib64/mariadb/plugin/
install lib/mariadb/plugin/caching_sha2_password.so /usr/lib64/mariadb/plugin/
install lib/mariadb/plugin/client_ed25519.so /usr/lib64/mariadb/plugin/
install lib/mariadb/plugin/dialog.so /usr/lib64/mariadb/plugin/
install lib/mariadb/plugin/mysql_clear_password.so /usr/lib64/mariadb/plugin/
install lib/mariadb/plugin/sha256_password.so /usr/lib64/mariadb/plugin/
systemctl restart mariadb

apt -y install default-libmysqlclient-dev unixodbc unixodbc-dev

cd /opt/astpp/misc/
tar -xzvf odbc.tar.gz
mkdir -p /usr/lib/x86_64-linux-gnu/odbc/.
cp -rf odbc/libmyodbc8* /usr/lib/x86_64-linux-gnu/odbc/.

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
* * * * * cd ${ASTPP_SOURCE_DIR}/web_interface/astpp/cron/ && php cron.php crons" > $CRONPATH

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

apt-get -y update
apt-get -y install locales-all

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
locale-gen es_ES.UTF-8
locale-gen fr_FR.UTF-8
locale-gen pt_BR.UTF-8

apt-get -y install unzip zip sox sqlite3 ncftp nmap gnupg2 wget lsb-release
apt-get -y install autoconf2.64 automake autotools-dev binutils bison build-essential cpp curl flex gcc libaudiofile-dev libc6-dev libexpat1 libexpat1-dev mcrypt libmcrypt-dev libnewt-dev libpopt-dev libsctp-dev libx11-dev libxml2 libxml2-dev lksctp-tools lynx m4 openssl ssl-cert zlib1g-dev
apt-get -y install autoconf automake devscripts gawk g++ git libjpeg-dev ibjpeg62-turbo-dev libncurses5-dev libtool-bin libtool make python-dev-is-python3 gawk pkg-config libtiff5-dev libperl-dev libgdbm-dev libdb-dev gettext libssl-dev libcurl4-openssl-dev libpcre3-dev libspeex-dev libspeexdsp-dev libsqlite3-dev libedit-dev libldns-dev libpq-dev libmp3lame-dev
apt-get -y install libgnutls28-dev libtiff5-dev libtiff5
apt-get -y install libvorbis0a libogg0 libogg-dev libvorbis-dev
apt-get -y install flite flite1-dev
apt-get -y install unixodbc-dev odbc-postgresql
apt -y autoremove

/usr/sbin/groupadd -r -f freeswitch
/usr/sbin/useradd -r -c "freeswitch" -g freeswitch freeswitch

cd /usr/src
git clone https://github.com/innotelinc/spandsp.git
cd spandsp
./bootstrap.sh && ./configure && make && make install
ldconfig
cd ..
git clone https://github.com/innotelinc/sofia-sip.git
cd sofia-sip
./bootstrap.sh && ./configure && make && make install
ldconfig
cd ..
git clone https://github.com/innotelinc/libks.git
cd libks
cmake . && make && make install
cd ..
git clone https://github.com/innotelinc/signalwire-c.git
cd signalwire-c
cmake . && make && make install
cd ..
git clone https://github.com/xiph/speex.git
cd speex
./autogen.sh && ./configure && make && make install
cd ..
git clone https://github.com/xiph/speexdsp.git
cd speexdsp
./autogen.sh && ./configure && make && make install

cd /usr/src
git clone https://github.com/innotelinc/freeswitch.git
cd freeswitch
./bootstrap.sh -j
autoupdate
./configure

[ -f modules.conf ] && cp modules.conf modules.conf.bak
sed -i -e \
"s/#applications\/mod_curl/applications\/mod_curl/g" \
-e "s/#applications\/mod_avmd/applications\/mod_avmd/g" \
-e "s/#asr_tts\/mod_flite/asr_tts\/mod_flite/g" \
-e "s/#asr_tts\/mod_tts_commandline/asr_tts\/mod_tts_commandline/g" \
-e "s/#formats\/mod_shout/formats\/mod_shout/g" \
-e "s/#endpoints\/mod_dingaling/endpoints\/mod_dingaling/g" \
-e "s/#formats\/mod_shell_stream/formats\/mod_shell_stream/g" \
-e "s/#say\/mod_say_de/say\/mod_say_de/g" \
-e "s/#say\/mod_say_es/say\/mod_say_es/g" \
-e "s/#say\/mod_say_fr/say\/mod_say_fr/g" \
-e "s/#say\/mod_say_it/say\/mod_say_it/g" \
-e "s/#say\/mod_say_nl/say\/mod_say_nl/g" \
-e "s/#say\/mod_say_ru/say\/mod_say_ru/g" \
-e "s/#say\/mod_say_zh/say\/mod_say_zh/g" \
-e "s/#say\/mod_say_hu/say\/mod_say_hu/g" \
-e "s/#say\/mod_say_th/say\/mod_say_th/g" \
-e "s/#xml_int\/mod_xml_cdr/xml_int\/mod_xml_cdr/g" \
-e "s/#xml_int\/mod_xml_curl/xml_int\/mod_xml_curl/g" \
-e "s/#event_handlers\/mod_json_cdr/event_handlers\/mod_json_cdr/g" \
modules.conf

make && make install && make sounds-install && make moh-install && make cd-moh-install && make cd-sounds-install
ln -s /usr/local/freeswitch/conf /etc/freeswitch
chown -R freeswitch:freeswitch /usr/local/freeswitch /etc/freeswitch

mv -f ${FS_DIR}/scripts /tmp/.
ln -s ${ASTPP_SOURCE_DIR}/freeswitch/fs ${WWWDIR}
ln -s ${ASTPP_SOURCE_DIR}/freeswitch/scripts ${FS_DIR}
cp -rf ${ASTPP_SOURCE_DIR}/freeswitch/sounds/*.wav ${FS_SOUNDSDIR}/
cp -rf ${ASTPP_SOURCE_DIR}/freeswitch/conf/autoload_configs/* /etc/freeswitch/autoload_configs/

#Normalize freeswitch installation

adduser --disabled-password  --quiet --system --home /usr/local/freeswitch --gecos "FreeSWITCH Voice Platform" --ingroup daemon freeswitch
chown -R freeswitch:daemon /usr/local/freeswitch/ 
chmod -R o-rwx /usr/local/freeswitch/

nano /etc/init.d/freeswitch

#!/bin/bash
### BEGIN INIT INFO
# Provides:          freeswitch
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       Freeswitch debian init script.
# Author:            Matthew Williams
#
### END INIT INFO
# Do NOT "set -e"

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin
DESC="Freeswitch"
NAME=freeswitch
DAEMON=/usr/local/freeswitch/bin/$NAME
DAEMON_ARGS="-nc"
PIDFILE=/usr/local/freeswitch/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

FS_USER=freeswitch
FS_GROUP=daemon

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

#
# Function that sets ulimit values for the daemon
#
do_setlimits() {
        ulimit -c unlimited
        ulimit -d unlimited
        ulimit -f unlimited
        ulimit -i unlimited
        ulimit -n 999999
        ulimit -q unlimited
        ulimit -u unlimited
        ulimit -v unlimited
        ulimit -x unlimited
        ulimit -s 240
        ulimit -l unlimited
        return 0
}

#
# Function that starts the daemon/service
#
do_start()
{
    # Set user to run as
        if [ $FS_USER ] ; then
      DAEMON_ARGS="`echo $DAEMON_ARGS` -u $FS_USER"
        fi
    # Set group to run as
        if [ $FS_GROUP ] ; then
          DAEMON_ARGS="`echo $DAEMON_ARGS` -g $FS_GROUP"
        fi

        # Return
        #   0 if daemon has been started
        #   1 if daemon was already running
        #   2 if daemon could not be started
        start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON --test > /dev/null -- \
                || return 1
        do_setlimits
        start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON --background -- \
                $DAEMON_ARGS \
                || return 2
        # Add code here, if necessary, that waits for the process to be ready
        # to handle requests from services started subsequently which depend
        # on this one.  As a last resort, sleep for some time.
}

#
# Function that stops the daemon/service
#
do_stop()
{
        # Return
        #   0 if daemon has been stopped
        #   1 if daemon was already stopped
        #   2 if daemon could not be stopped
        #   other if a failure occurred
        start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --name $NAME
        RETVAL="$?"
        [ "$RETVAL" = 2 ] && return 2
        # Wait for children to finish too if this is a daemon that forks
        # and if the daemon is only ever run from this initscript.
        # If the above conditions are not satisfied then add some other code
        # that waits for the process to drop all resources that could be
        # needed by services started subsequently.  A last resort is to
        # sleep for some time.
        start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
        [ "$?" = 2 ] && return 2
        # Many daemons don't delete their pidfiles when they exit.
        rm -f $PIDFILE
        return "$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
        #
        # If the daemon can reload its configuration without
        # restarting (for example, when it is sent a SIGHUP),
        # then implement that here.
        #
        start-stop-daemon --stop --signal 1 --quiet --pidfile $PIDFILE --name $NAME
        return 0
}

case "$1" in
  start)
        [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
        do_start
        case "$?" in
                0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
                2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
  stop)
        [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
        do_stop
        case "$?" in
                0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
                2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
  status)
       status_of_proc -p $PIDFILE $DAEMON $NAME && exit 0 || exit $?
       ;;
  #reload|force-reload)
        #
        # If do_reload() is not implemented then leave this commented out
        # and leave 'force-reload' as an alias for 'restart'.
        #
        #log_daemon_msg "Reloading $DESC" "$NAME"
        #do_reload
        #log_end_msg $?
        #;;
  restart|force-reload)
        #
        # If the "reload" option is implemented then remove the
        # 'force-reload' alias
        #
        log_daemon_msg "Restarting $DESC" "$NAME"
        do_stop
        case "$?" in
          0|1)
                do_start
                case "$?" in
                        0) log_end_msg 0 ;;
                        1) log_end_msg 1 ;; # Old process is still running
                        *) log_end_msg 1 ;; # Failed to start
                esac
                ;;
          *)
                # Failed to stop
                log_end_msg 1
                ;;
        esac
        ;;
  *)
        #echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
        echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
        exit 3
        ;;
esac

exit 0

chmod +x /etc/init.d/freeswitch
update-rc.d freeswitch defaults
systemctl enable freeswitch
systemctl start freeswitch

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

systemctl restart freeswitch

#Install Database for ASTPP
mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} create ${ASTPP_DATABASE_NAME}
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER 'astppuser'@'localhost' IDENTIFIED BY '${ASTPPUSER_MYSQL_PASSWORD}';"
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "ALTER USER 'astppuser'@'localhost' IDENTIFIED BY '${ASTPPUSER_MYSQL_PASSWORD}';"
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON \`${ASTPP_DATABASE_NAME}\` . * TO 'astppuser'@'localhost' IDENTIFIED BY 'DD@l1lama';"
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
apt-get install fail2ban -y

echo ""
read -p "Enter Client's Notification email address: ${NOTIEMAIL}"
NOTIEMAIL=${REPLY}
echo ""
read -p "Enter sender email address: ${NOTISENDEREMAIL}"
NOTISENDEREMAIL=${REPLY}
cd /opt/astpp/misc/
tar -xzvf deb_files.tar.gz
mv /etc/fail2ban /tmp/
cp -rf /opt/astpp/misc/deb_files/fail2ban /etc/fail2ban

sed -i -e "s/{INTF}/${INTF}/g" /etc/fail2ban/jail.local
sed -i -e "s/{NOTISENDEREMAIL}/${NOTISENDEREMAIL}/g" /etc/fail2ban/jail.local
sed -i -e "s/{NOTIEMAIL}/${NOTIEMAIL}/g" /etc/fail2ban/jail.local

mkdir -p /var/run/fail2ban
ln -s /usr/local/freeswitch/log/ /var/log/freeswitch

nano /etc/fail2ban/jail.conf
[Freeswitch]
logpath  = /var/log/freeswitch/freeswitch.log

systemctl enable fail2ban
systemctl restart fail2ban

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
