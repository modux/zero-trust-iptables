#!/bin/bash
# Update ipset to let my dynamic IP in

# useful list of repos etc
# https://docs.microsoft.com/en-us/visualstudio/install/install-and-use-visual-studio-behind-a-firewall-or-proxy-server?view=vs-2019

# find out what hosts your app is trying to dial to with this command

# it will add them to whitelist.txt 
# script -q -c "sudo tcpdump -i any -l port 53 2>/dev/null | grep -o --line-buffered ' A? .*' | cut -d' ' -f3" | tee -a whitelist.txt



if [[ $1 == "monitor" ]] ; then

	script -q -c "sudo tcpdump -i any -l port 53 2>/dev/null | grep -o --line-buffered ' A? .*' | cut -d' ' -f3" | tee -a whitelist.txt
	exit
fi



filename=$0
hosts=whitelist.txt

chown root:root $filename $hosts
chmod 744 $filename $hosts

dnsserver=9.9.9.9

if=ens33

iptables -C OUTPUT -o $if -m conntrack --ctstate ESTABLISHED -j ACCEPT || iptables -A OUTPUT -o $if -m conntrack --ctstate ESTABLISHED -j ACCEPT
iptables -C OUTPUT -o $if -j DROP || iptables -A OUTPUT -o $if -j DROP


# and IPv6, not like anyone uses it anyway :p
ip6tables -C OUTPUT -o $if -j DROP || ip6tables -A OUTPUT -o $if -j DROP

# temporarily allow access to DNS Server of choice
iptables -C OUTPUT -p udp --dport 53 -d $dnsserver -j ACCEPT || iptables -I OUTPUT -p udp --dport 53 -d $dnsserver -j ACCEPT



while IFS="" read -r host || [ -n "$host" ]
do
  printf '%s\n' "$host"

	set=$(echo $host | md5sum | cut -c1-30)
	me=$(basename "$0")

	ip=$(nslookup  $host $dnsserver | awk '/^Address: / { print $2 ; exit }')

	if [ -z "$ip" ]; then
	    logger -t "$me" "IP for '$host' not found"
	    exit 1
	fi


	grep ".*$host" /etc/hosts && sed -i "s/.*$host/$ip $host/g" /etc/hosts || echo $ip $host >> /etc/hosts
	echo here
	# make sure the set exists
	ipset -exist create $set hash:ip

	if ipset -q test $set $host; then
	    logger -t "$me" "IP '$ip' already in set '$set'."
	else 
	    logger -t "$me" "Adding IP '$ip' to set '$set'."
	    ipset flush $set
	    ipset add $set $ip
	fi


	iptables -C OUTPUT -p tcp  --match multiport --dports 80,443  -m set --match-set $set dst -j ACCEPT || 	iptables -I OUTPUT -p tcp  --match multiport --dports 80,443  -m set --match-set $set dst -j ACCEPT

done < $hosts

# add this file to cron
(crontab -l | grep $0) || ({ crontab -l; echo "*/5 * * * * root $(pwd)/$0"; } | crontab -)

# remove access to DNS server
iptables -D OUTPUT -p udp --dport 53 -d $dnsserver -j ACCEPT


exit
