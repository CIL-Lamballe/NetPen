## DEBUG
#set -x

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
dep_repo=('https://github.com/laramies/theHarvester' 'https://github.com/google/tsunami-security-scanner.git')
assets='assets/'
dpath=${assets}'dependencies/'
if [ ! -d "$dpath" ]
then
	mkdir $dpath
fi
i=0
for d in ${dep[@]}
do
	if [ ! -d "$dpath$d" ]
	then
		git clone --recurse-submodules ${dep_repo[$i]} $dpath$d
		((++i))
	fi
done

# Install additional packages
python3 -m pip install -r ${dpath}/${dep[0]}/requirements/dev.txt &> /dev/null
#python3 -m pip install -r ${dpath}/${dep[1]}/requirements/base.txt

unset i dep_repo pkg



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
	> $OPENPORTS_LOG
	for ip in ${IPS[@]}
	do
		(	echo "----- $ip -----";
			nmap -A -Pn $ip;
			echo
		) | tee -a $OPENPORTS_LOG
	done
}

function scanports() {
	local log="ports_$1.log"
	> $log
	nmap -A -Pn $1 | tee -a $log
}

function scanopenports() {
	tput clear
	pingall
	discover
	portscan
	local possible_hosts=`cat $OPENPORTS_LOG | grep -i "name" | sed -n -e 's/^.*name: //p' | grep -o -E "[a-zA-Z0-9]+" | sort | uniq`
	echo ${possible_hosts[@]} > possible_hosts.log
}

# Check domain Internet footprint in order to find sensitive information
function scantheweb() {
	local prevwd="$PWD/"
	local log=${prevwd}'internet_footprint.log'
	> $log
	tput clear
	printf "This could take a while..."
	cd ${dpath}${dep[0]}
        python3 theHarvester.py -d $1 -l 300 -b all | tail -n +17 > $log
	cd -
	cat $log | more
}

function scandomain() {
	tput clear
	if [ ! $OPENPORTS_LOG ]
	then
		tput setaf 196
		printf "Scan network before scanning domain!\n(choose: \"1. Network Scan\" from in main menu)\n"
		tput init
		read -n 1
		tput rmcup
		exit 2
	fi
	local prevwd="$PWD/"
	local log=${prevwd}'domain_found.log'
	> $log
	local domains=`cat $OPENPORTS_LOG | grep -i domain | cut -d ':' -f2 | grep -E -o "(\w+[.]\w+)+" | sort | uniq`
	local domains+=`cat $OPENPORTS_LOG | grep -E -o "((\w+[.])+\w+)+" | grep -E -v "[0-9]+[.][0-9]+" | sort | uniq`
	cd ${dpath}${dep[0]}
	(
		for d in ${domains[@]}
		do
			tput setaf 226
			printf "Scanning domain:"
			tput bold
			tput setaf 87
			printf " $d\n"
			tput init
        		python3 theHarvester.py -d $d -l 300 -b all | grep -v '\*'
			echo
		done
	) | tee -a $log
	cd -
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
	tput cup $(($x + 4)) $y
	printf "2. 👣 Internet Footprint"
	tput cup $(($x + 6)) $y
	printf "3. 🌐 Find Domains"
	tput cup $(($x + 8)) $y
	printf "4. 🌊 Tsunami"
	tput cup $(($x + 10)) $y
	printf "5. ⚓ Scan Ports"
	tput cup $(($x + 12)) $y
	printf "6. Quit"
	tput bold
	tput cup $(($x + 14)) $y
	read -p "Enter your choice [1-6] " CHOICE
	tput clear
	tput sgr0
	tput rc
}




##	EXECUTE
tput smcup
CHOICE=0
OPENPORTS_LOG='open_ports.log'
menu
case $CHOICE in
	1)
		tput cup 0 0
		scanopenports
		;;
	2)
		tput cup 0 0
		read -p "Enter your public/private domain name: " webdomain
		scantheweb $webdomain
		;;
	3)
		tput cup 0 0
		scandomain
		;;
	5)
		tput cup 0 0
		read -p "Enter IP you want to scan: " iptoscan
		scanports $iptoscan
		;;
	*)
		;;
esac
tput rmcup