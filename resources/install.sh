#!/bin/sh

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "Retriving and installing LaunchDaemons and pf rules for Avalon/Docker virtual networking..."
curl -s -o /Library/LaunchDaemons/org.avalonmediasystem.lo0.172.16.123.1.plist https://raw.githubusercontent.com/avalonmediasystem/avalon-docker/development/resources/org.avalonmediasystem.lo0.172.16.123.1.plist
curl -s -o /Library/LaunchDaemons/org.avalonmediasystem.pf.rails80.plist https://raw.githubusercontent.com/avalonmediasystem/avalon-docker/development/resources/org.avalonmediasystem.pf.rails80.plist
echo "rdr pass inet proto tcp from any to 172.16.123.1 port 80 -> 127.0.0.1 port 3000" > /etc/pf.anchors/rails80

echo "Installing Avalon entries into /etc/hosts..."
echo "172.16.123.1\tstreaming solr matterhorn fedora redis" >> /etc/hosts

echo "Loading virtual IP address and pf rules..."
launchctl load /Library/LaunchDaemons/org.avalonmediasystem.lo0.172.16.123.1.plist
launchctl load /Library/LaunchDaemons/org.avalonmediasystem.pf.rails80.plist

echo "Done."
