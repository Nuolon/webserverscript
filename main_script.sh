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
echo -e "${YEL}"
echo -e "${BLINKPURP}###${NC} ${RED}Welcome to${NC} ${LPURPLE}Nick's${NC} ${RED}httpd/apache webserver roll-out script${NC}${BLINKPURP} ###${NC}"
echo -e "${CYAN}Please make sure you run this script as${NC}${RED} privileged user${NC}${CYAN}, are you?${NC}${YEL} [Y/N] ${NC}"
read -p "Input: " -n 1 -r
echo -e "${YEL}"
if [[ $REPLY =~ ^[Nn]$  ]]
then
	exit 1
fi

}

selinux_passive() {
echo -e "${YEL}"
roll "Configuring selinux..."
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

change_hostname() {
echo -e "${YEL}"
roll "Changing hostname to: G05-Web01"
hostnamectl set-hostname G05-Web01
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

installing_dnf_utils() {
echo -e "${YEL}"
dnf install -y dnf-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module enable -y php:remi-7.4
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

install_mariaDB() {
echo -e "${YEL}"
dnf install -y mariadb-server
dnf install -y mariadb
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

install_httpd_apache() {
echo -e "${YEL}"
roll "Starting installation of \"httpd\" (apache) webserver via dnf..."
dnf -y install httpd
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}
install_PHPreqsForHttpd() {
echo -e "${YEL}"
roll "Starting download of PHP and good-to-have modules..."
dnf -y install php php-common php-pecl-apcu php-cli php-pear php-pdo php-mysqlnd php-pgsql php-gd php-mbstring php-xml php-json php-pecl-zip libzip php-intl
roll "Restarting Apache/httpd and configuring a PHP test site..."
systemctl restart httpd
roll "Changing permissions on /var/www/html/ to allow editing..."
sudo chmod 777 /var/www/html -R
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

start_and_enable_httpd_systemctl() {
echo -e "${YEL}"
roll "Starting httpd and enabling it to run on boot..."
systemctl enable httpd
systemctl start httpd
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

download_install_permissions_for_moodle() {
roll "Starting download and installing Moodle..."
echo -e "${YEL}"
wget -c https://download.moodle.org/download.php/direct/stable311/moodle-3.11.4.tgz
tar -xzvf moodle-3.11.4.tgz -C /var/www/
chmod 775 -R /var/www/moodle
chown apache:apache -R /var/www/moodle
mkdir -p /var/www/moodledata
chmod 770 -R /var/www/moodledata
chown apache:apache -R /var/www/moodledata
cp /var/www/moodle/config-dist.php /var/www/moodle/config.php
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

configure_mariaDB_for_moodle() {
roll "Configuring mariadb for moodle..."
systemctl start mariadb
systemctl enable mariadb
#systemctl start mariadb-server
#systemctl enable mariadb-server
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
#mysql -e "DROP DATABASE test;DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';"
mysql -e "CREATE DATABASE moodledb;"
mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodledb.* TO 'moodleadmin'@'localhost' IDENTIFIED BY 'Gengar'"
mysql -e "SET PASSWORD FOR root@localhost = PASSWORD('herpderp');FLUSH PRIVILEGES;"
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

configure_moodle() {
roll "Configuring moodle itself..."
echo -e "${YEL}"
cat >/etc/httpd/conf.d/moodle.conf <<EOL
<VirtualHost *:80>
 ServerName moodle.groep5.local
 DocumentRoot /var/www/moodle
 DirectoryIndex index.php
<Directory /var/www/moodle/>
 Options Indexes FollowSymLinks MultiViews
 AllowOverride All
 Order allow,deny
 allow from all
</Directory>
 ErrorLog /var/log/httpd/moodle_error.log
 CustomLog /var/log/httpd/moodle_access.log combined
</VirtualHost>
EOL

cp /var/www/moodle/config-dist.php /var/www/moodle/config.php
sed -i 's\$CFG->dbtype    = '\''pgsql'\'';\$CFG->dbtype    = '\''mariadb'\'';\' /var/www/moodle/config.php
sed -i 's\$CFG->dbname    = '\''moodle'\'';\$CFG->dbname    = '\''moodledb'\'';\' /var/www/moodle/config.php
sed -i 's\$CFG->dbuser    = '\''username'\'';\$CFG->dbuser    = '\''moodleadmin'\'';\' /var/www/moodle/config.php
sed -i 's\$CFG->dbpass    = '\''password'\'';\$CFG->dbpass    = '\''Gengar'\'';\' /var/www/moodle/config.php
sed -i 's#$CFG->wwwroot   = '\''http://example.com/moodle'\'';#$CFG->wwwroot   = '\''http://moodle.groep5.local'\'';#' /var/www/moodle/config.php
sed -i 's#$CFG->dataroot  = '\''\/home\/example\/moodledata'\'';#$CFG->dataroot  = '\''\/var\/www\/moodledata'\'';#' /var/www/moodle/config.php
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
systemctl restart httpd
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${YEL}"
}

configure_firewall() {
echo -e "${YEL}"
roll "Configuring firewall settings..."
firewall-cmd --add-port=80/tcp --zone=public --permanent
firewall-cmd --add-port=443/tcp --zone=public --permanent
firewall-cmd --reload
echo -e "${YEL}"
roll "Done!"
echo -e "${LPURPLE}========================================================${NRML}"
}

end() {
echo -e "${CYAN}^_^ Script completed, Moodle is reachable on: moodle.groep5.local ^_^${NC}${NRML}"
}

start
selinux_passive
change_hostname
installing_dnf_utils
install_httpd_apache
install_PHPreqsForHttpd
install_mariaDB
start_and_enable_httpd_systemctl
download_install_permissions_for_moodle
configure_mariaDB_for_moodle
configure_moodle
configure_firewall
end
