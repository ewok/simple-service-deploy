#!/bin/bash
set -e

# URL

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

curl=''
if command_exists curl; then
	curl='curl -sSL'
elif command_exists wget; then
	curl='wget -qO-'
fi

case $(head -n1 /etc/issue | cut -f 1 -d ' ') in                                                                                                                                   
    Debian)     type="debian" ;;                                                                                                                                                   
    Ubuntu)     type="ubuntu" ;;                                                                                                                                                   
    *)          type="rhel" ;;                                                                                                                                                     
esac

case "${type}" in
	debian|ubuntu)
	$curl "${URL}/package.deb" > /tmp/package.deb 
	apt-get update
	dpkg -i /tmp/package.deb || apt-get install -fy
	rm -f /tmp/package.deb
	;;

	rhel)
	$curl "${URL}/package.rpm" > /tmp/package.rpm
	yum --nogpgcheck localinstall -y /tmp/package.rpm
	rm -f /tmp/package.rpm
	;;
esac

