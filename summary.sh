##		PREREQUISITES

# Sudo rights
if [ "$EUID" -eq 0 ]
then
	echo "Please do not run the script as root!"
	exit 1
fi

# Packages
pkg=('git' 'fping' 'nmap' 'tput')
for bin in ${pkg[@]}
do
	if [ -x "$(command -v $bin)" ]
	then
		continue
	else
		echo "ERROR: $bin does not seem to be installed."
		echo "Please download $bin using your package manager!"
		exit 1
	fi
done
if [ ! -x "$(sudo bash -c 'command -v arp')" ]
then
	echo "ERROR: arp does not seem to be installed."
	echo "Please download arp using your package manager!"
	exit 1
fi

# Retreive and install dependencies
dep=('theHarvester' 'Tsunami')
assets='assets/'
dpath=${assets}'dependencies/'
if [ ! -d "$dpath" ]
then
	mkdir $dpath
fi
for d in ${dep[@]}
do
	if [ ! -d "$dpath$d" ]
	then
		bash $assets$d
	fi
done




##		 FUNCTIONS

# Ping network and list reachable hosts
function pingall() {
	ping -b -c 5 255.255.255.255 &>/dev/null
	netmasks=`sudo arp -an | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d '.' -f1,2 | uniq`
}

# Attempt to discover hosts using ICMP
function discover() {
	local range=1
	for ip in ${netmasks[@]}
		do for range in {0..2} # {0..255}
			do IPS+=`fping -4 -a -q -g ${ip[@]:0:8}.$range.0/24 2>/dev/null`
		done
	done
}

# Scan for open ports
function portscan() {
for ip in ${IPS[@]}
do
	echo "----- $ip -----"
	#nmap -v -A -Pn $ip | tee open_ports.log # heavy Scan taking ages
	nmap -A $ip | tee open_ports.log
	echo
done
}

function scanopenports() {
	tput clear
	pingall
	discover
	portscan
}

# Display menu
function menu() {
	tput clear
	tput cup 0 2
	bash ./assets/header
	tput cup 12 8
	tput setaf 3
	tput sgr0
	tput rev
	echo "M A I N - M E N U"
	tput sgr0
	tput cup 14 8
	echo "1. 🔎 Scan Network"
	tput cup 15 8
	echo "2. 🌊 Tsunami"
	tput cup 16 8
	echo "3. empty"
	tput cup 17 8
	echo "4. Quit"
	tput bold
	tput cup 19 8
	read -p "Enter your choice [1-4] " CHOICE
	tput clear
	tput sgr0
	tput rc
}




##		 EXECUTE
tput smcup
CHOICE=0
menu
if [ $CHOICE -eq 4 ]
then
	tput rmcup
	exit
else
	case $CHOICE in
		1)
			tput cup 0 0
			scanopenports
			;;
		2 | 3 | *)
			echo "empty"
			;;
	esac
fi
tput rmcup
