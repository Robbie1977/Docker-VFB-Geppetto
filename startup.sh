#!/bin/bash

cd /opt/geppetto/org.geppetto/utilities/source_setup 
python update_server.py

tail -f /home/virgo/serviceability/logs/log.log & 

/home/virgo/bin/startup.sh 
