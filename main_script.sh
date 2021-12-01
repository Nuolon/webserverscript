#!/bin/bash

#Variables that makes text appear just a little fancier.

RED='\033[0;31m'
NC='\033[0m'
LPURPLE='\033[1;35m'
YEL='\033[1;33m'
BLINKRED='\033[5;31m'
BLINKPURP='\033[5;35m'

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

install_httpd_apache() {
roll "Starting installation of \"httpd\" (apache) webserver via dnf..."
dnf -y install httpd
#apt-get install httpd
roll "Done!"
}

start_and_enable_httpd_systemctl() {
roll "Starting httpd and enabling it to run on boot..."
systemctl enable httpd
systemctl start httpd
roll "Done!"
}

configuring_basic_html_page() {
roll "Configuring a placeholder HTML landing page..."
touch /var/www/html/index.html
echo "Nick was hier eventjes, maar hij is ervandoor gegaan... <b>EPIC</b>"
roll "Done!" 
}

basic_html_page_check() {
roll "Opening FireFox to localhost to try and present the webpage; please confirm it works [Y/N]"
firefox 127.0.0.1
read -p "Did the website with the text: 'Nick was hier eventjes...' pop up? " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]
then
    echo -e  "${RED}User acknowledged webpage failure; stopping...${NC}"
	exit -1
fi
}

configure_firewall() {
firewall-cmd --add-service=http
firewall-cmd --add-service=https
firewall-cmd --runtime-to-permanent
}

install_httpd_apache
start_and_enable_httpd_systemctl
configuring_basic_html_page
basic_html_page_check
configure_firewall

