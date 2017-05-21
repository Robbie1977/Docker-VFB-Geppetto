#!/bin/bash

cd /opt/geppetto/org.geppetto/utilities/source_setup 
python update_server.py

mkdir -p ~/serviceability/logs
echo 'Start of log...' > ~/serviceability/logs/log.log

tail --sleep-interval=5 -F ~/serviceability/logs/log.log & 

/home/virgo/bin/startup.sh 
