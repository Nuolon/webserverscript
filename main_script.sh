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
roll "Open FireFox to 127.0.0.1; please confirm it works [Y/N]"
read -p "Did the website pop up? " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]
then
    echo -e  "${RED}User acknowledged webpage failure; stopping...${NC}"
	exit -1
fi
echo -e "${YEL}"
roll "Done!"
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
configure_firewall

