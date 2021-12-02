#!/bin/bash

#Variables that makes text appear just a little fancier.

RED='\033[0;31m'
NC='\033[0m'
LPURPLE='\033[1;35m'
YEL='\033[1;33m'
BLINKRED='\033[5;31m'
BLINKPURP='\033[5;35m'
CYAN='\033[1;36m'
NRML='\033[0;37m'

#Function to let text appear in a rolling-out fashion
roll() {
  msg="${1}"
    if [[ "${msg}" =~ ^=.*+$ ]]; then
      speed=".01"
    else
      speed=".03"
    fi
  let lnmsg=$(expr length "${msg}")-1
  for (( i=0; i <= "${lnmsg}"; i++ )); do
    echo -n "${msg:$i:1}"
    sleep "${speed}"
  done ; echo ""
}

start() {
echo -e "${BLINKPURP}###${NC} ${RED}Welcome to${NC} ${LPURPLE}Nick's${NC} ${RED}httpd/apache webserver roll-out script${NC}${BLINKPURP} ###${NC}"
echo -e "${CYAN}Please make sure you run this script as${NC}${RED} privileged user${NC}${CYAN}, are you?${NC}${YEL} [Y/N] ${NC}"
read -p "Input: " -n 1 -r
echo -e "${YEL}"
if [[ $REPLY =~ ^[Nn]$  ]]
then
	exit 1
fi

}

change_hostname() {
hostnamectl set-hostname G05-Web01
}

install_httpd_apache() {
roll "Starting installation of \"httpd\" (apache) webserver via dnf..."
dnf -y install httpd
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

start_and_enable_httpd_systemctl() {
roll "Starting httpd and enabling it to run on boot..."
systemctl enable httpd
systemctl start httpd
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

configuring_basic_html_page() {
roll "Configuring a placeholder HTML landing page..."
touch /var/www/html/index.html
echo "Nick was hier eventjes, maar hij is ervandoor gegaan... <b>EPIC</b>" >> /var/www/html/index.html
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

basic_html_page_check() {
gnome-terminal -- sh -c 'firefox 127.0.0.1'
roll "Opened FireFox to 127.0.0.1; please confirm it works [Y/N]"
read -p "Did the website pop up? " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]
then
    echo -e  "${RED}User acknowledged webpage failure; stopping...${NC}"
	exit -1
fi
echo -e "${YEL}"
roll "Removing test page to make room for Moodle..."
rm /var/www/html/index.html
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

install_mariaDB() {
roll "Installing mariaDB server package..."
dnf install mariadb-server
roll "Enabling MariaDB server and putting it on auto-boot..."
systemctl restart mariadb
systemctl enable mariadb
roll "Secure configuring MariaDB server through forcing root password, remove anonymous user and test database..."
mysql -e "UPDATE mysql.user SET Password = PASSWORD('Pa$$w0rd!') WHERE User = 'root'"
mysql -e "DROP USER ''@'localhost'"
mysql -e "DROP USER ''@'$(hostname)'"
mysql -e "DROP DATABASE test"
mysql -e "FLUSH PRIVILEGES"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

install_PHPreqsForHttpd() {
roll "Starting download of PHP and good-to-have modules..."
dnf install php php-common php-pecl-apcu php-cli php-pear php-pdo php-mysqlnd php-pgsql php-gd php-mbstring php-xml php-json php-pecl-zip libzip php-intl
roll "Restarting Apache/httpd and configuring a PHP test site..."
systemctl restart httpd
touch /var/www/html/test.php
roll "Changing permissions on /var/www/html/ to allow editing..."
sudo chmod 777 /var/www/html -R
echo "<?php phpinfo(); ?>" >> /var/www/html/test.php
gnome-terminal -- sh -c 'firefox 127.0.0.1/test.php'
roll "Opened FireFox to 127.0.0.1/test.php; please confirm it works [Y/N]"
read -p "Did the website pop up with PHP info?" -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]
then
	echo -e "${RED}User acknowledged webpage failure; stopping...${NC}"
		exit -1
fi
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

configure_mariaDB_for_moodle() {
roll "Configuring MariaDB for use in moodle..."
mysql -e "CREATE DATABASE moodledb;"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY  TABLES,DROP,INDEX,ALTER ON moodledb.* TO 'moodleadmin'@'localhost' IDENTIFIED BY 'Admin';"
mysql -e "FLUSH PRIVILEGES;"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

install_moodle() {
roll "Downloading Moodle 'latest' 3.9..."
wget -c https://download.moodle.org/download.php/direct/stable39/moodle-latest-39.tgz
roll "Moving files to /var/www/html/ and removing downloaded file(s)..."
tar -xzvf moodle-latest-39.tgz
mv moodle /var/www/html/
chmod 777 /var/www/html/moodle
rm moodle-latest-39.tgz
roll "Changing a line in httpd.conf to automatically open Moodle as main-page and rebooting apache..."
#To DO
systemctl restart httpd
roll "Setting permissions for apache..."
mkdir /var/www/moodledata
chmod 777 /var/www/moodledata
chown apache:apache -R /var/www/moodledata/
chown apache:apache -R /var/www/html/moodle/
chcon -R --type httpd_sys_rw_content_t /var/www/moodledata/
chcon -R --type httpd_sys_rw_content_t /var/www/html/moodle/
setsebool -P httpd_can_network_connect 1
systemctl restart httpd
echo -e "${LPURPLE}========================================================${YEL}"
}

configure_firewall() {
roll "Configuring firewall settings..."
firewall-cmd --add-service=http
firewall-cmd --add-service=https
firewall-cmd --runtime-to-permanent
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${NRML}"
}



start
change_hostname
install_httpd_apache
start_and_enable_httpd_systemctl
configuring_basic_html_page
basic_html_page_check
install_mariaDB
install_PHPreqsForHttpd
configure_mariaDB_for_moodle
install_moodle
configure_firewall
