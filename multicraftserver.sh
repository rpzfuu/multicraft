#!/bin/bash
set -e

DAEMONNUM=1
EMAIL=nate@gmail.com.com
NAME="blah"
DOMAIN="hotdog.com"
KEY="no"
export DEBIAN_FRONTEND=noninteractive
PW="P@ssW0rD"

apt-get update -y&&apt-get install -y vim software-properties-common apache2 phpmyadmin mysql-server php libapache2-mod-php php-mcrypt php-mysql zip default-jre -y&&service mysql restart

echo "ServerName ${NAME}" >> /etc/apache2/apache2.conf&&service apache2 restart

apt-get install -y dialog expect

SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Press y|Y for Yes, any other key for No:\"
send \"y\r\"
expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG\"
send \"1\r\"
expect \"New password:\"
send \"$PW\r\"
expect \"Re-enter new password:\"
send \"$PW\r\"
expect \"Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect eof
")
echo "$SECURE_MYSQL"

sed -i 's/.*irectoryIndex.*/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/' /etc/apache2/mods-enabled/dir.conf

service apache2 restart

add-apt-repository -y ppa:certbot/certbot&&apt-get update&&apt-get install python-certbot-apache -y

CERTBOT=$(expect -c "
set timeout 10
spawn certbot --apache -d ${DOMAIN}
expect \"*cancel):\"
send \"$EMAIL\r\"
expect \"(A)gree/(C)ancel:\"
send \"a\r\"
expect \"(Y)es/(N)o:\"
send \"n\r\"
expect \"Re-enter new password:\"
send \"$PW\r\"
expect \"Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"
expect eof
")
echo "$CERTBOT"

service mysql start
mkdir -p /run/dbus
dbus-daemon --system

cd ~&&mkdir MulticraftInstllation;cd MulticraftInstllation

wget https://www.multicraft.org/download/linux64 -O multicraft.tar.gz&&tar xvzf multicraft.tar.gz

cd multicraft

MULTI=$(expect -c "
set timeout 10
spawn ./setup.sh
expect \"Run each Minecraft server under its own user? (Multicraft will create system users):\"
send \"y\r\"
expect \"Run Multicraft under this user:\"
send \"minecraft\r\"
expect \"User not found. Create user \'minecraft\' on start of installation?\"
send \"y\r\"
expect \"Install Multicraft in:\"
send \"\r\"
expect \"If you have a license key you can enter it now:\"
send \"$KEY\r\"
expect \"If you control multiple machines from one web panel you need to assign each daemon a unique number (requires a Dynamic or custom license). Daemon number?\"
send \"$DAEMONNUM\r\"
expect \"Will the web panel run on this machine?\"
send \"y\r\"
expect \"User of the webserver:\"
send \"\r\"
expect \"Location of the web panel files:\"
send \"\r\"
expect \"Please enter a new daemon password (use the same password in the last step of the panel installer)\"
send \"$PW\r\"
expect \"Enable builtin FTP server?\"
send \"\r\"
expect \"IP the FTP server will listen on (0.0.0.0 for all IPs):\"
send \"0.0.0.0\r\"
expect \"IP to use to connect to the FTP server (external IP):\"
send \"\r\"
expect \"FTP server port:\"
send \"\r\"
expect \"Block FTP upload of .jar files and other executables (potentially dangerous plugins)?\"
send \"\r\"
expect \"What kind of database do you want to use?\"
send \"mysql\r\"
expect \"Database host:\"
send \"\r\"
expect \"Database name:\"
send \"\r\"
expect \"Database user:\"
send \"\r\"
expect \"Database password:\"
send \"$PW\r\"
expect \"Path to java program:\"
send \"\r\"
expect \"Path to zip program:\"
send \"\r\" 
expect \"Press [Enter] to continue.\"
send \"\r\" 
expect \"Save entered settings?\"
send \"\r\" 
expect eof
")
echo "$MULTI"

PANELDB="multicraft_panel"
PPASSWDDB="${PW}panel"
mysql -uroot -p${PW} -e "CREATE DATABASE ${PANELDB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -uroot -p${PW} -e "CREATE USER ${PANELDB}@localhost IDENTIFIED BY '${PPASSWDDB}';"
mysql -uroot -p${PW} -e "GRANT ALL PRIVILEGES ON ${PANELDB}.* TO '${PANELDB}'@'localhost';"
mysql -uroot -p${PW} -e "FLUSH PRIVILEGES;"

DAEMONDB="multicraft_daemon"
DPASSWDDB="${PW}daemon"
mysql -uroot -p${PW} -e "CREATE DATABASE ${DAEMONDB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -uroot -p${PW} -e "CREATE USER ${DAEMONDB}@localhost IDENTIFIED BY '${DPASSWDDB}';"
mysql -uroot -p${PW} -e "GRANT ALL PRIVILEGES ON ${DAEMONDB}.* TO '${DAEMONDB}'@'localhost';"
mysql -uroot -p${PW} -e "FLUSH PRIVILEGES;"

clear
echo;echo
echo "Go to the web panel: http://your.address/multicraft/install.php"
echo "$PANELDB: $PANELDB / $PPASSWDDB"
echo "$DAEMONDB: $DAEMONDB / $DPASSWDDB"

echo
