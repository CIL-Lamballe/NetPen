#!/bin/bash
# Check previous install
if [ -e $PWD/.netpenrc ]
then
	printf "Netpen already installed.\n"
	exit 1
fi

# Sudo rights
if [ `id -u` -ne 0 ]
then
	printf "Script needs to run as root!\nTry: \`sudo -i\` or \`su - root\` or \`sudo ./install\`\n"
	exit 1
fi

# Detect package type from /etc/issue
_found_arch() {
  local _ostype="$1"
  shift
  grep -qis "$*" /etc/issue && _OSTYPE="$_ostype"
}

# Detect package type
_OSTYPE_detect() {
  _found_arch DPKG   "Debian GNU/Linux" && return
  _found_arch DPKG   "Ubuntu" && return
  _found_arch YUM    "CentOS" && return
  _found_arch YUM    "Red Hat" && return
  _found_arch YUM    "Fedora" && return

  [[ -z "$_OSTYPE" ]] || return

  if [[ "$OSTYPE" != "darwin"* ]]; then
    _error "Can't detect OS type from /etc/issue. Running fallback method."
  fi
  [[ -x "/usr/bin/apt-get" ]]          && _OSTYPE="DPKG" && return
  [[ -x "/usr/bin/yum" ]]              && _OSTYPE="YUM" && return
  if [[ -z "$_OSTYPE" ]]; then
    _error "No supported package manager installed on system"
    _error "(supported: apt or yum)"
    exit 1
  fi
}

debian_install() {
	apt-get remove -y docker docker-engine docker.io containerd runc
	apt-get update
	apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
	curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
	apt-key fingerprint 0EBFCD88
	printf "Should be 9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88\n"
	local addr="https://download.docker.com/linux/debian"
       	local archi="deb [arch=amd64]"
       	add-apt-repository "$archi $addr $(lsb_release -cs) stable"
	apt-get update
	apt-get install -y docker-ce docker-ce-cli containerd.io
	docker run hello-world
}

centos_install() {
	sudo yum remove -yq docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
	sudo yum install -yq yum-utils
	sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	sudo yum install docker-ce docker-ce-cli containerd.io -yq
	printf "\nKey should be 060A 61C5 1B55 8A7F 742B 77AA C52F EB6B 621E 9F35\n"
	sudo systemctl start docker
	sudo docker run hello-world
}

_OSTYPE_detect
if [ "$_OSTYPE" = "YUM" ]
then
	centos_install
elif [ "$_OSTYPE" = "DPKG" ]
then
	debian_install
else
	printf "\n OS not supported!\n"
	exit 1
fi
docker build -t netpen:v0.1-a .
#if [ $? -eq 0 ]
#then
#	touch $PWD/.netpenrc
#fi
