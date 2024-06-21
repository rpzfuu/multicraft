#!/bin/bash
set -e

clear
export DEBIAN_FRONTEND=noninteractive

PANELDB="multicraft_panel"
DAEMONDB="multicraft_daemon"

# Function to gather email input
gatherEmail() {
    echo "Enter the SYSADMIN email address, followed by [ENTER]:"
    echo -n ">"
    read EMAIL
    regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
    if [ -z "$EMAIL" ] || ! [[ $EMAIL =~ $regex ]]; then
        gatherEmail
    fi
}

# Function to gather domain input
gatherDomain() {
    echo "Enter the FQDN of the server (i.e. thewebsite.com), followed by [ENTER]:"
    echo -n ">"
    read DOMAIN
    if [ -z "$DOMAIN" ]; then
        gatherDomain
    fi
}

# Function to gather daemon number input
gatherDaemon() {
    echo "Enter the daemon number for this instance (if this is the only instance running here type '1'), followed by [ENTER]:"
    echo -n ">"
    read DAEMONNUM
    if [ -z "$DAEMONNUM" ]; then
        gatherDaemon
    fi
}

# Function to gather Minecraft key input
gatherKey() {
    echo "Enter the Minecraft Key if you have one (else type 'no'), followed by [ENTER]:"
    echo -n ">"
    read KEY
    if [ -z "$KEY" ]; then
        gatherKey
    fi
}

# Function to gather password input
gatherPw() {
    echo -n "Enter a complex 8 character password, followed by [ENTER]:"
    echo -n ">"
    IFS= read -r PW
    LEN=${#PW}
    if [ "$LEN" -lt 8 ] || [ -z "$(printf %s "$PW" | tr -d "[:alnum:]")" ]; then
        echo "Password must be at least 8 characters long and contain special characters."
        gatherPw
    fi
    PPASSWDDB="${PW}panel"
    DPASSWDDB="${PW}daemon"
}

# Gather inputs
gatherDaemon
gatherDomain
gatherEmail
gatherKey
gatherPw

# Display gathered information
echo "This is the info you entered:"
echo
echo "SYSADMIN email: ${EMAIL}"
echo "Your domain name: ${DOMAIN}"
echo "Daemon number: ${DAEMONNUM}"
echo "Minecraft key: ${KEY}"
echo
read -n 1 -s -r -p "Hit [ENTER] to continue or CTRL+C to cancel"

# Install necessary packages
apt-get update -y
apt-get install -y vim software-properties-common apache2 phpmyadmin mysql-server php libapache2-mod-php php-mcrypt php-mysql zip default-jre dialog expect

# Restart MySQL service
service mysql restart

# Configure Apache
echo "ServerName ${DOMAIN}" >> /etc/apache2/apache2.conf
service apache2 restart

# Secure MySQL installation
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

# Update Apache configuration
sed -i 's/.*irectoryIndex.*/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/' /etc/apache2/mods-enabled/dir.conf
service apache2 restart

# Install Certbot
add-apt-repository -y ppa:certbot/certbot
apt-get update
apt-get install python-certbot-apache -y

# Configure Certbot for SSL
CERTBOT=$(expect -c "
set timeout 10
spawn certbot --apache -d ${DOMAIN}
expect \"*cancel):\"
send \"$EMAIL\r\"
expect \"(A)gree/(C)ancel:\"
send \"a\r\"
expect \"(Y)es/(N)o:\"
send \"n\r\"
expect eof
")
echo "$CERTBOT"

# Start MySQL service
service mysql start

# Create necessary databases and users
mysql -uroot -p${PW} -e "CREATE DATABASE ${PANELDB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -uroot -p${PW} -e "CREATE USER ${PANELDB}@localhost IDENTIFIED BY '${PPASSWDDB}';"
mysql -uroot -p${PW} -e "GRANT ALL PRIVILEGES ON ${PANELDB}.* TO '${PANELDB}'@'localhost';"
mysql -uroot -p${PW} -e "FLUSH PRIVILEGES;"

mysql -uroot -p${PW} -e "CREATE DATABASE ${DAEMONDB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -uroot -p${PW} -e "CREATE USER ${DAEMONDB}@localhost IDENTIFIED BY '${DPASSWDDB}';"
mysql -uroot -p${PW} -e "GRANT ALL PRIVILEGES ON ${DAEMONDB}.* TO '${DAEMONDB}'@'localhost';"
mysql -uroot -p${PW} -e "FLUSH PRIVILEGES;"

# Download and install Multicraft
cd ~
mkdir MulticraftInstallation
cd MulticraftInstallation

wget https://www.multicraft.org/download/linux64 -O multicraft.tar.gz
tar xvzf multicraft.tar.gz

cd multicraft

# Update Multicraft configuration
sed -i -e "/daemon_db/ s/sqlite:.*/mysql:host=127.0.0.1;dbname=multicraft_daemon'/ ; /panel_db/ s/sqlite:.*/mysql:host=127.0.0.1;dbname=multicraft_panel'/" /root/MulticraftInstallation/multicraft/panel/protected/config/config.php.dist 
sed -i -e '/panel_db_user/ s/root/multicraft_panel/ ; /daemon_db_user/ s/root/multicraft_daemon/' /root/MulticraftInstallation/multicraft/panel/protected/config/config.php.dist 

# Run Multicraft setup
MULTI=$(expect -c "
set timeout 10
spawn ./setup.sh
expect \"Run each Minecraft server under its own user? (Multicraft will create system users):\"
send \"y\r\"
expect \"Run Multicraft under this user:\"
send \"minecraft\r\"
expect \"User not found. Create user 'minecraft' on start of installation?\"
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

# Final Multicraft configuration
sed -i 's/dbUser.*/dbUser = multicraft_daemon/' /home/minecraft/multicraft/multicraft.conf
sed -i '/^password/ d' /home/minecraft/multicraft/multicraft.conf
sed -i "s/dbPassword.*/dbPassword = $DPASSWDDB/" /home/minecraft/multicraft/multicraft.conf
clear

# Display final instructions
echo
echo "Go to the web panel: http://your.address/multicraft/install.php"
echo "STOP! Copy and don't lose the following passwords:"
echo "$PANELDB: $PANELDB / $PPASSWDDB"
echo "$DAEMONDB: $DAEMONDB / $DPASSWDDB"
echo
