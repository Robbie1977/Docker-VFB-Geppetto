#!/bin/bash

cd /opt/geppetto/org.geppetto/utilities/source_setup 
python update_server.py

/home/virgo/bin/startup.sh 
