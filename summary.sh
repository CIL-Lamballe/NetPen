
##		 FUNCTIONS

# Ping network and list reachable hosts
function pingall() {
	ping -b -c 50 255.255.255.255 &>/dev/null
	netmasks=`sudo arp -an | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d '.' -f1,2 | uniq`
}

# Attempt to discover hosts using ICMP
function discover() {
	for ip in ${netmasks[@]}
		do for range in {0..255}
			do echo fping -4 -a -q -s -g ${ip[@]:0:8}.$range.0/24 2>/dev/null
		done
	done
}

##		 EXECUTE
bash ./assets/header
pingall
discover
