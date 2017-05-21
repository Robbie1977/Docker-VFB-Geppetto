#!/bin/bash

cd /opt/geppetto/org.geppetto/utilities/source_setup 
python update_server.py

echo 'Start of log...' >> /home/virgo/serviceability/logs/log.log

tail -F /home/virgo/serviceability/logs/log.log & 

/home/virgo/bin/startup.sh 
