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
echo -e "${BLINKPURP}###${NC} ${RED}Welcome to${NC} ${LPURPLE}Nick's${NC} ${RED}Moodle to HTTPS script${NC}${BLINKPURP} ###${NC}"
echo -e "${CYAN}Please make sure you run this script as${NC}${RED} privileged user${NC}${CYAN}, are you?${NC}${YEL} [Y/N] ${NC}"
read -p "Input: " -n 1 -r
echo -e "${YEL}"
if [[ $REPLY =~ ^[Nn]$  ]]
then
	exit 1
fi

}

establish_name() {
clear
echo -e "While running the certificate generation script; you gave up a NAME and TYPE, i.e 'Moodle' and 'Server'. "
echo -e "This made a folder with information called 'Moodle-csr' with a certificate, key and request in the format 'Moodle-server.crt' etc."
read -p "Input name: " name
read -p "Input type: " type
}

local_trust_CA() {
cp ~/Desktop/$name-csr/ca.crt /tmp
cp /tmp/ca.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust
}

install_SSL() {
yum install mod_ssl openssh -y
}

configure_moodle() {
roll "Configuring moodle itself..."
echo -e "${YEL}"
rm /etc/httpd/conf.d/moodle.conf
chmod -R 777 /home
cat >/etc/httpd/conf.d/moodle.conf <<EOL
NameVirtualHost *:80
<VirtualHost *:80>
 ServerName moodle.groep5.local
 Redirect / https://moodle.groep5.local/
</VirtualHost>

<VirtualHost *:443>
 ServerName moodle.groep5.local
 DocumentRoot /var/www/moodle
 SSLEngine on
 SSLCertificateFile /home/Groep5/Desktop/Moodle-csr/Moodle-server.crt
 SSLCertificateKeyFile /home/Groep5/Desktop/Moodle-csr/Moodle-server.key
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

# path /var/www/moodle/config.php
sed -i 's#$CFG->wwwroot   = '\''http://moodle.groep5.local'\'';#$CFG->wwwroot   = '\''https://moodle.groep5.local'\'';#' /var/www/moodle/config.php
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
