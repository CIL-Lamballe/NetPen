##		PREREQUISITES

# Sudo rights
if [ "$EUID" -eq 0 ]
then
	printf "Please do not run the script as root!\n"
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
		printf "ERROR: $bin does not seem to be installed.\n"
		printf "Please download $bin using your package manager!\n"
		exit 1
	fi
done
if [ ! -x "$(sudo bash -c 'command -v arp')" ]
then
	printf "ERROR: arp does not seem to be installed.\n"
	printf "Please download arp using your package manager!\n"
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
	local logfile='open_ports.log'
	> $logfile
	for ip in ${IPS[@]}
	do
		(	echo "----- $ip -----";
			#nmap -A $ip;
			nmap -A -Pn $ip;
			echo
		) | tee -a $logfile
		#nmap -v -A -Pn $ip | tee -a $logfile # heavy Scan taking ages
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
	y=10; x=11
	tput cup 0 2
	bash ./${assets}'header'
	tput cup $x $y
	tput setaf 3
	tput sgr0
	tput rev
	printf "M A I N - M E N U"
	tput sgr0
	tput cup $(($x + 2)) $y
	printf "1. 🔎 Scan Network"
	tput cup $(($x + 3)) $y
	printf "2. 🌊 Tsunami"
	tput cup $(($x + 4)) $y
	printf "3. empty"
	tput cup $(($x + 5)) $y
	printf "4. Quit"
	tput bold
	tput cup $(($x + 7)) $y
	read -p "Enter your choice [1-4] " CHOICE
	tput clear
	tput sgr0
	tput rc
}




##		 EXECUTE
tput smcup
CHOICE=0
menu
case $CHOICE in
	1)
		tput cup 0 0
		scanopenports
		;;
	2 | 3 | *)
		;;
esac
tput rmcup
