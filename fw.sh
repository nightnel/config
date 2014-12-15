#!/bin/bash
set -x

# ---------------------------
# 	Firewall configuration
# 	admin@marlonponton.com
# ---------------------------


# Global Variables
# -----------------
ipt="/sbin/iptables"



# Start Firewall
# ------------------------
function start-firewall	{

	echo -ne "-------------------------------\n"
	echo -ne "      Starting Firewall ...    \n"
	echo -ne "-------------------------------\n"
	
	$ipt -P INPUT DROP			# Drop all input packets
	$ipt -P OUTPUT ACCEPT		# Accept all output packets
	$ipt -P FORWARD DROP 		# Drop all forward packets

	$ipt -F 					# Flush all chains
	$ipt -X	INPUT-LOG			# Delete all custom chains

	$ipt -A INPUT -i lo -j ACCEPT	# Default policy for loopback interface
	$ipt -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT	# Default policy for established connections
	
	# Create input log chain
	$ipt -N INPUT-LOG

	# Send all incoming traffic to log chain
	$ipt -A INPUT -j INPUT-LOG


	# INPUT-LOG
	# ----------
	$ipt -A INPUT-LOG -m state --state NEW -p tcp --dport 22 -j LOG --log-prefix "iptables input ssh: " --log-level 4	# Log ssh connections
	$ipt -A INPUT-LOG -m state --state NEW -p tcp --dport 443 -j LOG --log-prefix "iptables input https: " --log-level 4	# Log https connections
	$ipt -A INPUT-LOG -m state --state NEW -p tcp --dport 80 -j LOG --log-prefix "iptables input http: " --log-level 4	# Log https connections
	#$ipt -A INPUT-LOG -m limit --limit 2/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4


	# General INPUT rules
	$ipt -A INPUT -m state --state NEW -p tcp -s 217.67.192.58 --dport 22 -j ACCEPT 	# Allow SSH connections only from ITSA network
	$ipt -A INPUT -m state --state NEW -p tcp -s 217.67.192.58 --dport 443 -j ACCEPT 	# Allow HTTPS only from ITSA network
	$ipt -A INPUT -m state --state NEW -p tcp -s 217.67.192.58 --dport 80 -j ACCEPT 	# Allow HTTP only from ITSA network

	# Save firewall settings
	iptables-save > /etc/sysconfig/iptables
	
}


# Default firewall policy
# ------------------------
function default-firewall	{

	echo -ne "-------------------------------\n"
	echo -ne "Setting default firewall policy\n"
	echo -ne "-------------------------------\n"

	iptables-restore < /root/firewall/default-firewall
}


# Status firewall
# ------------------------
function status-firewall	{

	echo -ne "--------------------\n"
	echo -ne "List firewall rules:\n"
	echo -ne "--------------------\n"
	$ipt -L -v 	# List all rules
}



# Firewall command line
case "$1" in
        start)
            start-firewall
            ;;
         
        status)
            status-firewall
            ;;

        default)
			default-firewall
            ;;
        log)
			grep iptables /var/log/kern.log 	# Show iptables log
            ;;
         
        *)
            echo $"Usage: $0 {start|default|status}"
            exit 1 
esac

