# zero-trust-iptables
Lock down your iptables to a whitelist of domains

## Warning ##
This script will block EGRESS from your machine as one of the first steps

Egress rules for established, related connections are added

Use for locking down a build machine or a dev VM

We don't want those third-party libs dialing out during build or run

0 Protect this file, it's getting added to root crontab
1 Allow Established egress
2 Block other egress
3 Add temp rule for DNS server  (temp to prevent DNS tunneling)
4 DNS lookup of hosts
5 Add hosts to /etc/hosts
6 Add IP and port 443 to ipset and iptables
7 remove DNS
8 add this file to crontab

 - Overwrites IP tables with latest IP for domain - ports 80 & 443
 - Doesn't write a global DNS config - to prevent other apps DNS tunneling in the DNS window


## Requirements

ipset 

sudo apt-get update
sudo apt-get install ipset

## Usage

To populate whitelist automatically run:

```bash
./lockdown-egress-to-whitelist.sh monitor
```

Run your program or build script, whitelist.txt will be populated with domains that were attempted to reach.

Review whitelist.txt and remove any nefarious looking things.

Modify whitelist.txt to include the domains you need.

Run the lockdown: 

```bash
./lockdown-egress-to-whitelist.sh
```

Default includes fairly standard Python pip, NodeJS npm, Docker hub and Ubuntu.

## To do

Include ip addresses in whitelist
