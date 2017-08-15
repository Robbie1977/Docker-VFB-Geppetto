#!/bin/bash

cd /opt/geppetto/org.geppetto/utilities/source_setup 
python update_server.py

sed 's\redirectPort="8443"\\g' -i /home/virgo/configuration/tomcat-server.xml

mkdir -p ~/serviceability/logs
echo 'Start of log...' > ~/serviceability/logs/log.log

tail --sleep-interval=5 -F ~/serviceability/logs/log.log & 

sed 's/XX:MaxPermSize=512m/XX:MaxPermSize=$MAXSIZE/g' -i /home/virgo/bin/dmk.sh
sed 's/Xmx512m/Xmx$MAXSIZE/' -i /home/virgo/bin/dmk.sh

/home/virgo/bin/startup.sh 
